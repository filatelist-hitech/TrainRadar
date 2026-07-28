package yandex

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

type fakeClient struct {
	mu       sync.Mutex
	calls    int
	apiKeys  []string
	response UpstreamSchedule
	err      error
}

func (f *fakeClient) Fetch(_ context.Context, apiKey string, _ Query) (UpstreamSchedule, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.calls++
	f.apiKeys = append(f.apiKeys, apiKey)
	return f.response, f.err
}

func (f *fakeClient) callCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.calls
}

type recordedLogger struct {
	events []string
}

func (l *recordedLogger) LogScheduleEvent(event string) {
	l.events = append(l.events, event)
}

func TestAdapterMissingAPIKeyDegradesWithoutDataOrPanic(t *testing.T) {
	t.Setenv(APIKeyEnvironmentVariable, "")
	client := &fakeClient{}
	logger := &recordedLogger{}
	adapter := newAdapter(t, client, time.Minute, time.Now, logger)

	response, err := adapter.Get(context.Background(), testQuery())

	if !errors.Is(err, ErrAPIKeyNotConfigured) {
		t.Fatalf("error = %v, want missing-key error", err)
	}
	if !isZeroResponse(response) {
		t.Fatalf("response = %#v, want zero response", response)
	}
	if client.callCount() != 0 {
		t.Fatalf("upstream calls = %d, want 0", client.callCount())
	}
	if got := strings.Join(logger.events, ","); got != "yandex_schedule_api_key_not_configured" {
		t.Fatalf("log events = %q", got)
	}
}

func TestAdapterAcceptsMaximumCacheTTL(t *testing.T) {
	t.Setenv(APIKeyEnvironmentVariable, "test-key")
	adapter := newAdapter(t, &fakeClient{}, MaxCacheTTL, time.Now, nil)

	if adapter.ttl != MaxCacheTTL {
		t.Fatalf("ttl = %s, want %s", adapter.ttl, MaxCacheTTL)
	}
}

func TestAdapterRejectsTTLAboveMaximum(t *testing.T) {
	t.Setenv(APIKeyEnvironmentVariable, "test-key")

	_, err := NewFromEnvironment(&fakeClient{}, MaxCacheTTL+time.Second, time.Now, nil)

	if !errors.Is(err, ErrCacheTTLTooLong) {
		t.Fatalf("error = %v, want TTL limit error", err)
	}
}

func TestAdapterCacheMissCallsUpstreamAndReturnsMetadata(t *testing.T) {
	t.Setenv(APIKeyEnvironmentVariable, "test-key")
	now := time.Date(2026, time.July, 28, 9, 0, 0, 0, time.UTC)
	client := &fakeClient{response: testSchedule(now.Add(-time.Minute))}
	adapter := newAdapter(t, client, 2*time.Minute, func() time.Time { return now }, nil)

	response, err := adapter.Get(context.Background(), testQuery())

	if err != nil {
		t.Fatalf("Get() error = %v", err)
	}
	if client.callCount() != 1 {
		t.Fatalf("upstream calls = %d, want 1", client.callCount())
	}
	if response.Attribution != SourceAttribution || response.Cache.State != CacheMiss {
		t.Fatalf("response metadata = %#v", response)
	}
	if response.SourceTimestamp != now.Add(-time.Minute) || response.Cache.FreshUntil != now.Add(2*time.Minute) {
		t.Fatalf("response freshness = %#v", response)
	}
}

func TestAdapterCacheHitAvoidsUpstreamAndReturnsCopy(t *testing.T) {
	t.Setenv(APIKeyEnvironmentVariable, "test-key")
	now := time.Date(2026, time.July, 28, 9, 0, 0, 0, time.UTC)
	client := &fakeClient{response: testSchedule(now)}
	adapter := newAdapter(t, client, time.Minute, func() time.Time { return now }, nil)

	first, err := adapter.Get(context.Background(), testQuery())
	if err != nil {
		t.Fatalf("first Get() error = %v", err)
	}
	first.Trips[0].UID = "caller-mutation"
	second, err := adapter.Get(context.Background(), testQuery())

	if err != nil {
		t.Fatalf("second Get() error = %v", err)
	}
	if client.callCount() != 1 {
		t.Fatalf("upstream calls = %d, want 1", client.callCount())
	}
	if second.Cache.State != CacheHit || second.Trips[0].UID == "caller-mutation" {
		t.Fatalf("cache response = %#v", second)
	}
}

func TestAdapterExpiryNeverServesStaleData(t *testing.T) {
	t.Setenv(APIKeyEnvironmentVariable, "test-key")
	now := time.Date(2026, time.July, 28, 9, 0, 0, 0, time.UTC)
	client := &fakeClient{response: testSchedule(now)}
	adapter := newAdapter(t, client, time.Minute, func() time.Time { return now }, nil)

	if _, err := adapter.Get(context.Background(), testQuery()); err != nil {
		t.Fatalf("first Get() error = %v", err)
	}
	now = now.Add(time.Minute)
	if _, err := adapter.Get(context.Background(), testQuery()); err != nil {
		t.Fatalf("expired Get() error = %v", err)
	}

	if client.callCount() != 2 {
		t.Fatalf("upstream calls = %d, want 2 after expiry", client.callCount())
	}
}

func TestAdapterUpstreamErrorReturnsSafeUnavailableResponse(t *testing.T) {
	const secret = "never-log-this-yandex-key"
	t.Setenv(APIKeyEnvironmentVariable, secret)
	logger := &recordedLogger{}
	client := &fakeClient{err: fmt.Errorf("provider rejected credential %q", secret)}
	adapter := newAdapter(t, client, time.Minute, time.Now, logger)

	response, err := adapter.Get(context.Background(), testQuery())

	if !errors.Is(err, ErrUpstreamUnavailable) {
		t.Fatalf("error = %v, want upstream unavailable", err)
	}
	if !isZeroResponse(response) {
		t.Fatalf("response = %#v, want zero response", response)
	}
	if strings.Contains(err.Error(), secret) || strings.Contains(fmt.Sprintf("%#v", response), secret) || strings.Contains(strings.Join(logger.events, ","), secret) {
		t.Fatal("API key leaked into error, response, or logging")
	}
}

func TestAdapterCacheIsConcurrencySafe(t *testing.T) {
	t.Setenv(APIKeyEnvironmentVariable, "test-key")
	now := time.Date(2026, time.July, 28, 9, 0, 0, 0, time.UTC)
	client := &fakeClient{response: testSchedule(now)}
	adapter := newAdapter(t, client, time.Minute, func() time.Time { return now }, nil)

	const callers = 64
	errors := make(chan error, callers)
	var group sync.WaitGroup
	for range callers {
		group.Add(1)
		go func() {
			defer group.Done()
			_, err := adapter.Get(context.Background(), testQuery())
			errors <- err
		}()
	}
	group.Wait()
	close(errors)
	for err := range errors {
		if err != nil {
			t.Fatalf("concurrent Get() error = %v", err)
		}
	}
	if client.callCount() != 1 {
		t.Fatalf("upstream calls = %d, want one cache fill", client.callCount())
	}
}

func TestAdapterHasNoFilePersistenceDependency(t *testing.T) {
	sourcePath := filepath.Join("adapter.go")
	source, err := os.ReadFile(sourcePath)
	if err != nil {
		t.Fatalf("read adapter source: %v", err)
	}
	for _, forbidden := range []string{"os.Write", "os.Create", "os.OpenFile", "database/sql", "sqlite", "postgres", "snapshot"} {
		if strings.Contains(string(source), forbidden) {
			t.Fatalf("adapter source contains forbidden persistence dependency %q", forbidden)
		}
	}
}

func newAdapter(t *testing.T, client UpstreamClient, ttl time.Duration, now func() time.Time, logger EventLogger) *Adapter {
	t.Helper()
	adapter, err := NewFromEnvironment(client, ttl, now, logger)
	if err != nil {
		t.Fatalf("NewFromEnvironment() error = %v", err)
	}
	return adapter
}

func testQuery() Query {
	return Query{From: "s2000005", To: "s2000093", Date: "2026-07-28"}
}

func testSchedule(sourceTimestamp time.Time) UpstreamSchedule {
	return UpstreamSchedule{
		SourceTimestamp: sourceTimestamp,
		Trips: []Trip{{
			UID:       "synthetic-trip",
			Departure: sourceTimestamp.Add(time.Hour),
			Arrival:   sourceTimestamp.Add(3 * time.Hour),
		}},
	}
}

func isZeroResponse(response Response) bool {
	return response.Attribution == "" && response.SourceTimestamp.IsZero() && len(response.Trips) == 0 &&
		response.Cache == (CacheMetadata{})
}

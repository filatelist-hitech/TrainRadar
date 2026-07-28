// Package yandex provides the cache-only boundary for Yandex Schedule API use.
// It deliberately has no HTTP implementation: a future upstream client is injected,
// keeping this component local, read-only and deterministic in tests.
package yandex

import (
	"context"
	"errors"
	"os"
	"sync"
	"time"
)

const (
	// APIKeyEnvironmentVariable is intentionally a name only; its value is never exposed.
	APIKeyEnvironmentVariable = "YANDEX_RASP_API_KEY"
	SourceAttribution         = "Данные предоставлены сервисом Яндекс.Расписания"
	MaxCacheTTL               = 300 * time.Second
)

var (
	ErrCacheTTLTooLong      = errors.New("schedule cache ttl exceeds 300 seconds")
	ErrInvalidCacheTTL      = errors.New("schedule cache ttl must be positive")
	ErrAPIKeyNotConfigured  = errors.New("schedule unavailable: server-side API key is not configured")
	ErrUpstreamUnconfigured = errors.New("schedule unavailable: upstream client is not configured")
	ErrUpstreamUnavailable  = errors.New("schedule unavailable: upstream request failed")
)

// Query is a read-only request to the upstream schedule surface.
// All fields are value types so it is safe to use as an in-memory cache key.
type Query struct {
	From string
	To   string
	Date string
}

// Trip is the minimal provider-neutral payload currently preserved by the adapter.
// It contains no API credential or user data.
type Trip struct {
	UID       string
	Departure time.Time
	Arrival   time.Time
}

// UpstreamSchedule is the response supplied by an injected upstream client.
// A zero SourceTimestamp means the adapter uses its retrieval time as the source timestamp.
type UpstreamSchedule struct {
	Trips           []Trip
	SourceTimestamp time.Time
}

// UpstreamClient is the only integration point allowed to make a provider request.
// Unit tests inject a fake implementation; this package never opens the network itself.
type UpstreamClient interface {
	Fetch(context.Context, string, Query) (UpstreamSchedule, error)
}

// EventLogger receives constant, credential-free state labels only.
type EventLogger interface {
	LogScheduleEvent(string)
}

type CacheState string

const (
	CacheMiss CacheState = "miss"
	CacheHit  CacheState = "hit"
)

// CacheMetadata makes cache behaviour visible to the future use case without exposing secrets.
type CacheMetadata struct {
	State      CacheState
	FetchedAt  time.Time
	FreshUntil time.Time
	TTL        time.Duration
}

// Response is the adapter's safe internal output.
type Response struct {
	Attribution     string
	SourceTimestamp time.Time
	Trips           []Trip
	Cache           CacheMetadata
}

type cacheEntry struct {
	response Response
}

// Adapter holds API credentials and schedule data in process memory only.
type Adapter struct {
	client UpstreamClient
	apiKey string
	ttl    time.Duration
	now    func() time.Time
	logger EventLogger

	mu    sync.Mutex
	cache map[Query]cacheEntry
}

// NewFromEnvironment reads the provider key only from the server process environment.
// Missing configuration returns a usable adapter that degrades safely on Get.
func NewFromEnvironment(client UpstreamClient, ttl time.Duration, now func() time.Time, logger EventLogger) (*Adapter, error) {
	if ttl <= 0 {
		return nil, ErrInvalidCacheTTL
	}
	if ttl > MaxCacheTTL {
		return nil, ErrCacheTTLTooLong
	}
	if now == nil {
		now = time.Now
	}

	return &Adapter{
		client: client,
		apiKey: os.Getenv(APIKeyEnvironmentVariable),
		ttl:    ttl,
		now:    now,
		logger: logger,
		cache:  make(map[Query]cacheEntry),
	}, nil
}

// Get returns only a fresh in-memory response. It never serves expired data or writes persistence.
func (a *Adapter) Get(ctx context.Context, query Query) (Response, error) {
	a.mu.Lock()
	defer a.mu.Unlock()

	if a.apiKey == "" {
		a.log("yandex_schedule_api_key_not_configured")
		return Response{}, ErrAPIKeyNotConfigured
	}

	now := a.now().UTC()
	if entry, ok := a.cache[query]; ok && now.Before(entry.response.Cache.FreshUntil) {
		response := cloneResponse(entry.response)
		response.Cache.State = CacheHit
		return response, nil
	}

	if a.client == nil {
		a.log("yandex_schedule_upstream_not_configured")
		return Response{}, ErrUpstreamUnconfigured
	}

	upstream, err := a.client.Fetch(ctx, a.apiKey, query)
	if err != nil {
		a.log("yandex_schedule_upstream_error")
		return Response{}, ErrUpstreamUnavailable
	}

	sourceTimestamp := upstream.SourceTimestamp.UTC()
	if sourceTimestamp.IsZero() {
		sourceTimestamp = now
	}
	response := Response{
		Attribution:     SourceAttribution,
		SourceTimestamp: sourceTimestamp,
		Trips:           append([]Trip(nil), upstream.Trips...),
		Cache: CacheMetadata{
			State:      CacheMiss,
			FetchedAt:  now,
			FreshUntil: now.Add(a.ttl),
			TTL:        a.ttl,
		},
	}
	a.cache[query] = cacheEntry{response: response}
	return cloneResponse(response), nil
}

func (a *Adapter) log(event string) {
	if a.logger != nil {
		a.logger.LogScheduleEvent(event)
	}
}

func cloneResponse(response Response) Response {
	response.Trips = append([]Trip(nil), response.Trips...)
	return response
}

package rawgps

import (
	"testing"
	"time"
)

func TestRetentionNeverExceedsTwentyFourHours(t *testing.T) {
	now := time.Now().UTC()
	valid := Record{ObservedAt: now, ExpiresAt: now.Add(24 * time.Hour)}
	invalid := Record{ObservedAt: now, ExpiresAt: now.Add(24*time.Hour + time.Second)}

	if !valid.RetentionIsValid() {
		t.Fatal("24-hour retention must be valid")
	}
	if invalid.RetentionIsValid() {
		t.Fatal("retention over 24 hours must be rejected")
	}
}

package rawgps

import "time"

const MaximumRetention = 24 * time.Hour

// Record describes only encrypted persistence metadata. Exact coordinates are
// encrypted before crossing this boundary and are never fields of this type.
type Record struct {
	ObservationID string
	Ciphertext    []byte
	Nonce         []byte
	WrappedDEK    []byte
	ObservedAt    time.Time
	ExpiresAt     time.Time
}

func (record Record) RetentionIsValid() bool {
	if record.ObservedAt.IsZero() || record.ExpiresAt.IsZero() {
		return false
	}
	retention := record.ExpiresAt.Sub(record.ObservedAt)
	return retention > 0 && retention <= MaximumRetention
}

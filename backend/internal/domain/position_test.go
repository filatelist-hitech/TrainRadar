package domain

import "testing"

func TestPositionStateLiveCoverage(t *testing.T) {
	tests := []struct {
		state PositionState
		live  bool
	}{
		{PositionOfficialActual, true},
		{PositionCrowdConfirmed, true},
		{PositionEstimated, false},
		{PositionStaleLost, false},
		{PositionState("unknown"), false},
	}

	for _, test := range tests {
		if got := test.state.IsLiveCoverage(); got != test.live {
			t.Fatalf("%s live coverage = %v, want %v", test.state, got, test.live)
		}
	}
}

func TestCrowdConfirmedThreshold(t *testing.T) {
	if got := MinimumIndependentCapabilities(PositionCrowdConfirmed); got != 3 {
		t.Fatalf("crowd_confirmed threshold = %d, want 3", got)
	}
}

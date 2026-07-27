package domain

type PositionState string

const (
	PositionOfficialActual PositionState = "official_actual"
	PositionCrowdConfirmed PositionState = "crowd_confirmed"
	PositionEstimated      PositionState = "estimated"
	PositionStaleLost      PositionState = "stale_lost"
)

func (state PositionState) IsLiveCoverage() bool {
	return state == PositionOfficialActual || state == PositionCrowdConfirmed
}

func MinimumIndependentCapabilities(state PositionState) int {
	if state == PositionCrowdConfirmed {
		return 3
	}
	return 0
}

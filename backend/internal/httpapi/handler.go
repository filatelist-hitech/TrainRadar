package httpapi

import (
	"encoding/json"
	"net/http"
)

type statusResponse struct {
	Project          string   `json:"project"`
	Milestone        string   `json:"milestone"`
	Corridor         string   `json:"corridor"`
	RegisteredStops  int      `json:"registered_stops"`
	Implemented      []string `json:"implemented"`
	NotImplemented   []string `json:"not_implemented"`
	RealtimeEndpoint string   `json:"realtime_endpoint"`
}

func NewHandler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", health)
	mux.HandleFunc("GET /v1/status", status)
	mux.HandleFunc("GET /v1/live/events", realtimeNotImplemented)
	return mux
}

func health(writer http.ResponseWriter, _ *http.Request) {
	writeJSON(writer, http.StatusOK, map[string]string{"status": "ok"})
}

func status(writer http.ResponseWriter, _ *http.Request) {
	writeJSON(writer, http.StatusOK, statusResponse{
		Project:          "TrainRadar",
		Milestone:        "M0",
		Corridor:         "Москва-Павелецкая → Узуново",
		RegisteredStops:  44,
		Implemented:      []string{"health", "status", "reference-data validation"},
		NotImplemented:   []string{"schedule import", "GPS collection", "map matching", "realtime", "ETA"},
		RealtimeEndpoint: "reserved_not_implemented",
	})
}

func realtimeNotImplemented(writer http.ResponseWriter, _ *http.Request) {
	writeJSON(writer, http.StatusNotImplemented, map[string]string{
		"code":    "m0_realtime_not_implemented",
		"message": "SSE contract is reserved; no live data is produced in M0",
	})
}

func writeJSON(writer http.ResponseWriter, statusCode int, payload any) {
	writer.Header().Set("Content-Type", "application/json; charset=utf-8")
	writer.WriteHeader(statusCode)
	_ = json.NewEncoder(writer).Encode(payload)
}

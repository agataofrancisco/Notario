package progress

import "time"

const completedKind = "completed"

// Event intentionally contains no task content, calendar IDs, schedules or
// OAuth credentials. It is the entire cloud data boundary for this service.
type Event struct {
	OperationID   string    `json:"operationId"`
	CompletedAt   time.Time `json:"completedAt"`
	ActualMinutes int       `json:"actualMinutes"`
	Kind          string    `json:"kind"`
}

type Aggregate struct {
	CompletedCount     int       `json:"completedCount"`
	ActualMinutesTotal int       `json:"actualMinutesTotal"`
	LastCompletedAt    time.Time `json:"lastCompletedAt,omitempty"`
}

type PushRequest struct {
	Events []Event `json:"events"`
}

type PushResponse struct {
	AcceptedOperationIDs []string  `json:"acceptedOperationIds"`
	Aggregate            Aggregate `json:"aggregate"`
	Cursor               int64     `json:"cursor"`
}

type PullResponse struct {
	Events    []Event   `json:"events"`
	Aggregate Aggregate `json:"aggregate"`
	Cursor    int64     `json:"cursor"`
}

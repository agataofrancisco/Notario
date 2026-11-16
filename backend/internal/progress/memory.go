package progress

import (
	"context"
	"sort"
	"sync"
)

// MemoryStore is used by unit tests only. Production uses PostgresStore.
type MemoryStore struct {
	mu     sync.Mutex
	users  map[string]*memoryUser
	cursor int64
}

type memoryUser struct {
	events map[string]storedEvent
}

type storedEvent struct {
	Event
	Cursor int64
}

func NewMemoryStore() *MemoryStore { return &MemoryStore{users: map[string]*memoryUser{}} }

func (s *MemoryStore) Push(_ context.Context, userID string, events []Event) (PushResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	user := s.user(userID)
	accepted := make([]string, 0, len(events))
	for _, event := range events {
		if _, exists := user.events[event.OperationID]; exists {
			accepted = append(accepted, event.OperationID)
			continue
		}
		s.cursor++
		user.events[event.OperationID] = storedEvent{Event: event, Cursor: s.cursor}
		accepted = append(accepted, event.OperationID)
	}
	return PushResponse{AcceptedOperationIDs: accepted, Aggregate: aggregate(user.events), Cursor: s.cursor}, nil
}

func (s *MemoryStore) Pull(_ context.Context, userID string, cursor int64) (PullResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	user := s.user(userID)
	events := make([]storedEvent, 0)
	for _, event := range user.events {
		if event.Cursor > cursor {
			events = append(events, event)
		}
	}
	sort.Slice(events, func(i, j int) bool { return events[i].Cursor < events[j].Cursor })
	response := PullResponse{Aggregate: aggregate(user.events), Cursor: s.cursor}
	for _, event := range events {
		response.Events = append(response.Events, event.Event)
	}
	return response, nil
}

func (s *MemoryStore) DeleteUser(_ context.Context, userID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.users, userID)
	return nil
}

func (s *MemoryStore) user(id string) *memoryUser {
	if user := s.users[id]; user != nil {
		return user
	}
	user := &memoryUser{events: map[string]storedEvent{}}
	s.users[id] = user
	return user
}

func aggregate(events map[string]storedEvent) Aggregate {
	result := Aggregate{}
	for _, event := range events {
		result.CompletedCount++
		result.ActualMinutesTotal += event.ActualMinutes
		if event.CompletedAt.After(result.LastCompletedAt) {
			result.LastCompletedAt = event.CompletedAt
		}
	}
	return result
}

package progress

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

type testVerifier struct {
	user string
	err  error
}

func (v testVerifier) Verify(context.Context, string) (string, error) { return v.user, v.err }

func TestPushIsIdempotentAndProgressOnly(t *testing.T) {
	handler := NewHandler(NewMemoryStore(), testVerifier{user: "person-a"})
	body := `{"events":[{"operationId":"op-1","completedAt":"2026-11-15T10:00:00Z","actualMinutes":30,"kind":"completed"}]}`
	for range 2 {
		req := httptest.NewRequest(http.MethodPost, "/v1/progress/push", strings.NewReader(body))
		req.Header.Set("Authorization", "Bearer test")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, req)
		if response.Code != http.StatusOK {
			t.Fatalf("push status = %d: %s", response.Code, response.Body.String())
		}
	}
	req := httptest.NewRequest(http.MethodGet, "/v1/progress/pull?cursor=0", nil)
	req.Header.Set("Authorization", "Bearer test")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, req)
	if !strings.Contains(response.Body.String(), `"completedCount":1`) {
		t.Fatalf("expected one completion: %s", response.Body.String())
	}
}

func TestPushRejectsTaskData(t *testing.T) {
	handler := NewHandler(NewMemoryStore(), testVerifier{user: "person-a"})
	body := `{"events":[],"title":"private task"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/progress/push", strings.NewReader(body))
	req.Header.Set("Authorization", "Bearer test")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, req)
	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d", response.Code)
	}
}

func TestAuthRequired(t *testing.T) {
	handler := NewHandler(NewMemoryStore(), testVerifier{user: "person-a"})
	req := httptest.NewRequest(http.MethodGet, "/v1/progress/pull", nil)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, req)
	if response.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d", response.Code)
	}
}

func TestInvalidTokenIsRejected(t *testing.T) {
	handler := NewHandler(NewMemoryStore(), testVerifier{err: errors.New("expired")})
	req := httptest.NewRequest(http.MethodGet, "/v1/progress/pull", nil)
	req.Header.Set("Authorization", "Bearer expired")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, req)
	if response.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d", response.Code)
	}
}

func TestProgressIsPrivateToGoogleSubject(t *testing.T) {
	store := NewMemoryStore()
	first := NewHandler(store, testVerifier{user: "person-a"})
	second := NewHandler(store, testVerifier{user: "person-b"})
	body := `{"events":[{"operationId":"op-person-a","completedAt":"2026-11-15T10:00:00Z","actualMinutes":30,"kind":"completed"}]}`
	push := httptest.NewRequest(http.MethodPost, "/v1/progress/push", strings.NewReader(body))
	push.Header.Set("Authorization", "Bearer test")
	first.ServeHTTP(httptest.NewRecorder(), push)
	pull := httptest.NewRequest(http.MethodGet, "/v1/progress/pull?cursor=0", nil)
	pull.Header.Set("Authorization", "Bearer test")
	response := httptest.NewRecorder()
	second.ServeHTTP(response, pull)
	if strings.Contains(response.Body.String(), "op-person-a") || strings.Contains(response.Body.String(), `"completedCount":1`) {
		t.Fatalf("progress leaked across users: %s", response.Body.String())
	}
}

func TestHealthzDoesNotRequireAuthentication(t *testing.T) {
	handler := NewHandler(NewMemoryStore(), testVerifier{err: errors.New("unused")})
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if response.Code != http.StatusOK || !strings.Contains(response.Body.String(), `"status":"ok"`) {
		t.Fatalf("health = %d: %s", response.Code, response.Body.String())
	}
}

func TestDeleteRemovesOnlyCallersProgress(t *testing.T) {
	store := NewMemoryStore()
	for user, operation := range map[string]string{"person-a": "op-a", "person-b": "op-b"} {
		_, err := store.Push(context.Background(), user, []Event{{
			OperationID: operation, CompletedAt: time.Date(2026, 11, 15, 10, 0, 0, 0, time.UTC), ActualMinutes: 20, Kind: completedKind,
		}})
		if err != nil {
			t.Fatal(err)
		}
	}
	handler := NewHandler(store, testVerifier{user: "person-a"})
	request := httptest.NewRequest(http.MethodDelete, "/v1/account/data", nil)
	request.Header.Set("Authorization", "Bearer test")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent {
		t.Fatalf("delete status = %d", response.Code)
	}
	remaining, err := store.Pull(context.Background(), "person-b", 0)
	if err != nil || remaining.Aggregate.CompletedCount != 1 {
		t.Fatalf("other user data was changed: %+v %v", remaining, err)
	}
}

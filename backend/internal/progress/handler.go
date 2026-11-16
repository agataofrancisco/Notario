package progress

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const maxRequestBytes = 64 << 10

func NewHandler(store Store, verifier TokenVerifier) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	mux.Handle("POST /v1/progress/push", authenticate(verifier, push(store)))
	mux.Handle("GET /v1/progress/pull", authenticate(verifier, pull(store)))
	mux.Handle("DELETE /v1/account/data", authenticate(verifier, deleteAccount(store)))
	return recoverer(mux)
}

type userContextKey struct{}

func authenticate(verifier TokenVerifier, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		parts := strings.Fields(r.Header.Get("Authorization"))
		if len(parts) != 2 || parts[0] != "Bearer" {
			writeError(w, http.StatusUnauthorized, "missing_bearer_token")
			return
		}
		userID, err := verifier.Verify(r.Context(), parts[1])
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid_id_token")
			return
		}
		next.ServeHTTP(w, contextWithUser(r, userID))
	})
}

func contextWithUser(r *http.Request, userID string) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), userContextKey{}, userID))
}

func userID(r *http.Request) string { return r.Context().Value(userContextKey{}).(string) }

func push(store Store) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var request PushRequest
		if err := decodeJSON(w, r, &request); err != nil {
			return
		}
		if len(request.Events) == 0 || len(request.Events) > 100 {
			writeError(w, http.StatusBadRequest, "events_must_contain_1_to_100_items")
			return
		}
		for _, event := range request.Events {
			if err := validateEvent(event); err != nil {
				writeError(w, http.StatusBadRequest, err.Error())
				return
			}
		}
		response, err := store.Push(r.Context(), userID(r), request.Events)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "progress_store_unavailable")
			return
		}
		writeJSON(w, http.StatusOK, response)
	})
}

func pull(store Store) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cursor, err := strconv.ParseInt(r.URL.Query().Get("cursor"), 10, 64)
		if r.URL.Query().Get("cursor") == "" {
			cursor = 0
			err = nil
		}
		if err != nil || cursor < 0 {
			writeError(w, http.StatusBadRequest, "invalid_cursor")
			return
		}
		response, err := store.Pull(r.Context(), userID(r), cursor)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "progress_store_unavailable")
			return
		}
		writeJSON(w, http.StatusOK, response)
	})
}

func deleteAccount(store Store) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := store.DeleteUser(r.Context(), userID(r)); err != nil {
			writeError(w, http.StatusInternalServerError, "progress_store_unavailable")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})
}

func validateEvent(event Event) error {
	if event.OperationID == "" || len(event.OperationID) > 128 {
		return errors.New("invalid_operation_id")
	}
	if event.Kind != completedKind {
		return errors.New("invalid_progress_kind")
	}
	if event.ActualMinutes < 0 || event.ActualMinutes > 24*60 {
		return errors.New("invalid_actual_minutes")
	}
	if event.CompletedAt.IsZero() || event.CompletedAt.After(time.Now().UTC().Add(5*time.Minute)) {
		return errors.New("invalid_completed_at")
	}
	return nil
}

func decodeJSON(w http.ResponseWriter, r *http.Request, dst any) error {
	r.Body = http.MaxBytesReader(w, r.Body, maxRequestBytes)
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(dst); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_progress_payload")
		return err
	}
	if decoder.Decode(&struct{}{}) != io.EOF {
		writeError(w, http.StatusBadRequest, "invalid_progress_payload")
		return errors.New("multiple JSON values")
	}
	return nil
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func writeError(w http.ResponseWriter, status int, code string) {
	writeJSON(w, status, map[string]string{"error": code})
}
func recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if recover() != nil {
				writeError(w, http.StatusInternalServerError, "internal_error")
			}
		}()
		next.ServeHTTP(w, r)
	})
}

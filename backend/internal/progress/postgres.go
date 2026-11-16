package progress

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresStore struct{ pool *pgxpool.Pool }

func NewPostgresStore(ctx context.Context, databaseURL string) (*PostgresStore, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, err
	}
	return &PostgresStore{pool: pool}, nil
}

func (s *PostgresStore) Close() { s.pool.Close() }

func (s *PostgresStore) Migrate(ctx context.Context) error {
	_, err := s.pool.Exec(ctx, `
CREATE TABLE IF NOT EXISTS progress_events (
  operation_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  device_id TEXT NOT NULL DEFAULT '',
  completed_at TIMESTAMPTZ NOT NULL,
  actual_minutes INTEGER NOT NULL CHECK (actual_minutes >= 0 AND actual_minutes <= 1440),
  kind TEXT NOT NULL CHECK (kind = 'completed'),
  cursor BIGSERIAL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS progress_events_user_cursor ON progress_events (user_id, cursor);
`)
	return err
}

func (s *PostgresStore) Push(ctx context.Context, userID string, events []Event) (PushResponse, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return PushResponse{}, err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	accepted := make([]string, 0, len(events))
	for _, event := range events {
		_, err := tx.Exec(ctx, `INSERT INTO progress_events (operation_id, user_id, completed_at, actual_minutes, kind) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (operation_id) DO NOTHING`, event.OperationID, userID, event.CompletedAt.UTC(), event.ActualMinutes, event.Kind)
		if err != nil {
			return PushResponse{}, err
		}
		accepted = append(accepted, event.OperationID)
	}
	response, err := pullPostgres(ctx, tx, userID, 0, false)
	if err != nil {
		return PushResponse{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return PushResponse{}, err
	}
	return PushResponse{AcceptedOperationIDs: accepted, Aggregate: response.Aggregate, Cursor: response.Cursor}, nil
}

func (s *PostgresStore) Pull(ctx context.Context, userID string, cursor int64) (PullResponse, error) {
	return pullPostgres(ctx, s.pool, userID, cursor, true)
}

func (s *PostgresStore) DeleteUser(ctx context.Context, userID string) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM progress_events WHERE user_id = $1`, userID)
	return err
}

type queryer interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
	QueryRow(context.Context, string, ...any) pgx.Row
}

func pullPostgres(ctx context.Context, q queryer, userID string, cursor int64, includeEvents bool) (PullResponse, error) {
	var result PullResponse
	if err := q.QueryRow(ctx, `SELECT COUNT(*), COALESCE(SUM(actual_minutes), 0), COALESCE(MAX(completed_at), 'epoch'::timestamptz), COALESCE(MAX(cursor), 0) FROM progress_events WHERE user_id = $1`, userID).Scan(&result.Aggregate.CompletedCount, &result.Aggregate.ActualMinutesTotal, &result.Aggregate.LastCompletedAt, &result.Cursor); err != nil {
		return result, err
	}
	if !includeEvents {
		return result, nil
	}
	rows, err := q.Query(ctx, `SELECT operation_id, completed_at, actual_minutes, kind FROM progress_events WHERE user_id = $1 AND cursor > $2 ORDER BY cursor ASC LIMIT 500`, userID, cursor)
	if err != nil {
		return result, err
	}
	defer rows.Close()
	for rows.Next() {
		var event Event
		if err := rows.Scan(&event.OperationID, &event.CompletedAt, &event.ActualMinutes, &event.Kind); err != nil {
			return result, err
		}
		result.Events = append(result.Events, event)
	}
	if rows.Err() != nil {
		return result, fmt.Errorf("read progress events: %w", rows.Err())
	}
	return result, nil
}

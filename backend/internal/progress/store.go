package progress

import "context"

type Store interface {
	Push(ctx context.Context, userID string, events []Event) (PushResponse, error)
	Pull(ctx context.Context, userID string, cursor int64) (PullResponse, error)
	DeleteUser(ctx context.Context, userID string) error
}

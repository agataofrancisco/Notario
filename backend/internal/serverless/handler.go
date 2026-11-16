package serverless

import (
	"context"
	"net/http"
	"os"
	"sync"

	"github.com/notario/progress-backend/internal/progress"
)

var (
	once       sync.Once
	apiHandler http.Handler
	initErr    error
)

// Serve handles a Vercel Function invocation. The database pool is reused by
// warm function instances and is intentionally not closed between requests.
func Serve(w http.ResponseWriter, r *http.Request, route string) {
	once.Do(func() {
		clientID := os.Getenv("GOOGLE_OAUTH_CLIENT_ID")
		databaseURL := os.Getenv("DATABASE_URL")
		if clientID == "" || databaseURL == "" {
			initErr = errConfigurationMissing{}
			return
		}
		store, err := progress.NewPostgresStore(context.Background(), databaseURL)
		if err != nil {
			initErr = err
			return
		}
		if err := store.Migrate(context.Background()); err != nil {
			store.Close()
			initErr = err
			return
		}
		apiHandler = progress.NewHandler(store, progress.NewGoogleVerifier(clientID))
	})
	if initErr != nil {
		http.Error(w, `{"error":"service_unavailable"}`, http.StatusServiceUnavailable)
		return
	}

	request := r.Clone(r.Context())
	urlCopy := *r.URL
	urlCopy.Path = route
	request.URL = &urlCopy
	apiHandler.ServeHTTP(w, request)
}

type errConfigurationMissing struct{}

func (errConfigurationMissing) Error() string { return "required configuration is missing" }

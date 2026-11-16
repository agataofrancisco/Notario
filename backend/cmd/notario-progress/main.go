package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/notario/progress-backend/internal/progress"
)

func main() {
	clientID := os.Getenv("GOOGLE_OAUTH_CLIENT_ID")
	databaseURL := os.Getenv("DATABASE_URL")
	if clientID == "" || databaseURL == "" {
		log.Fatal("GOOGLE_OAUTH_CLIENT_ID and DATABASE_URL are required")
	}

	ctx := context.Background()
	store, err := progress.NewPostgresStore(ctx, databaseURL)
	if err != nil {
		log.Fatalf("connect database: %v", err)
	}
	defer store.Close()
	if err := store.Migrate(ctx); err != nil {
		log.Fatalf("migrate database: %v", err)
	}

	handler := progress.NewHandler(store, progress.NewGoogleVerifier(clientID))
	server := &http.Server{
		Addr:              envOr("ADDR", ":8080"),
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("notario progress backend listening on %s", server.Addr)
	log.Fatal(server.ListenAndServe())
}

func envOr(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

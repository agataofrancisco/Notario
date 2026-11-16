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
		Addr:              listenAddr(),
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("notario progress backend listening on %s", server.Addr)
	log.Fatal(server.ListenAndServe())
}

// Vercel's container runtime supplies PORT. Local Docker keeps the documented
// default of 8080, and ADDR remains available for an explicit override.
func listenAddr() string {
	if address := os.Getenv("ADDR"); address != "" {
		return address
	}
	if port := os.Getenv("PORT"); port != "" {
		return ":" + port
	}
	return ":8080"
}

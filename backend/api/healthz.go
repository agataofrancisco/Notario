package handler

import (
	"net/http"

	"github.com/notario/progress-backend/internal/serverless"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	serverless.Serve(w, r, "/healthz")
}

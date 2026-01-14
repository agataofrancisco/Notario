package models

import (
	"time"

	"github.com/google/uuid"
)

// User representa um utilizador do sistema
type User struct {
	ID                 uuid.UUID `json:"id"`
	GoogleID           string    `json:"google_id"`
	Email              string    `json:"email"`
	Nome               string    `json:"nome"`
	FotoURL            *string   `json:"foto_url,omitempty"`
	GoogleCalendarID   *string   `json:"google_calendar_id,omitempty"`
	GoogleRefreshToken *string   `json:"-"` // Nunca expor no JSON
	Timezone           string    `json:"timezone"`
	CriadoEm           time.Time `json:"criado_em"`
	AtualizadoEm       time.Time `json:"atualizado_em"`
}

// CreateUserRequest representa os dados para criar um utilizador
type CreateUserRequest struct {
	GoogleID           string  `json:"google_id" binding:"required"`
	Email              string  `json:"email" binding:"required,email"`
	Nome               string  `json:"nome" binding:"required"`
	FotoURL            *string `json:"foto_url"`
	GoogleCalendarID   *string `json:"google_calendar_id"`
	GoogleRefreshToken *string `json:"google_refresh_token"`
	Timezone           string  `json:"timezone"`
}

// UpdateUserRequest representa os dados para atualizar um utilizador
type UpdateUserRequest struct {
	Nome               *string `json:"nome"`
	FotoURL            *string `json:"foto_url"`
	GoogleCalendarID   *string `json:"google_calendar_id"`
	GoogleRefreshToken *string `json:"google_refresh_token"`
	Timezone           *string `json:"timezone"`
}

// UserResponse representa a resposta pública de um utilizador
type UserResponse struct {
	ID       uuid.UUID `json:"id"`
	Email    string    `json:"email"`
	Nome     string    `json:"nome"`
	FotoURL  *string   `json:"foto_url,omitempty"`
	Timezone string    `json:"timezone"`
}

// ToResponse converte User para UserResponse
func (u *User) ToResponse() UserResponse {
	return UserResponse{
		ID:       u.ID,
		Email:    u.Email,
		Nome:     u.Nome,
		FotoURL:  u.FotoURL,
		Timezone: u.Timezone,
	}
}

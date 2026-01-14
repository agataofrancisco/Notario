package models

import (
	"time"

	"github.com/google/uuid"
)

// Note representa uma nota do sistema
type Note struct {
	ID            uuid.UUID `json:"id"`
	UserID        uuid.UUID `json:"user_id"`
	GoogleEventID *string   `json:"google_event_id,omitempty"`
	Titulo        string    `json:"titulo"`
	Conteudo      string    `json:"conteudo"`
	DataLembrete  time.Time `json:"data_lembrete"`
	Sincronizado  bool      `json:"sincronizado"`
	Versao        int       `json:"versao"`
	CriadoEm      time.Time `json:"criado_em"`
	AtualizadoEm  time.Time `json:"atualizado_em"`
}

// CreateNoteRequest representa os dados para criar uma nota
type CreateNoteRequest struct {
	Titulo       string    `json:"titulo" binding:"required"`
	Conteudo     string    `json:"conteudo" binding:"required"`
	DataLembrete time.Time `json:"data_lembrete" binding:"required"`
}

// UpdateNoteRequest representa os dados para atualizar uma nota
type UpdateNoteRequest struct {
	Titulo       *string    `json:"titulo"`
	Conteudo     *string    `json:"conteudo"`
	DataLembrete *time.Time `json:"data_lembrete"`
}

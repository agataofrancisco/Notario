package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/agataofrancisco/notario/internal/domain/models"
	"github.com/agataofrancisco/notario/pkg/database"
	"github.com/google/uuid"
)

// NoteRepository lida com operações de notas na base de dados
type NoteRepository struct{}

// NewNoteRepository cria uma nova instância do repositório
func NewNoteRepository() *NoteRepository {
	return &NoteRepository{}
}

// Create cria uma nova nota
func (r *NoteRepository) Create(userID uuid.UUID, req models.CreateNoteRequest) (*models.Note, error) {
	note := &models.Note{
		ID:           uuid.New(),
		UserID:       userID,
		Titulo:       req.Titulo,
		Conteudo:     req.Conteudo,
		DataLembrete: req.DataLembrete,
		Sincronizado: false,
		Versao:       1,
		CriadoEm:     time.Now(),
		AtualizadoEm: time.Now(),
	}

	query := `
		INSERT INTO notes (id, user_id, titulo, conteudo, data_lembrete, sincronizado, versao, criado_em, atualizado_em)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, criado_em, atualizado_em
	`

	err := database.DB.QueryRow(
		query,
		note.ID, note.UserID, note.Titulo, note.Conteudo, note.DataLembrete,
		note.Sincronizado, note.Versao, note.CriadoEm, note.AtualizadoEm,
	).Scan(&note.ID, &note.CriadoEm, &note.AtualizadoEm)

	if err != nil {
		return nil, fmt.Errorf("erro ao criar nota: %w", err)
	}

	return note, nil
}

// GetByID obtém uma nota por ID
func (r *NoteRepository) GetByID(id uuid.UUID) (*models.Note, error) {
	note := &models.Note{}

	query := `
		SELECT id, user_id, google_event_id, titulo, conteudo, data_lembrete,
			   sincronizado, versao, criado_em, atualizado_em
		FROM notes
		WHERE id = $1
	`

	err := database.DB.QueryRow(query, id).Scan(
		&note.ID, &note.UserID, &note.GoogleEventID, &note.Titulo, &note.Conteudo,
		&note.DataLembrete, &note.Sincronizado, &note.Versao,
		&note.CriadoEm, &note.AtualizadoEm,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("nota não encontrada")
	}

	if err != nil {
		return nil, fmt.Errorf("erro ao obter nota: %w", err)
	}

	return note, nil
}

// GetByUserID obtém todas as notas de um utilizador
func (r *NoteRepository) GetByUserID(userID uuid.UUID) ([]models.Note, error) {
	query := `
		SELECT id, user_id, google_event_id, titulo, conteudo, data_lembrete,
			   sincronizado, versao, criado_em, atualizado_em
		FROM notes
		WHERE user_id = $1
		ORDER BY data_lembrete ASC
	`

	rows, err := database.DB.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("erro ao obter notas: %w", err)
	}
	defer rows.Close()

	notes := []models.Note{}
	for rows.Next() {
		var note models.Note
		err := rows.Scan(
			&note.ID, &note.UserID, &note.GoogleEventID, &note.Titulo, &note.Conteudo,
			&note.DataLembrete, &note.Sincronizado, &note.Versao,
			&note.CriadoEm, &note.AtualizadoEm,
		)
		if err != nil {
			return nil, fmt.Errorf("erro ao escanear nota: %w", err)
		}
		notes = append(notes, note)
	}

	return notes, nil
}

// Update atualiza uma nota
func (r *NoteRepository) Update(id uuid.UUID, req models.UpdateNoteRequest) (*models.Note, error) {
	note, err := r.GetByID(id)
	if err != nil {
		return nil, err
	}

	// Atualizar campos
	if req.Titulo != nil {
		note.Titulo = *req.Titulo
	}
	if req.Conteudo != nil {
		note.Conteudo = *req.Conteudo
	}
	if req.DataLembrete != nil {
		note.DataLembrete = *req.DataLembrete
	}

	note.AtualizadoEm = time.Now()
	note.Versao++
	note.Sincronizado = false

	query := `
		UPDATE notes
		SET titulo = $1, conteudo = $2, data_lembrete = $3, sincronizado = $4, versao = $5, atualizado_em = $6
		WHERE id = $7
	`

	_, err = database.DB.Exec(
		query,
		note.Titulo, note.Conteudo, note.DataLembrete,
		note.Sincronizado, note.Versao, note.AtualizadoEm, id,
	)

	if err != nil {
		return nil, fmt.Errorf("erro ao atualizar nota: %w", err)
	}

	return note, nil
}

// Delete elimina uma nota
func (r *NoteRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM notes WHERE id = $1`

	result, err := database.DB.Exec(query, id)
	if err != nil {
		return fmt.Errorf("erro ao eliminar nota: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("erro ao verificar linhas afetadas: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("nota não encontrada")
	}

	return nil
}

// UpdateGoogleEventID atualiza o ID do evento do Google Calendar
func (r *NoteRepository) UpdateGoogleEventID(id uuid.UUID, googleEventID string) error {
	query := `UPDATE notes SET google_event_id = $1, sincronizado = true WHERE id = $2`

	_, err := database.DB.Exec(query, googleEventID, id)
	if err != nil {
		return fmt.Errorf("erro ao atualizar Google Event ID: %w", err)
	}

	return nil
}

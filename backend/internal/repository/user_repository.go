package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/agataofrancisco/notario/internal/domain/models"
	"github.com/agataofrancisco/notario/pkg/database"
	"github.com/google/uuid"
)

// UserRepository lida com operações de utilizadores na base de dados
type UserRepository struct{}

// NewUserRepository cria uma nova instância do repositório
func NewUserRepository() *UserRepository {
	return &UserRepository{}
}

// Create cria um novo utilizador
func (r *UserRepository) Create(req models.CreateUserRequest) (*models.User, error) {
	user := &models.User{
		ID:                 uuid.New(),
		GoogleID:           req.GoogleID,
		Email:              req.Email,
		Nome:               req.Nome,
		FotoURL:            req.FotoURL,
		GoogleCalendarID:   req.GoogleCalendarID,
		GoogleRefreshToken: req.GoogleRefreshToken,
		Timezone:           req.Timezone,
		CriadoEm:           time.Now(),
		AtualizadoEm:       time.Now(),
	}

	if user.Timezone == "" {
		user.Timezone = "Europe/Lisbon"
	}

	query := `
		INSERT INTO users (id, google_id, email, nome, foto_url, google_calendar_id, google_refresh_token, timezone, criado_em, atualizado_em)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, criado_em, atualizado_em
	`

	err := database.DB.QueryRow(
		query,
		user.ID,
		user.GoogleID,
		user.Email,
		user.Nome,
		user.FotoURL,
		user.GoogleCalendarID,
		user.GoogleRefreshToken,
		user.Timezone,
		user.CriadoEm,
		user.AtualizadoEm,
	).Scan(&user.ID, &user.CriadoEm, &user.AtualizadoEm)

	if err != nil {
		return nil, fmt.Errorf("erro ao criar utilizador: %w", err)
	}

	return user, nil
}

// GetByID obtém um utilizador por ID
func (r *UserRepository) GetByID(id uuid.UUID) (*models.User, error) {
	user := &models.User{}

	query := `
		SELECT id, google_id, email, nome, foto_url, google_calendar_id, google_refresh_token, timezone, criado_em, atualizado_em
		FROM users
		WHERE id = $1
	`

	err := database.DB.QueryRow(query, id).Scan(
		&user.ID,
		&user.GoogleID,
		&user.Email,
		&user.Nome,
		&user.FotoURL,
		&user.GoogleCalendarID,
		&user.GoogleRefreshToken,
		&user.Timezone,
		&user.CriadoEm,
		&user.AtualizadoEm,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("utilizador não encontrado")
	}

	if err != nil {
		return nil, fmt.Errorf("erro ao obter utilizador: %w", err)
	}

	return user, nil
}

// GetByGoogleID obtém um utilizador por Google ID
func (r *UserRepository) GetByGoogleID(googleID string) (*models.User, error) {
	user := &models.User{}

	query := `
		SELECT id, google_id, email, nome, foto_url, google_calendar_id, google_refresh_token, timezone, criado_em, atualizado_em
		FROM users
		WHERE google_id = $1
	`

	err := database.DB.QueryRow(query, googleID).Scan(
		&user.ID,
		&user.GoogleID,
		&user.Email,
		&user.Nome,
		&user.FotoURL,
		&user.GoogleCalendarID,
		&user.GoogleRefreshToken,
		&user.Timezone,
		&user.CriadoEm,
		&user.AtualizadoEm,
	)

	if err == sql.ErrNoRows {
		return nil, nil // Não encontrado, mas não é erro
	}

	if err != nil {
		return nil, fmt.Errorf("erro ao obter utilizador por Google ID: %w", err)
	}

	return user, nil
}

// GetByEmail obtém um utilizador por email
func (r *UserRepository) GetByEmail(email string) (*models.User, error) {
	user := &models.User{}

	query := `
		SELECT id, google_id, email, nome, foto_url, google_calendar_id, google_refresh_token, timezone, criado_em, atualizado_em
		FROM users
		WHERE email = $1
	`

	err := database.DB.QueryRow(query, email).Scan(
		&user.ID,
		&user.GoogleID,
		&user.Email,
		&user.Nome,
		&user.FotoURL,
		&user.GoogleCalendarID,
		&user.GoogleRefreshToken,
		&user.Timezone,
		&user.CriadoEm,
		&user.AtualizadoEm,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}

	if err != nil {
		return nil, fmt.Errorf("erro ao obter utilizador por email: %w", err)
	}

	return user, nil
}

// Update atualiza um utilizador
func (r *UserRepository) Update(id uuid.UUID, req models.UpdateUserRequest) (*models.User, error) {
	// Buscar utilizador atual
	user, err := r.GetByID(id)
	if err != nil {
		return nil, err
	}

	// Atualizar campos
	if req.Nome != nil {
		user.Nome = *req.Nome
	}
	if req.FotoURL != nil {
		user.FotoURL = req.FotoURL
	}
	if req.GoogleCalendarID != nil {
		user.GoogleCalendarID = req.GoogleCalendarID
	}
	if req.GoogleRefreshToken != nil {
		user.GoogleRefreshToken = req.GoogleRefreshToken
	}
	if req.Timezone != nil {
		user.Timezone = *req.Timezone
	}

	user.AtualizadoEm = time.Now()

	query := `
		UPDATE users
		SET nome = $1, foto_url = $2, google_calendar_id = $3, google_refresh_token = $4, timezone = $5, atualizado_em = $6
		WHERE id = $7
	`

	_, err = database.DB.Exec(
		query,
		user.Nome,
		user.FotoURL,
		user.GoogleCalendarID,
		user.GoogleRefreshToken,
		user.Timezone,
		user.AtualizadoEm,
		id,
	)

	if err != nil {
		return nil, fmt.Errorf("erro ao atualizar utilizador: %w", err)
	}

	return user, nil
}

// Delete elimina um utilizador
func (r *UserRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM users WHERE id = $1`

	result, err := database.DB.Exec(query, id)
	if err != nil {
		return fmt.Errorf("erro ao eliminar utilizador: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("erro ao verificar linhas afetadas: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("utilizador não encontrado")
	}

	return nil
}

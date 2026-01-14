package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/agataofrancisco/notario/internal/domain/models"
	"github.com/agataofrancisco/notario/pkg/database"
	"github.com/google/uuid"
)

// TaskRepository lida com operações de tarefas na base de dados
type TaskRepository struct{}

// NewTaskRepository cria uma nova instância do repositório
func NewTaskRepository() *TaskRepository {
	return &TaskRepository{}
}

// Create cria uma nova tarefa
func (r *TaskRepository) Create(userID uuid.UUID, req models.CreateTaskRequest) (*models.Task, error) {
	task := &models.Task{
		ID:                 uuid.New(),
		UserID:             userID,
		Titulo:             req.Titulo,
		Descricao:          req.Descricao,
		DataInicio:         req.DataInicio,
		DataFim:            req.DataInicio.Add(time.Duration(req.DuracaoMinutos) * time.Minute),
		DuracaoMinutos:     req.DuracaoMinutos,
		Prioridade:         req.Prioridade,
		AvisoAntesMinutos:  req.AvisoAntesMinutos,
		AvisoDepoisMinutos: req.AvisoDepoisMinutos,
		Estado:             models.EstadoPendente,
		Sincronizado:       false,
		Versao:             1,
		CriadoEm:           time.Now(),
		AtualizadoEm:       time.Now(),
	}

	if task.AvisoAntesMinutos == 0 {
		task.AvisoAntesMinutos = 15
	}
	if task.AvisoDepoisMinutos == 0 {
		task.AvisoDepoisMinutos = 5
	}

	query := `
		INSERT INTO tasks (
			id, user_id, titulo, descricao, data_inicio, data_fim, duracao_minutos,
			prioridade, aviso_antes_minutos, aviso_depois_minutos, estado,
			sincronizado, versao, criado_em, atualizado_em
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
		RETURNING id, criado_em, atualizado_em
	`

	err := database.DB.QueryRow(
		query,
		task.ID, task.UserID, task.Titulo, task.Descricao, task.DataInicio, task.DataFim,
		task.DuracaoMinutos, task.Prioridade, task.AvisoAntesMinutos, task.AvisoDepoisMinutos,
		task.Estado, task.Sincronizado, task.Versao, task.CriadoEm, task.AtualizadoEm,
	).Scan(&task.ID, &task.CriadoEm, &task.AtualizadoEm)

	if err != nil {
		return nil, fmt.Errorf("erro ao criar tarefa: %w", err)
	}

	return task, nil
}

// GetByID obtém uma tarefa por ID
func (r *TaskRepository) GetByID(id uuid.UUID) (*models.Task, error) {
	task := &models.Task{}

	query := `
		SELECT id, user_id, google_event_id, titulo, descricao, data_inicio, data_fim,
			   duracao_minutos, prioridade, aviso_antes_minutos, aviso_depois_minutos,
			   estado, tempo_real_minutos, sincronizado, versao, criado_em, atualizado_em, concluido_em
		FROM tasks
		WHERE id = $1
	`

	err := database.DB.QueryRow(query, id).Scan(
		&task.ID, &task.UserID, &task.GoogleEventID, &task.Titulo, &task.Descricao,
		&task.DataInicio, &task.DataFim, &task.DuracaoMinutos, &task.Prioridade,
		&task.AvisoAntesMinutos, &task.AvisoDepoisMinutos, &task.Estado,
		&task.TempoRealMinutos, &task.Sincronizado, &task.Versao,
		&task.CriadoEm, &task.AtualizadoEm, &task.ConcluidoEm,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("tarefa não encontrada")
	}

	if err != nil {
		return nil, fmt.Errorf("erro ao obter tarefa: %w", err)
	}

	return task, nil
}

// GetByUserID obtém todas as tarefas de um utilizador
func (r *TaskRepository) GetByUserID(userID uuid.UUID) ([]models.Task, error) {
	query := `
		SELECT id, user_id, google_event_id, titulo, descricao, data_inicio, data_fim,
			   duracao_minutos, prioridade, aviso_antes_minutos, aviso_depois_minutos,
			   estado, tempo_real_minutos, sincronizado, versao, criado_em, atualizado_em, concluido_em
		FROM tasks
		WHERE user_id = $1
		ORDER BY data_inicio ASC
	`

	rows, err := database.DB.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("erro ao obter tarefas: %w", err)
	}
	defer rows.Close()

	tasks := []models.Task{}
	for rows.Next() {
		var task models.Task
		err := rows.Scan(
			&task.ID, &task.UserID, &task.GoogleEventID, &task.Titulo, &task.Descricao,
			&task.DataInicio, &task.DataFim, &task.DuracaoMinutos, &task.Prioridade,
			&task.AvisoAntesMinutos, &task.AvisoDepoisMinutos, &task.Estado,
			&task.TempoRealMinutos, &task.Sincronizado, &task.Versao,
			&task.CriadoEm, &task.AtualizadoEm, &task.ConcluidoEm,
		)
		if err != nil {
			return nil, fmt.Errorf("erro ao escanear tarefa: %w", err)
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

// GetByUserAndDate obtém tarefas de um utilizador numa data específica
func (r *TaskRepository) GetByUserAndDate(userID uuid.UUID, date time.Time) ([]models.Task, error) {
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
	endOfDay := startOfDay.Add(24 * time.Hour)

	query := `
		SELECT id, user_id, google_event_id, titulo, descricao, data_inicio, data_fim,
			   duracao_minutos, prioridade, aviso_antes_minutos, aviso_depois_minutos,
			   estado, tempo_real_minutos, sincronizado, versao, criado_em, atualizado_em, concluido_em
		FROM tasks
		WHERE user_id = $1 AND data_inicio >= $2 AND data_inicio < $3
		ORDER BY data_inicio ASC
	`

	rows, err := database.DB.Query(query, userID, startOfDay, endOfDay)
	if err != nil {
		return nil, fmt.Errorf("erro ao obter tarefas por data: %w", err)
	}
	defer rows.Close()

	tasks := []models.Task{}
	for rows.Next() {
		var task models.Task
		err := rows.Scan(
			&task.ID, &task.UserID, &task.GoogleEventID, &task.Titulo, &task.Descricao,
			&task.DataInicio, &task.DataFim, &task.DuracaoMinutos, &task.Prioridade,
			&task.AvisoAntesMinutos, &task.AvisoDepoisMinutos, &task.Estado,
			&task.TempoRealMinutos, &task.Sincronizado, &task.Versao,
			&task.CriadoEm, &task.AtualizadoEm, &task.ConcluidoEm,
		)
		if err != nil {
			return nil, fmt.Errorf("erro ao escanear tarefa: %w", err)
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

// Update atualiza uma tarefa
func (r *TaskRepository) Update(id uuid.UUID, req models.UpdateTaskRequest) (*models.Task, error) {
	task, err := r.GetByID(id)
	if err != nil {
		return nil, err
	}

	// Atualizar campos
	if req.Titulo != nil {
		task.Titulo = *req.Titulo
	}
	if req.Descricao != nil {
		task.Descricao = req.Descricao
	}
	if req.DataInicio != nil {
		task.DataInicio = *req.DataInicio
		if req.DuracaoMinutos != nil {
			task.DataFim = task.DataInicio.Add(time.Duration(*req.DuracaoMinutos) * time.Minute)
		} else {
			task.DataFim = task.DataInicio.Add(time.Duration(task.DuracaoMinutos) * time.Minute)
		}
	}
	if req.DuracaoMinutos != nil {
		task.DuracaoMinutos = *req.DuracaoMinutos
		task.DataFim = task.DataInicio.Add(time.Duration(task.DuracaoMinutos) * time.Minute)
	}
	if req.Prioridade != nil {
		task.Prioridade = *req.Prioridade
	}
	if req.AvisoAntesMinutos != nil {
		task.AvisoAntesMinutos = *req.AvisoAntesMinutos
	}
	if req.AvisoDepoisMinutos != nil {
		task.AvisoDepoisMinutos = *req.AvisoDepoisMinutos
	}
	if req.Estado != nil {
		task.Estado = *req.Estado
	}

	task.AtualizadoEm = time.Now()
	task.Versao++
	task.Sincronizado = false

	query := `
		UPDATE tasks
		SET titulo = $1, descricao = $2, data_inicio = $3, data_fim = $4, duracao_minutos = $5,
			prioridade = $6, aviso_antes_minutos = $7, aviso_depois_minutos = $8, estado = $9,
			sincronizado = $10, versao = $11, atualizado_em = $12
		WHERE id = $13
	`

	_, err = database.DB.Exec(
		query,
		task.Titulo, task.Descricao, task.DataInicio, task.DataFim, task.DuracaoMinutos,
		task.Prioridade, task.AvisoAntesMinutos, task.AvisoDepoisMinutos, task.Estado,
		task.Sincronizado, task.Versao, task.AtualizadoEm, id,
	)

	if err != nil {
		return nil, fmt.Errorf("erro ao atualizar tarefa: %w", err)
	}

	return task, nil
}

// Delete elimina uma tarefa
func (r *TaskRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM tasks WHERE id = $1`

	result, err := database.DB.Exec(query, id)
	if err != nil {
		return fmt.Errorf("erro ao eliminar tarefa: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("erro ao verificar linhas afetadas: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("tarefa não encontrada")
	}

	return nil
}

// UpdateGoogleEventID atualiza o ID do evento do Google Calendar
func (r *TaskRepository) UpdateGoogleEventID(id uuid.UUID, googleEventID string) error {
	query := `UPDATE tasks SET google_event_id = $1, sincronizado = true WHERE id = $2`

	_, err := database.DB.Exec(query, googleEventID, id)
	if err != nil {
		return fmt.Errorf("erro ao atualizar Google Event ID: %w", err)
	}

	return nil
}

// MarkAsStarted marca uma tarefa como iniciada
func (r *TaskRepository) MarkAsStarted(id uuid.UUID) error {
	query := `UPDATE tasks SET estado = $1, atualizado_em = $2 WHERE id = $3`

	_, err := database.DB.Exec(query, models.EstadoEmExecucao, time.Now(), id)
	if err != nil {
		return fmt.Errorf("erro ao marcar tarefa como iniciada: %w", err)
	}

	return nil
}

// MarkAsCompleted marca uma tarefa como concluída
func (r *TaskRepository) MarkAsCompleted(id uuid.UUID, tempoRealMinutos int) error {
	now := time.Now()
	query := `UPDATE tasks SET estado = $1, tempo_real_minutos = $2, concluido_em = $3, atualizado_em = $4 WHERE id = $5`

	_, err := database.DB.Exec(query, models.EstadoConcluida, tempoRealMinutos, now, now, id)
	if err != nil {
		return fmt.Errorf("erro ao marcar tarefa como concluída: %w", err)
	}

	return nil
}

// MarkAsSkipped marca uma tarefa como pulada
func (r *TaskRepository) MarkAsSkipped(id uuid.UUID) error {
	query := `UPDATE tasks SET estado = $1, atualizado_em = $2 WHERE id = $3`

	_, err := database.DB.Exec(query, models.EstadoPulada, time.Now(), id)
	if err != nil {
		return fmt.Errorf("erro ao marcar tarefa como pulada: %w", err)
	}

	return nil
}

package handlers

import (
	"net/http"
	"time"

	"github.com/agataofrancisco/notario/internal/domain/models"
	"github.com/agataofrancisco/notario/internal/domain/services"
	"github.com/agataofrancisco/notario/internal/repository"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// TaskHandler lida com operações de tarefas
type TaskHandler struct {
	taskRepo        *repository.TaskRepository
	scheduleService *services.ScheduleService
}

// NewTaskHandler cria uma nova instância
func NewTaskHandler(taskRepo *repository.TaskRepository, scheduleService *services.ScheduleService) *TaskHandler {
	return &TaskHandler{
		taskRepo:        taskRepo,
		scheduleService: scheduleService,
	}
}

// List lista tarefas do utilizador
func (h *TaskHandler) List(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de utilizador inválido"})
		return
	}

	// Filtros opcionais
	dataInicioStr := c.Query("data_inicio")
	dataFimStr := c.Query("data_fim")
	estado := c.Query("estado")

	var tasks []models.Task

	// Se tiver filtro de data
	if dataInicioStr != "" {
		dataInicio, err := time.Parse(time.RFC3339, dataInicioStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Formato de data inválido"})
			return
		}

		tasks, err = h.taskRepo.GetByUserAndDate(uid, dataInicio)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao buscar tarefas"})
			return
		}
	} else {
		tasks, err = h.taskRepo.GetByUserID(uid)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao buscar tarefas"})
			return
		}
	}

	// Filtrar por estado se especificado
	if estado != "" {
		filtered := []models.Task{}
		for _, task := range tasks {
			if string(task.Estado) == estado {
				filtered = append(filtered, task)
			}
		}
		tasks = filtered
	}

	c.JSON(http.StatusOK, gin.H{"tasks": tasks})
}

// Create cria uma nova tarefa
func (h *TaskHandler) Create(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de utilizador inválido"})
		return
	}

	var req models.CreateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dados inválidos", "details": err.Error()})
		return
	}

	// Criar tarefa
	task, err := h.taskRepo.Create(uid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao criar tarefa"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"task": task})
}

// Get obtém uma tarefa específica
func (h *TaskHandler) Get(c *gin.Context) {
	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	task, err := h.taskRepo.GetByID(taskID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tarefa não encontrada"})
		return
	}

	// Verificar se a tarefa pertence ao utilizador
	userID := c.GetString("user_id")
	if task.UserID.String() != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Acesso negado"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"task": task})
}

// Update atualiza uma tarefa
func (h *TaskHandler) Update(c *gin.Context) {
	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	// Verificar se a tarefa pertence ao utilizador
	task, err := h.taskRepo.GetByID(taskID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tarefa não encontrada"})
		return
	}

	userID := c.GetString("user_id")
	if task.UserID.String() != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Acesso negado"})
		return
	}

	var req models.UpdateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dados inválidos"})
		return
	}

	updatedTask, err := h.taskRepo.Update(taskID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao atualizar tarefa"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"task": updatedTask})
}

// Delete elimina uma tarefa
func (h *TaskHandler) Delete(c *gin.Context) {
	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	// Verificar se a tarefa pertence ao utilizador
	task, err := h.taskRepo.GetByID(taskID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tarefa não encontrada"})
		return
	}

	userID := c.GetString("user_id")
	if task.UserID.String() != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Acesso negado"})
		return
	}

	if err := h.taskRepo.Delete(taskID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao eliminar tarefa"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tarefa eliminada com sucesso"})
}

// ValidateDay valida se uma tarefa cabe num dia
func (h *TaskHandler) ValidateDay(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de utilizador inválido"})
		return
	}

	var req models.ValidateDayRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dados inválidos"})
		return
	}

	response, err := h.scheduleService.ValidateDay(uid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao validar dia"})
		return
	}

	c.JSON(http.StatusOK, response)
}

// Start inicia execução de uma tarefa
func (h *TaskHandler) Start(c *gin.Context) {
	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	// Verificar se a tarefa pertence ao utilizador
	task, err := h.taskRepo.GetByID(taskID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tarefa não encontrada"})
		return
	}

	userID := c.GetString("user_id")
	if task.UserID.String() != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Acesso negado"})
		return
	}

	// Marcar como iniciada
	if err := h.taskRepo.MarkAsStarted(taskID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao iniciar tarefa"})
		return
	}

	response := models.StartTaskResponse{
		TaskID:          taskID,
		DataInicio:      time.Now(),
		DataFimPrevista: time.Now().Add(time.Duration(task.DuracaoMinutos) * time.Minute),
		Mensagem:        "Tarefa iniciada! Boa sorte!",
	}

	c.JSON(http.StatusOK, response)
}

// Complete conclui uma tarefa
func (h *TaskHandler) Complete(c *gin.Context) {
	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	// Verificar se a tarefa pertence ao utilizador
	task, err := h.taskRepo.GetByID(taskID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tarefa não encontrada"})
		return
	}

	userID := c.GetString("user_id")
	if task.UserID.String() != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Acesso negado"})
		return
	}

	var req models.CompleteTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dados inválidos"})
		return
	}

	// Marcar como concluída
	if err := h.taskRepo.MarkAsCompleted(taskID, req.TempoRealMinutos); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao concluir tarefa"})
		return
	}

	// Calcular tempo extra e impacto
	response, err := h.scheduleService.CalcularTempoExtra(taskID, req.TempoRealMinutos)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao calcular tempo extra"})
		return
	}

	c.JSON(http.StatusOK, response)
}

// Skip pula uma tarefa
func (h *TaskHandler) Skip(c *gin.Context) {
	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	// Verificar se a tarefa pertence ao utilizador
	task, err := h.taskRepo.GetByID(taskID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tarefa não encontrada"})
		return
	}

	userID := c.GetString("user_id")
	uid, _ := uuid.Parse(userID)
	if task.UserID.String() != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Acesso negado"})
		return
	}

	var req models.SkipTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dados inválidos"})
		return
	}

	// Marcar como pulada
	if err := h.taskRepo.MarkAsSkipped(taskID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao pular tarefa"})
		return
	}

	// Sugerir dias alternativos
	diasAlternativos, err := h.scheduleService.SugerirDiasAlternativos(uid, task.DuracaoMinutos)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao sugerir dias"})
		return
	}

	response := models.SkipTaskResponse{
		TaskID:           taskID,
		DiasAlternativos: diasAlternativos,
		Mensagem:         "Tarefa pulada. Sugerimos reagendar para:",
	}

	c.JSON(http.StatusOK, response)
}

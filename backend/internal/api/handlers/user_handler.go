package handlers

import (
	"net/http"

	"github.com/agataofrancisco/notario/internal/domain/models"
	"github.com/agataofrancisco/notario/internal/repository"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UserHandler lida com operações de utilizadores
type UserHandler struct {
	userRepo *repository.UserRepository
}

// NewUserHandler cria uma nova instância
func NewUserHandler(userRepo *repository.UserRepository) *UserHandler {
	return &UserHandler{
		userRepo: userRepo,
	}
}

// GetMe obtém dados do utilizador autenticado
func (h *UserHandler) GetMe(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de utilizador inválido"})
		return
	}

	user, err := h.userRepo.GetByID(uid)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Utilizador não encontrado"})
		return
	}

	c.JSON(http.StatusOK, user.ToResponse())
}

// UpdateMe atualiza dados do utilizador autenticado
func (h *UserHandler) UpdateMe(c *gin.Context) {
	userID := c.GetString("user_id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de utilizador inválido"})
		return
	}

	var req models.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dados inválidos"})
		return
	}

	user, err := h.userRepo.Update(uid, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao atualizar utilizador"})
		return
	}

	c.JSON(http.StatusOK, user.ToResponse())
}

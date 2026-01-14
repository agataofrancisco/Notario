package handlers

import (
	"net/http"
	"time"

	"github.com/agataofrancisco/notario/internal/domain/models"
	"github.com/agataofrancisco/notario/internal/repository"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"google.golang.org/api/oauth2/v2"
	"google.golang.org/api/option"
)

// AuthHandler lida com autenticação
type AuthHandler struct {
	userRepo  *repository.UserRepository
	jwtSecret string
}

// NewAuthHandler cria uma nova instância
func NewAuthHandler(userRepo *repository.UserRepository, jwtSecret string) *AuthHandler {
	return &AuthHandler{
		userRepo:  userRepo,
		jwtSecret: jwtSecret,
	}
}

// GoogleLoginRequest representa a requisição de login do Google
type GoogleLoginRequest struct {
	IDToken     string `json:"id_token" binding:"required"`
	AccessToken string `json:"access_token" binding:"required"`
}

// AuthResponse representa a resposta de autenticação
type AuthResponse struct {
	User     models.UserResponse `json:"user"`
	JWTToken string              `json:"jwt_token"`
}

// GoogleLogin autentica utilizador via Google OAuth
func (h *AuthHandler) GoogleLogin(c *gin.Context) {
	var req GoogleLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dados inválidos"})
		return
	}

	// Verificar token do Google
	ctx := c.Request.Context()
	oauth2Service, err := oauth2.NewService(ctx, option.WithHTTPClient(http.DefaultClient))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao verificar token"})
		return
	}

	tokenInfo, err := oauth2Service.Tokeninfo().IdToken(req.IDToken).Do()
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token inválido"})
		return
	}

	// Verificar se utilizador já existe
	user, err := h.userRepo.GetByGoogleID(tokenInfo.UserId)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao buscar utilizador"})
		return
	}

	// Se não existe, criar novo utilizador
	if user == nil {
		createReq := models.CreateUserRequest{
			GoogleID: tokenInfo.UserId,
			Email:    tokenInfo.Email,
			Nome:     tokenInfo.Email, // Usar email como nome inicial
			Timezone: "Europe/Lisbon",
		}

		// Se tiver foto no perfil
		if tokenInfo.Picture != "" {
			createReq.FotoURL = &tokenInfo.Picture
		}

		user, err = h.userRepo.Create(createReq)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao criar utilizador"})
			return
		}
	}

	// Gerar JWT token
	jwtToken, err := h.generateJWT(user.ID.String())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao gerar token"})
		return
	}

	c.JSON(http.StatusOK, AuthResponse{
		User:     user.ToResponse(),
		JWTToken: jwtToken,
	})
}

// generateJWT gera um token JWT
func (h *AuthHandler) generateJWT(userID string) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(), // 7 dias
		"iat":     time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(h.jwtSecret))
}

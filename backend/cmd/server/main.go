package main

import (
	"log"

	"github.com/agataofrancisco/notario/internal/api"
	"github.com/agataofrancisco/notario/internal/config"
	"github.com/agataofrancisco/notario/pkg/database"
	"github.com/gin-gonic/gin"
)

func main() {
	log.Println("🚀 Iniciando NOTÁRIO Backend...")

	// Carregar configurações
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("❌ Erro ao carregar configurações: %v", err)
	}

	log.Printf("📝 Ambiente: %s", cfg.Server.Environment)

	// Conectar à base de dados
	if err := database.Connect(cfg.GetDSN()); err != nil {
		log.Fatalf("❌ Erro ao conectar à base de dados: %v", err)
	}
	defer database.Close()

	// Inicializar schema
	if err := database.InitSchema(); err != nil {
		log.Fatalf("❌ Erro ao inicializar schema: %v", err)
	}

	// Configurar Gin
	if cfg.Server.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// Configurar CORS
	router.Use(corsMiddleware())

	// Configurar rotas
	api.SetupRoutes(router, cfg.JWT.Secret)

	// Iniciar servidor
	log.Printf("✅ Servidor NOTÁRIO rodando na porta %s", cfg.Server.Port)
	if err := router.Run(":" + cfg.Server.Port); err != nil {
		log.Fatalf("❌ Erro ao iniciar servidor: %v", err)
	}
}

// corsMiddleware configura CORS
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

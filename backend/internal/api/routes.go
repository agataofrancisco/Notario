package api

import (
	"github.com/agataofrancisco/notario/internal/api/handlers"
	"github.com/agataofrancisco/notario/internal/api/middleware"
	"github.com/agataofrancisco/notario/internal/domain/services"
	"github.com/agataofrancisco/notario/internal/repository"
	"github.com/gin-gonic/gin"
)

// SetupRoutes configura todas as rotas da API
func SetupRoutes(router *gin.Engine, jwtSecret string) {
	// Repositórios
	userRepo := repository.NewUserRepository()
	taskRepo := repository.NewTaskRepository()
	noteRepo := repository.NewNoteRepository()

	// Serviços
	scheduleService := services.NewScheduleService(taskRepo)

	// Handlers
	authHandler := handlers.NewAuthHandler(userRepo, jwtSecret)
	taskHandler := handlers.NewTaskHandler(taskRepo, scheduleService)
	userHandler := handlers.NewUserHandler(userRepo)

	// Grupo de rotas da API
	api := router.Group("/api")
	{
		// Rotas públicas (sem autenticação)
		auth := api.Group("/auth")
		{
			auth.POST("/google", authHandler.GoogleLogin)
		}

		// Rotas protegidas (requerem autenticação)
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware(jwtSecret))
		{
			// Utilizadores
			users := protected.Group("/users")
			{
				users.GET("/me", userHandler.GetMe)
				users.PATCH("/me", userHandler.UpdateMe)
			}

			// Tarefas
			tasks := protected.Group("/tasks")
			{
				tasks.GET("", taskHandler.List)
				tasks.POST("", taskHandler.Create)
				tasks.GET("/:id", taskHandler.Get)
				tasks.PUT("/:id", taskHandler.Update)
				tasks.DELETE("/:id", taskHandler.Delete)

				// Validação
				tasks.POST("/validate-day", taskHandler.ValidateDay)

				// Execução
				tasks.POST("/:id/start", taskHandler.Start)
				tasks.POST("/:id/complete", taskHandler.Complete)
				tasks.POST("/:id/skip", taskHandler.Skip)
			}

			// Notas (TODO: implementar handlers)
			// notes := protected.Group("/notes")
			// {
			// 	notes.GET("", noteHandler.List)
			// 	notes.POST("", noteHandler.Create)
			// 	notes.GET("/:id", noteHandler.Get)
			// 	notes.PUT("/:id", noteHandler.Update)
			// 	notes.DELETE("/:id", noteHandler.Delete)
			// }

			// Estatísticas (TODO: implementar handlers)
			// statistics := protected.Group("/statistics")
			// {
			// 	statistics.GET("", statisticsHandler.Get)
			// }

			// Sincronização (TODO: implementar handlers)
			// sync := protected.Group("/sync")
			// {
			// 	sync.POST("", syncHandler.Sync)
			// }
		}
	}

	// Rota de health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "notario-api",
		})
	})
}

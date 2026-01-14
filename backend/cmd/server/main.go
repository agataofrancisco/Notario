package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/agataofrancisco/notario/internal/config"
	"github.com/agataofrancisco/notario/pkg/database"
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

	// TODO: Inicializar router e handlers

	log.Printf("✅ Servidor rodando na porta %s", cfg.Server.Port)

	// Aguardar sinal de encerramento
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Encerrando servidor...")
}

package database

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/lib/pq"
)

// DB é a instância global da base de dados
var DB *sql.DB

// Connect estabelece conexão com PostgreSQL
func Connect(dsn string) error {
	var err error
	DB, err = sql.Open("postgres", dsn)
	if err != nil {
		return fmt.Errorf("erro ao abrir conexão: %w", err)
	}

	// Configurar pool de conexões
	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(5)
	DB.SetConnMaxLifetime(5 * time.Minute)

	// Testar conexão
	if err := DB.Ping(); err != nil {
		return fmt.Errorf("erro ao pingar base de dados: %w", err)
	}

	log.Println("✅ Conexão com PostgreSQL estabelecida")
	return nil
}

// Close fecha a conexão com a base de dados
func Close() error {
	if DB != nil {
		return DB.Close()
	}
	return nil
}

// InitSchema cria as tabelas se não existirem
func InitSchema() error {
	schema := `
	-- Tabela de utilizadores
	CREATE TABLE IF NOT EXISTS users (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		google_id VARCHAR(255) UNIQUE NOT NULL,
		email VARCHAR(255) UNIQUE NOT NULL,
		nome VARCHAR(255) NOT NULL,
		foto_url TEXT,
		google_calendar_id VARCHAR(255),
		google_refresh_token TEXT,
		timezone VARCHAR(50) DEFAULT 'Europe/Lisbon',
		criado_em TIMESTAMP DEFAULT NOW(),
		atualizado_em TIMESTAMP DEFAULT NOW()
	);

	-- Tabela de tarefas
	CREATE TABLE IF NOT EXISTS tasks (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		google_event_id VARCHAR(255) UNIQUE,
		
		titulo VARCHAR(255) NOT NULL,
		descricao TEXT,
		
		data_inicio TIMESTAMP NOT NULL,
		data_fim TIMESTAMP NOT NULL,
		duracao_minutos INTEGER NOT NULL,
		
		prioridade VARCHAR(20) NOT NULL CHECK (prioridade IN ('baixa', 'media', 'alta')),
		
		aviso_antes_minutos INTEGER DEFAULT 15,
		aviso_depois_minutos INTEGER DEFAULT 5,
		
		estado VARCHAR(20) DEFAULT 'pendente' CHECK (estado IN ('pendente', 'em_execucao', 'concluida', 'pulada', 'cancelada')),
		tempo_real_minutos INTEGER,
		
		sincronizado BOOLEAN DEFAULT FALSE,
		versao INTEGER DEFAULT 1,
		
		criado_em TIMESTAMP DEFAULT NOW(),
		atualizado_em TIMESTAMP DEFAULT NOW(),
		concluido_em TIMESTAMP
	);

	CREATE INDEX IF NOT EXISTS idx_tasks_user_data ON tasks(user_id, data_inicio);
	CREATE INDEX IF NOT EXISTS idx_tasks_google_event ON tasks(google_event_id);
	CREATE INDEX IF NOT EXISTS idx_tasks_estado ON tasks(estado);

	-- Tabela de notas
	CREATE TABLE IF NOT EXISTS notes (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		google_event_id VARCHAR(255) UNIQUE,
		
		titulo VARCHAR(255) NOT NULL,
		conteudo TEXT NOT NULL,
		
		data_lembrete TIMESTAMP NOT NULL,
		
		sincronizado BOOLEAN DEFAULT FALSE,
		versao INTEGER DEFAULT 1,
		
		criado_em TIMESTAMP DEFAULT NOW(),
		atualizado_em TIMESTAMP DEFAULT NOW()
	);

	CREATE INDEX IF NOT EXISTS idx_notes_user_data ON notes(user_id, data_lembrete);

	-- Tabela de fila de sincronização
	CREATE TABLE IF NOT EXISTS sync_queue (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		entidade_tipo VARCHAR(20) NOT NULL CHECK (entidade_tipo IN ('task', 'note')),
		entidade_id UUID NOT NULL,
		operacao VARCHAR(20) NOT NULL CHECK (operacao IN ('create', 'update', 'delete')),
		payload JSONB NOT NULL,
		processado BOOLEAN DEFAULT FALSE,
		tentativas INTEGER DEFAULT 0,
		erro TEXT,
		criado_em TIMESTAMP DEFAULT NOW()
	);

	CREATE INDEX IF NOT EXISTS idx_sync_queue_user ON sync_queue(user_id, processado);

	-- Tabela de estatísticas
	CREATE TABLE IF NOT EXISTS statistics (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		data DATE NOT NULL,
		
		tarefas_planejadas INTEGER DEFAULT 0,
		tarefas_concluidas INTEGER DEFAULT 0,
		tarefas_puladas INTEGER DEFAULT 0,
		tempo_planejado_minutos INTEGER DEFAULT 0,
		tempo_real_minutos INTEGER DEFAULT 0,
		
		pontuacao_produtividade DECIMAL(5,2),
		
		criado_em TIMESTAMP DEFAULT NOW(),
		
		UNIQUE(user_id, data)
	);

	CREATE INDEX IF NOT EXISTS idx_statistics_user_data ON statistics(user_id, data DESC);
	`

	_, err := DB.Exec(schema)
	if err != nil {
		return fmt.Errorf("erro ao criar schema: %w", err)
	}

	log.Println("✅ Schema da base de dados inicializado")
	return nil
}

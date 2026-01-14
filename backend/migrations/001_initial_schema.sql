-- NOTÁRIO - Schema Inicial
-- Criação de todas as tabelas do sistema

-- Extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tabela de utilizadores
CREATE TABLE users (
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

CREATE INDEX idx_users_google_id ON users(google_id);
CREATE INDEX idx_users_email ON users(email);

-- Tabela de tarefas
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    google_event_id VARCHAR(255),
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    data_inicio TIMESTAMP NOT NULL,
    data_fim TIMESTAMP NOT NULL,
    duracao_minutos INTEGER NOT NULL,
    prioridade VARCHAR(20) NOT NULL CHECK (prioridade IN ('baixa', 'media', 'alta')),
    aviso_antes_minutos INTEGER DEFAULT 10,
    aviso_depois_minutos INTEGER DEFAULT 5,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendente' 
        CHECK (estado IN ('pendente', 'em_execucao', 'concluida', 'pulada', 'cancelada')),
    tempo_real_minutos INTEGER,
    sincronizado BOOLEAN DEFAULT FALSE,
    versao INTEGER DEFAULT 1,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW(),
    concluido_em TIMESTAMP
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_data_inicio ON tasks(data_inicio);
CREATE INDEX idx_tasks_estado ON tasks(estado);
CREATE INDEX idx_tasks_google_event_id ON tasks(google_event_id);
CREATE INDEX idx_tasks_user_date ON tasks(user_id, data_inicio);

-- Tabela de notas
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    google_event_id VARCHAR(255),
    titulo VARCHAR(255) NOT NULL,
    conteudo TEXT NOT NULL,
    data_lembrete TIMESTAMP NOT NULL,
    sincronizado BOOLEAN DEFAULT FALSE,
    versao INTEGER DEFAULT 1,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_data_lembrete ON notes(data_lembrete);

-- Tabela de estatísticas
CREATE TABLE statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    data DATE NOT NULL,
    tarefas_planejadas INTEGER DEFAULT 0,
    tarefas_concluidas INTEGER DEFAULT 0,
    tempo_planejado_minutos INTEGER DEFAULT 0,
    tempo_real_minutos INTEGER DEFAULT 0,
    pontuacao DECIMAL(5,2) DEFAULT 0,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, data)
);

CREATE INDEX idx_statistics_user_id ON statistics(user_id);
CREATE INDEX idx_statistics_data ON statistics(data);

-- Trigger para atualizar atualizado_em automaticamente
CREATE OR REPLACE FUNCTION update_atualizado_em()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_atualizado_em
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_atualizado_em();

CREATE TRIGGER tasks_atualizado_em
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_atualizado_em();

CREATE TRIGGER notes_atualizado_em
    BEFORE UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_atualizado_em();

CREATE TRIGGER statistics_atualizado_em
    BEFORE UPDATE ON statistics
    FOR EACH ROW
    EXECUTE FUNCTION update_atualizado_em();

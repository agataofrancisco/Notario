package models

import (
	"time"

	"github.com/google/uuid"
)

// Prioridade representa os níveis de prioridade
type Prioridade string

const (
	PrioridadeBaixa Prioridade = "baixa"
	PrioridadeMedia Prioridade = "media"
	PrioridadeAlta  Prioridade = "alta"
)

// EstadoTarefa representa os estados possíveis de uma tarefa
type EstadoTarefa string

const (
	EstadoPendente   EstadoTarefa = "pendente"
	EstadoEmExecucao EstadoTarefa = "em_execucao"
	EstadoConcluida  EstadoTarefa = "concluida"
	EstadoPulada     EstadoTarefa = "pulada"
	EstadoCancelada  EstadoTarefa = "cancelada"
)

// Task representa uma tarefa do sistema
type Task struct {
	ID                 uuid.UUID    `json:"id"`
	UserID             uuid.UUID    `json:"user_id"`
	GoogleEventID      *string      `json:"google_event_id,omitempty"`
	Titulo             string       `json:"titulo"`
	Descricao          *string      `json:"descricao,omitempty"`
	DataInicio         time.Time    `json:"data_inicio"`
	DataFim            time.Time    `json:"data_fim"`
	DuracaoMinutos     int          `json:"duracao_minutos"`
	Prioridade         Prioridade   `json:"prioridade"`
	AvisoAntesMinutos  int          `json:"aviso_antes_minutos"`
	AvisoDepoisMinutos int          `json:"aviso_depois_minutos"`
	Estado             EstadoTarefa `json:"estado"`
	TempoRealMinutos   *int         `json:"tempo_real_minutos,omitempty"`
	Sincronizado       bool         `json:"sincronizado"`
	Versao             int          `json:"versao"`
	CriadoEm           time.Time    `json:"criado_em"`
	AtualizadoEm       time.Time    `json:"atualizado_em"`
	ConcluidoEm        *time.Time   `json:"concluido_em,omitempty"`
}

// CreateTaskRequest representa os dados para criar uma tarefa
type CreateTaskRequest struct {
	Titulo             string     `json:"titulo" binding:"required"`
	Descricao          *string    `json:"descricao"`
	DataInicio         time.Time  `json:"data_inicio" binding:"required"`
	DuracaoMinutos     int        `json:"duracao_minutos" binding:"required,min=1"`
	Prioridade         Prioridade `json:"prioridade" binding:"required,oneof=baixa media alta"`
	AvisoAntesMinutos  int        `json:"aviso_antes_minutos"`
	AvisoDepoisMinutos int        `json:"aviso_depois_minutos"`
}

// UpdateTaskRequest representa os dados para atualizar uma tarefa
type UpdateTaskRequest struct {
	Titulo             *string       `json:"titulo"`
	Descricao          *string       `json:"descricao"`
	DataInicio         *time.Time    `json:"data_inicio"`
	DuracaoMinutos     *int          `json:"duracao_minutos" binding:"omitempty,min=1"`
	Prioridade         *Prioridade   `json:"prioridade" binding:"omitempty,oneof=baixa media alta"`
	AvisoAntesMinutos  *int          `json:"aviso_antes_minutos"`
	AvisoDepoisMinutos *int          `json:"aviso_depois_minutos"`
	Estado             *EstadoTarefa `json:"estado" binding:"omitempty,oneof=pendente em_execucao concluida pulada cancelada"`
}

// ValidateDayRequest representa a requisição para validar um dia
type ValidateDayRequest struct {
	Data           time.Time  `json:"data" binding:"required"`
	DuracaoMinutos int        `json:"duracao_minutos" binding:"required,min=1"`
	Prioridade     Prioridade `json:"prioridade" binding:"required,oneof=baixa media alta"`
}

// ValidateDayResponse representa a resposta da validação de dia
type ValidateDayResponse struct {
	Viavel             bool          `json:"viavel"`
	TempoLivreMinutos  int           `json:"tempo_livre_minutos"`
	RequereConfirmacao bool          `json:"requere_confirmacao"`
	TarefasParaMover   []Task        `json:"tarefas_para_mover,omitempty"`
	DiasAlternativos   []SugestaoDia `json:"dias_alternativos,omitempty"`
	Mensagem           string        `json:"mensagem"`
}

// SugestaoDia representa uma sugestão de dia alternativo
type SugestaoDia struct {
	Data              time.Time `json:"data"`
	TempoLivreMinutos int       `json:"tempo_livre_minutos"`
	Carga             string    `json:"carga"` // "leve", "moderado", "cheio"
	Recomendado       bool      `json:"recomendado"`
}

// StartTaskResponse representa a resposta ao iniciar uma tarefa
type StartTaskResponse struct {
	TaskID          uuid.UUID `json:"task_id"`
	DataInicio      time.Time `json:"data_inicio"`
	DataFimPrevista time.Time `json:"data_fim_prevista"`
	Mensagem        string    `json:"mensagem"`
}

// CompleteTaskRequest representa a requisição para concluir uma tarefa
type CompleteTaskRequest struct {
	TempoRealMinutos int  `json:"tempo_real_minutos" binding:"required,min=1"`
	Concluida        bool `json:"concluida" binding:"required"`
}

// CompleteTaskResponse representa a resposta ao concluir uma tarefa
type CompleteTaskResponse struct {
	TaskID               uuid.UUID `json:"task_id"`
	TempoExtraMinutos    int       `json:"tempo_extra_minutos"`
	TarefasAfetadas      []Task    `json:"tarefas_afetadas,omitempty"`
	RequereReagendamento bool      `json:"requere_reagendamento"`
	Mensagem             string    `json:"mensagem"`
}

// SkipTaskRequest representa a requisição para pular uma tarefa
type SkipTaskRequest struct {
	Motivo string `json:"motivo"`
}

// SkipTaskResponse representa a resposta ao pular uma tarefa
type SkipTaskResponse struct {
	TaskID           uuid.UUID     `json:"task_id"`
	NovaData         *time.Time    `json:"nova_data,omitempty"`
	DiasAlternativos []SugestaoDia `json:"dias_alternativos,omitempty"`
	Mensagem         string        `json:"mensagem"`
}

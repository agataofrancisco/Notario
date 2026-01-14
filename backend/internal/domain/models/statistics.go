package models

import (
	"time"

	"github.com/google/uuid"
)

// Statistics representa as estatísticas de um dia
type Statistics struct {
	ID                     uuid.UUID `json:"id"`
	UserID                 uuid.UUID `json:"user_id"`
	Data                   time.Time `json:"data"`
	TarefasPlanejadas      int       `json:"tarefas_planejadas"`
	TarefasConcluidas      int       `json:"tarefas_concluidas"`
	TarefasPuladas         int       `json:"tarefas_puladas"`
	TempoPlanejadoMinutos  int       `json:"tempo_planejado_minutos"`
	TempoRealMinutos       int       `json:"tempo_real_minutos"`
	PontuacaoProdutividade float64   `json:"pontuacao_produtividade"`
	CriadoEm               time.Time `json:"criado_em"`
}

// DailyStatsResponse representa as estatísticas de um dia
type DailyStatsResponse struct {
	Data                   time.Time `json:"data"`
	TarefasPlanejadas      int       `json:"tarefas_planejadas"`
	TarefasConcluidas      int       `json:"tarefas_concluidas"`
	TarefasPuladas         int       `json:"tarefas_puladas"`
	TaxaConclusao          float64   `json:"taxa_conclusao"`
	TempoPlanejadoMinutos  int       `json:"tempo_planejado_minutos"`
	TempoRealMinutos       int       `json:"tempo_real_minutos"`
	PontuacaoProdutividade float64   `json:"pontuacao_produtividade"`
	Status                 string    `json:"status"` // "excelente", "bom", "regular", "fraco"
}

// WeeklyStatsResponse representa as estatísticas de uma semana
type WeeklyStatsResponse struct {
	DataInicio             time.Time            `json:"data_inicio"`
	DataFim                time.Time            `json:"data_fim"`
	TotalTarefasPlanejadas int                  `json:"total_tarefas_planejadas"`
	TotalTarefasConcluidas int                  `json:"total_tarefas_concluidas"`
	MediaPontuacao         float64              `json:"media_pontuacao"`
	DiasMelhores           []DailyStatsResponse `json:"dias_melhores"`
	DiasPiores             []DailyStatsResponse `json:"dias_piores"`
}

// MonthlyStatsResponse representa as estatísticas de um mês
type MonthlyStatsResponse struct {
	Mes                    int                   `json:"mes"`
	Ano                    int                   `json:"ano"`
	TotalTarefasPlanejadas int                   `json:"total_tarefas_planejadas"`
	TotalTarefasConcluidas int                   `json:"total_tarefas_concluidas"`
	MediaPontuacao         float64               `json:"media_pontuacao"`
	DiasProdutivos         int                   `json:"dias_produtivos"`
	DiasTotais             int                   `json:"dias_totais"`
	Tendencia              string                `json:"tendencia"` // "melhorando", "estavel", "piorando"
	EstatisticasSemanais   []WeeklyStatsResponse `json:"estatisticas_semanais"`
}

// TrendsResponse representa as tendências de produtividade
type TrendsResponse struct {
	Periodo                string         `json:"periodo"` // "30_dias", "90_dias", "ano"
	MediaPontuacao         float64        `json:"media_pontuacao"`
	TaxaConclusaoMedia     float64        `json:"taxa_conclusao_media"`
	HorarioMaisProdutivo   string         `json:"horario_mais_produtivo"`
	DiaSemanaMailProdutivo string         `json:"dia_semana_mais_produtivo"`
	PrioridadeMaisComum    string         `json:"prioridade_mais_comum"`
	TempoMedioPorTarefa    int            `json:"tempo_medio_por_tarefa"`
	Grafico                []PontoGrafico `json:"grafico"`
}

// PontoGrafico representa um ponto no gráfico de tendências
type PontoGrafico struct {
	Data          time.Time `json:"data"`
	Pontuacao     float64   `json:"pontuacao"`
	TaxaConclusao float64   `json:"taxa_conclusao"`
}

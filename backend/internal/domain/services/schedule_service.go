package services

import (
	"fmt"
	"math"
	"sort"
	"time"

	"github.com/agataofrancisco/notario/internal/domain/models"
	"github.com/agataofrancisco/notario/internal/repository"
	"github.com/google/uuid"
)

// ScheduleService lida com a lógica de agendamento inteligente
type ScheduleService struct {
	taskRepo *repository.TaskRepository
}

// NewScheduleService cria uma nova instância do serviço
func NewScheduleService(taskRepo *repository.TaskRepository) *ScheduleService {
	return &ScheduleService{
		taskRepo: taskRepo,
	}
}

// ValidateDay valida se uma nova tarefa cabe num dia
func (s *ScheduleService) ValidateDay(userID uuid.UUID, req models.ValidateDayRequest) (*models.ValidateDayResponse, error) {
	// 1. Calcular tempo livre no dia
	tempoLivre, err := s.CalcularTempoLivre(userID, req.Data)
	if err != nil {
		return nil, err
	}

	// 2. Adicionar margem de segurança (10%)
	tempoNecessario := int(float64(req.DuracaoMinutos) * 1.1)

	// 3. Se cabe diretamente, retornar sucesso
	if tempoLivre >= tempoNecessario {
		return &models.ValidateDayResponse{
			Viavel:             true,
			TempoLivreMinutos:  tempoLivre,
			RequereConfirmacao: false,
			Mensagem:           "Tarefa agendada com sucesso!",
		}, nil
	}

	// 4. Tentar reagendar tarefas de menor prioridade
	proposta, err := s.ProporReagendamento(userID, req.Data, req.DuracaoMinutos, req.Prioridade)
	if err != nil {
		return nil, err
	}

	return proposta, nil
}

// CalcularTempoLivre calcula o tempo livre num dia (8h-22h = 14h)
func (s *ScheduleService) CalcularTempoLivre(userID uuid.UUID, data time.Time) (int, error) {
	// Buscar tarefas do dia
	tarefas, err := s.taskRepo.GetByUserAndDate(userID, data)
	if err != nil {
		return 0, err
	}

	// Calcular tempo ocupado
	totalOcupado := 0
	for _, tarefa := range tarefas {
		if tarefa.Estado != models.EstadoCancelada {
			totalOcupado += tarefa.DuracaoMinutos
		}
	}

	// Tempo disponível: 14h (8h-22h) - ocupado
	tempoDisponivel := (14 * 60) - totalOcupado

	return tempoDisponivel, nil
}

// ProporReagendamento propõe reagendamento de tarefas de menor prioridade
func (s *ScheduleService) ProporReagendamento(userID uuid.UUID, data time.Time, duracaoMinutos int, prioridade models.Prioridade) (*models.ValidateDayResponse, error) {
	// Buscar tarefas do dia
	tarefas, err := s.taskRepo.GetByUserAndDate(userID, data)
	if err != nil {
		return nil, err
	}

	// Ordenar por prioridade (baixa primeiro)
	sort.Slice(tarefas, func(i, j int) bool {
		return getPrioridadeValor(tarefas[i].Prioridade) < getPrioridadeValor(tarefas[j].Prioridade)
	})

	// Tentar mover tarefas até caber
	tarefasParaMover := []models.Task{}
	tempoLiberado := 0
	tempoNecessario := int(float64(duracaoMinutos) * 1.1)

	for _, tarefa := range tarefas {
		// Não mover tarefas de mesma ou maior prioridade
		if getPrioridadeValor(tarefa.Prioridade) >= getPrioridadeValor(prioridade) {
			break
		}

		tarefasParaMover = append(tarefasParaMover, tarefa)
		tempoLiberado += tarefa.DuracaoMinutos

		if tempoLiberado >= tempoNecessario {
			break
		}
	}

	// Se conseguiu espaço, sugerir próximos dias para tarefas movidas
	if tempoLiberado >= tempoNecessario {
		// TODO: Implementar sugestão de próximos dias
		return &models.ValidateDayResponse{
			Viavel:             true,
			TempoLivreMinutos:  tempoLiberado,
			RequereConfirmacao: true,
			TarefasParaMover:   tarefasParaMover,
			Mensagem:           fmt.Sprintf("Dia cheio. Podemos mover %d tarefa(s) de menor prioridade?", len(tarefasParaMover)),
		}, nil
	}

	// Não cabe, sugerir dias alternativos
	diasAlternativos, err := s.SugerirDiasAlternativos(userID, duracaoMinutos)
	if err != nil {
		return nil, err
	}

	return &models.ValidateDayResponse{
		Viavel:           false,
		DiasAlternativos: diasAlternativos,
		Mensagem:         "Este dia está completamente cheio. Sugerimos estas alternativas:",
	}, nil
}

// SugerirDiasAlternativos sugere próximos dias viáveis
func (s *ScheduleService) SugerirDiasAlternativos(userID uuid.UUID, duracaoMinutos int) ([]models.SugestaoDia, error) {
	sugestoes := []models.SugestaoDia{}
	hoje := time.Now()

	// Analisar próximos 14 dias
	for i := 1; i <= 14; i++ {
		proximaData := hoje.AddDate(0, 0, i)
		tempoLivre, err := s.CalcularTempoLivre(userID, proximaData)
		if err != nil {
			continue
		}

		tempoNecessario := int(float64(duracaoMinutos) * 1.1)
		if tempoLivre >= tempoNecessario {
			carga := s.CalcularCargaDoDia(tempoLivre)

			sugestoes = append(sugestoes, models.SugestaoDia{
				Data:              proximaData,
				TempoLivreMinutos: tempoLivre,
				Carga:             carga,
				Recomendado:       carga == "leve",
			})
		}

		// Retornar primeiras 5 opções
		if len(sugestoes) >= 5 {
			break
		}
	}

	return sugestoes, nil
}

// CalcularCargaDoDia calcula a carga de um dia baseado no tempo livre
func (s *ScheduleService) CalcularCargaDoDia(tempoLivreMinutos int) string {
	totalMinutos := 14 * 60 // 14h disponíveis
	percentualLivre := float64(tempoLivreMinutos) / float64(totalMinutos)

	if percentualLivre > 0.7 {
		return "leve"
	} else if percentualLivre > 0.4 {
		return "moderado"
	}
	return "cheio"
}

// CalcularTempoExtra calcula o tempo extra quando uma tarefa demora mais
func (s *ScheduleService) CalcularTempoExtra(taskID uuid.UUID, tempoRealMinutos int) (*models.CompleteTaskResponse, error) {
	// Buscar tarefa
	tarefa, err := s.taskRepo.GetByID(taskID)
	if err != nil {
		return nil, err
	}

	tempoExtra := tempoRealMinutos - tarefa.DuracaoMinutos

	// Se não há tempo extra, concluir normalmente
	if tempoExtra <= 0 {
		return &models.CompleteTaskResponse{
			TaskID:               taskID,
			TempoExtraMinutos:    0,
			RequereReagendamento: false,
			Mensagem:             "Tarefa concluída no tempo previsto!",
		}, nil
	}

	// Buscar tarefas do mesmo dia após esta
	tarefasPosteriores, err := s.buscarTarefasPosteriores(tarefa.UserID, tarefa.DataFim)
	if err != nil {
		return nil, err
	}

	// Se não há tarefas posteriores, não há problema
	if len(tarefasPosteriores) == 0 {
		return &models.CompleteTaskResponse{
			TaskID:               taskID,
			TempoExtraMinutos:    tempoExtra,
			RequereReagendamento: false,
			Mensagem:             fmt.Sprintf("Tarefa concluída com %d minutos extras.", tempoExtra),
		}, nil
	}

	// Há tarefas posteriores, precisa reagendar
	return &models.CompleteTaskResponse{
		TaskID:               taskID,
		TempoExtraMinutos:    tempoExtra,
		TarefasAfetadas:      tarefasPosteriores,
		RequereReagendamento: true,
		Mensagem:             fmt.Sprintf("Tarefa demorou %d minutos extras. %d tarefa(s) serão afetadas.", tempoExtra, len(tarefasPosteriores)),
	}, nil
}

// buscarTarefasPosteriores busca tarefas que vêm depois de uma data
func (s *ScheduleService) buscarTarefasPosteriores(userID uuid.UUID, dataReferencia time.Time) ([]models.Task, error) {
	// Buscar tarefas do mesmo dia
	tarefas, err := s.taskRepo.GetByUserAndDate(userID, dataReferencia)
	if err != nil {
		return nil, err
	}

	// Filtrar apenas as posteriores
	posteriores := []models.Task{}
	for _, tarefa := range tarefas {
		if tarefa.DataInicio.After(dataReferencia) && tarefa.Estado == models.EstadoPendente {
			posteriores = append(posteriores, tarefa)
		}
	}

	return posteriores, nil
}

// CalcularPontuacao calcula a pontuação de produtividade de um dia
func (s *ScheduleService) CalcularPontuacao(userID uuid.UUID, data time.Time) (float64, error) {
	tarefas, err := s.taskRepo.GetByUserAndDate(userID, data)
	if err != nil {
		return 0, err
	}

	if len(tarefas) == 0 {
		return 0, nil
	}

	// Contar tarefas por estado
	planejadas := len(tarefas)
	concluidas := 0
	tempoPlanejado := 0
	tempoReal := 0
	altasPlanejadas := 0
	altasConcluidas := 0

	for _, tarefa := range tarefas {
		tempoPlanejado += tarefa.DuracaoMinutos

		if tarefa.Prioridade == models.PrioridadeAlta {
			altasPlanejadas++
		}

		if tarefa.Estado == models.EstadoConcluida {
			concluidas++
			if tarefa.TempoRealMinutos != nil {
				tempoReal += *tarefa.TempoRealMinutos
			}
			if tarefa.Prioridade == models.PrioridadeAlta {
				altasConcluidas++
			}
		}
	}

	// Taxa de conclusão (0-40 pontos)
	taxaConclusao := (float64(concluidas) / float64(planejadas)) * 40

	// Precisão de tempo (0-30 pontos)
	precisaoTempo := 0.0
	if tempoPlanejado > 0 && tempoReal > 0 {
		ratio := float64(tempoReal) / float64(tempoPlanejado)
		if ratio >= 0.9 && ratio <= 1.1 {
			precisaoTempo = 30
		} else if ratio < 0.9 {
			precisaoTempo = (ratio / 0.9) * 30
		} else {
			precisaoTempo = math.Max(0, 30-((ratio-1.1)*30))
		}
	}

	// Prioridades altas (0-20 pontos)
	pontosPrioridade := 0.0
	if altasPlanejadas > 0 {
		pontosPrioridade = (float64(altasConcluidas) / float64(altasPlanejadas)) * 20
	}

	// Bônus de consistência (0-10 pontos) - TODO: Implementar
	bonus := 0.0

	pontuacao := taxaConclusao + precisaoTempo + pontosPrioridade + bonus

	return math.Min(pontuacao, 100), nil
}

// getPrioridadeValor converte prioridade em valor numérico
func getPrioridadeValor(p models.Prioridade) int {
	switch p {
	case models.PrioridadeBaixa:
		return 1
	case models.PrioridadeMedia:
		return 2
	case models.PrioridadeAlta:
		return 3
	default:
		return 0
	}
}

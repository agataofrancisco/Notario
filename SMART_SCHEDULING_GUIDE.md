# Guia do Sistema de Reagendamento Inteligente

## Visão Geral

O NOTÁRIO agora possui um sistema inteligente de reagendamento que ajuda a otimizar o agendamento de tarefas baseado em prioridades. Quando um dia está cheio, o sistema pode sugerir automaticamente mover tarefas de menor prioridade para liberar espaço.

## Funcionalidades Implementadas

### 1. Sistema de Reagendamento por Prioridade

#### Como Funciona
- Quando você tenta agendar uma tarefa e o dia está cheio, o sistema analisa as tarefas existentes
- Identifica tarefas de menor prioridade que podem ser movidas
- Sugere reagendamento automático para liberar espaço
- Encontra os melhores dias alternativos para as tarefas movidas

#### Critérios de Prioridade
- **Alta**: Tarefas urgentes e importantes
- **Média**: Tarefas importantes mas não urgentes  
- **Baixa**: Tarefas normais que podem ser reagendadas

#### Regras de Reagendamento
- Apenas tarefas marcadas como "Negociáveis" podem ser movidas
- Tarefas de prioridade menor podem ser movidas para dar lugar a tarefas de prioridade maior
- O sistema preserva o horário original ao mover para outro dia
- Considera dias úteis vs fins de semana ao sugerir reagendamento

### 2. Notificações Semanais Inteligentes

#### Resumo Semanal (Domingos às 20h)
- Mostra tarefas definidas vs concluídas na semana
- Calcula percentual de conclusão
- Fornece feedback motivacional baseado no desempenho:
  - 80%+ = "🎉 Excelente semana!"
  - 60-79% = "👍 Boa semana!"
  - 40-59% = "💪 Pode melhorar!"
  - <40% = "🎯 Foque na próxima semana!"

#### Lembrete de Planejamento (Domingos às 19h)
- Lembra de planejar a próxima semana
- Incentiva o hábito de organização semanal

#### Estatísticas Incluídas
- Número de tarefas definidas
- Número de tarefas concluídas
- Tarefas pendentes e puladas
- Tempo planeado vs tempo realizado
- Eficiência de tempo (%)

## Como Usar

### 1. Criando uma Tarefa com Reagendamento Inteligente

1. **Preencha o formulário** de nova tarefa normalmente
2. **Defina a prioridade** adequada (Alta/Média/Baixa)
3. **Marque como "Negociável"** se a tarefa pode ser reagendada
4. **Clique em "Criar Tarefa"** - o sistema validará automaticamente
5. **Se o dia estiver cheio**, aparecerá o diálogo de reagendamento:
   - Veja quais tarefas podem ser movidas
   - Revise o reagendamento sugerido
   - Clique em "Executar Reagendamento" para confirmar

### 2. Visualizando Estatísticas Semanais

1. **No Dashboard**, clique no ícone de estatísticas (📊) no canto superior direito
2. **Veja o resumo** da semana atual com todas as métricas
3. **Use as informações** para melhorar seu planejamento

### 3. Configurando Notificações

As notificações semanais são configuradas automaticamente quando você faz login. Para gerenciar:

- **Ativar/Desativar**: As notificações são gerenciadas pelo sistema automaticamente
- **Horários**: Domingos às 19h (planejamento) e 20h (resumo)
- **Permissões**: Certifique-se de que as notificações estão habilitadas no seu dispositivo

## Exemplos Práticos

### Exemplo 1: Reagendamento por Prioridade

**Situação**: Você quer agendar uma reunião importante (Prioridade Alta) para terça-feira, mas o dia já tem:
- Estudar Flutter (Prioridade Baixa, 2h)
- Exercício (Prioridade Média, 1h)
- Trabalho (Prioridade Alta, 6h)

**Resultado**: O sistema sugere mover "Estudar Flutter" para quarta-feira, liberando 2h para a reunião.

### Exemplo 2: Notificação Semanal

**Domingo às 20h**: 
> "Resumo Semanal 📊
> Definidas: 12 | Concluídas: 9 (75%)
> 👍 Boa semana!"

## Configurações Avançadas

### Parâmetros do Sistema

```dart
// Tempo útil por dia (16 horas)
const minutosUteisDia = 960;

// Margem de segurança para agendamento
const double scheduleSafetyMargin = 1.1;

// Horários de trabalho
const int workStartHour = 8;
const int workEndHour = 22;
```

### Personalização

- **Tarefas Negociáveis**: Marque/desmarque no formulário de criação
- **Margem de Segurança**: Configure para tarefas não-negociáveis
- **Prioridades**: Use consistentemente para melhor reagendamento

## Benefícios

1. **Otimização Automática**: Menos tempo pensando em reagendamentos
2. **Respeito às Prioridades**: Tarefas importantes sempre têm precedência
3. **Visibilidade Semanal**: Acompanhe seu progresso e melhore continuamente
4. **Motivação**: Feedback positivo baseado no desempenho
5. **Planejamento Proativo**: Lembretes para organizar a semana

## Troubleshooting

### Problema: Reagendamento não funciona
- Verifique se as tarefas estão marcadas como "Negociáveis"
- Confirme que há tarefas de menor prioridade no dia
- Certifique-se de que há dias alternativos disponíveis

### Problema: Notificações não chegam
- Verifique permissões de notificação no dispositivo
- Confirme que o usuário está logado
- Reinicie o app se necessário

### Problema: Estatísticas incorretas
- As estatísticas são calculadas por semana (segunda a domingo)
- Tarefas canceladas não contam para estatísticas
- Tempo realizado só conta para tarefas concluídas

## Próximas Melhorias

- [ ] Reagendamento em lote para múltiplas tarefas
- [ ] Sugestões de horários ótimos baseados em histórico
- [ ] Notificações personalizáveis por usuário
- [ ] Análise de produtividade mensal
- [ ] Integração com calendários externos para reagendamento
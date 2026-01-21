# Product Requirements Document (PRD) - Notário

## 1. Visão Geral do Produto

**Nome do Produto:** Notário (Notas + Calendário)
**Slogan/Meta:** "Motor de Disciplina para gestão de tempo e produtividade"
**Objetivo Principal:** Resolver problemas de esquecimento, acúmulo de tarefas e hiperfoco (envolvimento excessivo), garantindo que o usuário cumpra suas atividades diárias sem sobrecarga, com integração total ao Google Calendar.

## 2. Problemas a Resolver

1.  **Esquecimento:** O usuário esquece atividades, mensagens e compromissos se não forem lembrados ativamente.
2.  **Colecionamento de Tarefas:** Acúmulo de tarefas em diversas partes do dia sem execução.
3.  **Envolvimento Excessivo (Hiperfoco):** Perda de noção do tempo em uma única atividade, prejudicando o restante do dia.
4.  **Desconexão entre Ferramentas:** Uso de bloco de notas para tarefas e calendário para reuniões, causando falhas de sincronia.

## 3. Solução Proposta

Um aplicativo que unifica notas e calendário, atuando como um "gerente" pessoal.

- **Integração Bidirecional:** Tudo que é criado no Notário vai para o Google Calendar e vice-versa.
- **Controle de Sobrecarga:** O sistema impede agendamentos se não houver tempo hábil ("Time Live"), sugerindo dias alternativos.
- **Priorização Dinâmica:** Tarefas de baixa prioridade são reagendadas automaticamente em caso de atrasos.
- **Acompanhamento em Tempo Real:** Monitoramento da execução com timer e feedback constante.

## 4. Funcionalidades Principais (Core)

### 4.1. Gestão de Atividades (Tasks)

- **Tipos de Atividade:**
  - **Inegociáveis:** Atividades fixas do dia (ex: trabalho, treino).
  - **Padrão:** Tarefas adicionais com tempo estimado.
- **Criação:**
  - Inputs: Título, Descrição, Prioridade (Baixa, Média, Alta), Data/Hora, Tempo Estimado, Avisos (antes e depois).
  - **Segurança de Tempo:** O app adiciona automaticamente uma "margem de segurança" (fração do tempo) ao tempo estimado pelo usuário.
- **Validação de Disponibilidade (Sobrecarga):**
  - Ao tentar adicionar, o app verifica o calendário.
  - Se não houver espaço, _bloqueia_ e sugere o próximo dia/horário viável.

### 4.2. Gestão de Notas

- **Conceito:** "Lembrar de algo em um momento específico".
- **Criação:**
  - Inputs: Título, Descrição, Data/Hora do lembrete.
- **Integração:** Aparecem no calendário como eventos/lembretes pontuais.

### 4.3. Fluxo de Execução & Notificações

- **Pré-Atividade:**
  - Notificação Local X minutos antes (configurável).
  - Prompt ao abrir o app: "Pronto para iniciar?" ou "Skipar/Pular?".
- **Fluxo "Skipar":**
  - Se o usuário pular, o app recalcula o dia.
  - Tenta encaixar outra atividade possível.
  - Mostra o impacto do "pulo" no sucesso do dia (dissuasão).
  - Último recurso: Reagendar.
- **Fluxo "Realizar" (Execution Mode):**
  - **UI:** Ampulheta com animação de areia caindo (representação visual do tempo).
  - Avisos de "Tempo acabando" e "Término" via notificações locais.
  - **Pós-Termino:**
    - Se não terminou: Consome tempo livre (Time Live) ou "come" tempo de atividade de menor prioridade.
    - Se terminou: Registra sucesso.

* **Encerramento do Dia:**
  - Resumo do dia.
  - Classificação do dia (Sucesso/Fracasso) baseado na % de execução.
  - Feedback motivacional ("Parabéns, você merece").

### 4.4. Dashboard & UI

- **Tela Inicial (Dashboard):**
  - Estado atual (Adiantado/Atrasado/No Prazo).
  - Calendário Visual:
    - 🔴 Vermelho: Dia Cheio.
    - 🔵 Azul: Espaço Disponível.
    - 🟢 Verde: Dia Livre.
  - Botão "Quick Add" (+).
- **Listas:**
  - Lista de Atividades (com edição).
  - Lista de Notas.
- **Histórico:** Estatísticas de produtividade e dias "vitoriosos".

## 5. Requisitos Não Funcionais

- **Integração:**
  - **Fase Atual:** Local-First (Notificações Locais). Integração Google Calendar em espera de verificação.
- **Plataformas:** Mobile (Flutter) - Android (Prioridade) / iOS.
- **Design:**
  - Aesthetics: Premium, Vibrante, Glassmorphism, Dark Mode.
  - **Assets:** Logo `notariologo.png` na Splash Screen e Ícone.
  - UX: "Wow factor", animações fluidas (ex: ampulheta), responsividade imediata.
- **Offline-First:** Deve funcionar 100% offline, com notificações locais substituindo o Google Calendar temporariamente.

## 6. Arquitetura de Dados (Entidades)

- **Activity/Task:** id, title, description, startTime, duration, safetyMargin, priority (Low, Med, High), status (Pending, InProgress, Done, Skipped), googleEventId.
- **Note:** id, title, content, reminderTime, googleEventId.
- **DayStats:** date, successRate, status (Excellent, Good, Bad).

## 7. Roadmap de Implementação Sugerido

1.  **Fundação:** Configuração do Projeto, Temas, Navegação.
2.  **Core Services:** Google Auth, Calendar Service, Local Database (Drift/Hive/Sqflite).
3.  **Feature: Atividades:** CRUD, Lógica de "Sobrecarga" (algoritmo de alocação de tempo).
4.  **Feature: Execução:** Timer, Notificações Locais, Lógica de "Skip".
5.  **Feature: Notas:** CRUD simples integrado ao calendário.
6.  **Dashboard & Polimento:** UI Premium, Gráficos, Animações.

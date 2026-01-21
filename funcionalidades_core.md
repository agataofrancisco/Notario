# NOTÁRIO - Funcionalidades Core

## 🎯 Visão Geral

**NOTÁRIO** = Motor de Disciplina para gestão de tempo e produtividade

**Conceito:** App que combina tarefas + calendário com agendamento inteligente e execução disciplinada

---

## ⚡ Funcionalidades CORE (MVP)

### 1. 📝 Gestão de Tarefas

**O que faz:**
- Criar tarefas com título, descrição, duração estimada
- Definir prioridade (baixa, média, alta)
- Agendar data e hora de início
- Editar e deletar tarefas
- Marcar como concluída/pulada/cancelada

**Telas:**
- ✅ Lista de tarefas (por dia)
- ✅ Formulário criar/editar tarefa
- ✅ Detalhes da tarefa

**Status:** 🟡 Parcialmente implementado (falta UI)

---

### 2. 🧠 Agendamento Inteligente

**O que faz:**
- Valida se há tempo livre no dia escolhido
- Sugere dias alternativos se não houver espaço
- Considera prioridades ao sugerir movimentações
- Evita conflitos de horários

**Como funciona:**
1. Usuário tenta agendar tarefa para um dia
2. Sistema verifica tempo disponível (24h - tarefas existentes)
3. Se não couber, sugere:
   - Mover tarefas de baixa prioridade
   - Dias alternativos com espaço
4. Usuário decide e confirma

**Status:** ✅ Backend implementado, 🟡 UI falta

---

### 3. ⏱️ Modo de Execução

**O que faz:**
- Temporizador para executar tarefas
- Notificações de início/fim
- Registro de tempo real gasto
- Opções: concluir, pular, cancelar

**Fluxo:**
1. Usuário clica "Iniciar" na tarefa
2. Abre tela de execução com temporizador
3. Temporizador conta o tempo
4. Ao terminar:
   - **Concluir:** Registra tempo real, marca como concluída
   - **Pular:** Marca como pulada, não conta para estatísticas
   - **Cancelar:** Volta ao estado pendente

**Status:** ❌ Não implementado

---

### 4. 📅 Sincronização Google Calendar

**O que faz:**
- Sincroniza tarefas com Google Calendar
- Cria eventos automaticamente
- Atualização bidirecional (app ↔ calendar)
- Lê eventos existentes para validação

**Benefícios:**
- Visualizar tarefas no calendário do Google
- Receber notificações do Google
- Integração com outros apps

**Status:** ❌ Não implementado (PRIORIDADE ALTA)

---

### 5. 🔔 Notificações

**O que faz:**
- Lembrete antes da tarefa começar (15 min antes)
- Notificação quando tarefa deve iniciar
- Notificação quando tempo acabar
- Ações rápidas (iniciar, pular)

**Status:** ❌ Não implementado

---

## 🎨 Funcionalidades EXTRAS (Pós-MVP)

### 6. 📓 Notas

**O que faz:**
- Criar notas rápidas
- Anexar notas a tarefas
- Lembretes em notas
- Busca em notas

**Status:** ❌ Não implementado

---

### 7. 📊 Estatísticas

**O que faz:**
- Pontuação de produtividade
- Sequência de dias produtivos
- Gráficos de tarefas concluídas
- Histórico de tempo gasto
- Tendências semanais/mensais

**Métricas:**
- Taxa de conclusão
- Tempo médio por tarefa
- Prioridades mais executadas
- Dias mais produtivos

**Status:** ❌ Não implementado

---

## 🏗️ Arquitetura Atual

### ✅ Implementado

**Backend (Firebase):**
- ✅ Firebase Authentication (Email/Password + Google OAuth)
- ✅ Firestore para tarefas (tempo real)
- ✅ Estrutura de dados definida

**Mobile:**
- ✅ Login/Registro com email/senha
- ✅ Google Sign-In (opcional)
- ✅ Dashboard básico
- ✅ AuthBloc completo
- ✅ TaskBloc estruturado
- ✅ Tema Material Design 3

### 🟡 Parcialmente Implementado

- 🟡 TaskBloc (eventos definidos, handlers faltam UI)
- 🟡 Dashboard (estrutura pronta, falta dados reais)

### ❌ Não Implementado

- ❌ Telas de tarefas (criar, editar, listar)
- ❌ Modo de execução
- ❌ Google Calendar integration
- ❌ Notificações
- ❌ Notas
- ❌ Estatísticas

---

## 🎯 Roadmap MVP (Próximos Passos)

### Fase 1: Gestão de Tarefas (1 semana)
1. ✅ Criar `TaskFormScreen` (criar/editar)
2. ✅ Criar `TaskListScreen` (lista por dia)
3. ✅ Implementar validação de dia com feedback visual
4. ✅ Testar CRUD completo

### Fase 2: Execução (1 semana)
1. ✅ Criar `ExecutionScreen` com temporizador
2. ✅ Implementar lógica de início/pausa/conclusão
3. ✅ Adicionar notificações locais
4. ✅ Testar fluxo completo

### Fase 3: Google Calendar (1 semana)
1. ✅ Configurar Google Calendar API
2. ✅ Implementar sincronização de eventos
3. ✅ Testar criação/atualização/deleção
4. ✅ Implementar leitura de eventos para validação

### Fase 4: Polimento (3-5 dias)
1. ✅ Melhorar UI/UX
2. ✅ Adicionar animações
3. ✅ Testes de integração
4. ✅ Correção de bugs

**Total:** ~3-4 semanas para MVP completo

---

## 🔑 Diferenciais do NOTÁRIO

1. **Agendamento Inteligente**
   - Não deixa agendar se não houver tempo
   - Sugere alternativas automaticamente

2. **Modo de Execução Disciplinado**
   - Temporizador obriga foco
   - Registro preciso de tempo real

3. **Sincronização Google Calendar**
   - Melhor integração com ecossistema
   - Notificações nativas do Google

4. **Offline-First**
   - Funciona sem internet
   - Sincroniza quando voltar online

5. **Estatísticas Motivadoras**
   - Gamificação com pontuação
   - Sequências de dias produtivos

---

## 📱 Fluxo de Uso Típico

### Manhã
1. Abrir app
2. Ver tarefas do dia no dashboard
3. Clicar "Iniciar" na primeira tarefa
4. Executar com temporizador
5. Concluir e passar para próxima

### Durante o Dia
1. Criar nova tarefa urgente
2. Sistema valida se cabe no dia
3. Se não couber, sugere mover outras ou escolher outro dia
4. Usuário decide e confirma

### Noite
1. Ver estatísticas do dia
2. Verificar pontuação
3. Planejar tarefas do dia seguinte

---

## 🎨 Identidade Visual

**Cores:**
- Primary: Roxo/Azul (#667eea)
- Secondary: Roxo escuro (#764ba2)
- Accent: Verde para sucesso, Vermelho para urgente

**Estilo:**
- Material Design 3
- Gradientes suaves
- Cards com elevação
- Animações fluidas

**Ícone:**
- 📅 Calendário (representa organização)
- ⚡ Raio (representa disciplina/energia)

---

## 💡 Ideias Futuras (Pós-MVP)

- 🤖 IA para sugerir melhor horário baseado em histórico
- 👥 Compartilhamento de tarefas em equipe
- 🎯 Metas semanais/mensais
- 🏆 Conquistas e badges
- 📱 Widget para home screen
- ⌚ App para smartwatch
- 🌐 Versão web

---

## ✅ Status Atual: 40% Completo

**Pronto:**
- ✅ Autenticação
- ✅ Estrutura base
- ✅ Firebase configurado

**Próximo:**
- 🎯 Telas de tarefas
- 🎯 Modo de execução
- 🎯 Google Calendar

**Tempo para MVP:** 3-4 semanas

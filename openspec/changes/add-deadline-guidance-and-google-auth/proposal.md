# Proposal

## Why

O Notário permite programar tarefas, mas não distingue o momento reservado para a executar da data-limite real. Isso impede o produto de orientar o utilizador quando termina o plano do dia e ainda há trabalho importante que se aproxima da respetiva deadline. Além disso, o login Google e o acesso ao Calendar não partilham uma sessão autenticada, pelo que a principal experiência de entrada e integração com calendário não está concluída.

## What Changes

- Adicionar uma deadline opcional a cada tarefa, independente da data/hora planeada, com validação clara para prazos impossíveis.
- Criar um motor local, determinístico e explicável de recomendações de foco. Quando o utilizador conclui o trabalho planeado para hoje, o motor poderá sugerir tarefas pendentes com maior urgência, prioridade e viabilidade dentro do tempo livre; nunca move nem inicia tarefas sem confirmação.
- Mostrar as recomendações e a pressão de deadline na experiência diária, com ações para começar, agendar ou dispensar uma sugestão.
- Tornar o Google Sign-In o percurso de autenticação real via Firebase Auth e reutilizar a conta/sessão autorizada para acesso explícito ao Google Calendar, incluindo estados de autorização, erro, cancelamento e desligamento.
- Executar uma auditoria UI/UX de todos os ecrãs, diálogos e estados de carregamento/erro/vazio em formatos móveis, com correções de usabilidade e acessibilidade encontradas durante a implementação.
- Não introduzir modelo de IA nem serviço pago: as recomendações da primeira versão usam regras locais transparentes e dados já existentes no dispositivo/Firestore.

## Capabilities

### New Capabilities

- `task-deadline-guidance`: deadlines de tarefa e recomendações explicáveis de trabalho prioritário no tempo livre.
- `google-auth-calendar-access`: autenticação Google através de Firebase e concessão/revogação consistente de acesso ao Google Calendar.
- `task-flow-usability`: requisitos de UX, acessibilidade e cobertura de estados para os fluxos de autenticação, criação, gestão e execução de tarefas.

### Modified Capabilities

- Nenhuma; o repositório ainda não possui especificações OpenSpec de capacidades existentes.

## Impact

- Modelo `Task`, serialização Firestore/SQLite, consultas e regras/índices Firestore quando necessários.
- Camadas de tarefa (repositório, BLoC, formulários, lista/dashboard e execução), incluindo testes unitários e de widget.
- `AuthService`, `GoogleCalendarService`, Auth BLoC e ecrã de login; configurações OAuth/Firebase para Android, iOS e web.
- Dependências e documentação de configuração Google/Firebase; a Calendar API e o fornecedor Google terão de estar ativos no projeto Google/Firebase do utilizador.

# 📱 NOTÁRIO - Gestor Inteligente de Tarefas

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 🎯 Sobre o Projeto

**NOTÁRIO** é um aplicativo móvel inteligente de gestão de tarefas e tempo, desenvolvido em Flutter. O app ajuda você a organizar seu dia, evitar sobrecarga e manter o foco com um sistema de execução baseado em timer (Modo Foco).

### ✨ Principais Funcionalidades

- **📋 Gestão de Tarefas**: Crie, edite e organize tarefas com prioridades
- **⏱️ Modo Foco**: Timer com animação de ampulheta para execução de tarefas
- **🚫 Controle de Sobrecarga**: Validação automática de viabilidade do dia
- **📝 Notas com Lembretes**: Sistema completo de notas com notificações
- **📊 Dashboard Analítico**: Estatísticas visuais e calendário de calor
- **🔔 Notificações Locais**: Lembretes inteligentes para tarefas e notas
- **💾 Offline-First**: Funciona sem internet com sincronização posterior
- **🎨 UI/UX Premium**: Design moderno com animações suaves

## 🏗️ Arquitetura

O projeto segue os princípios de **Clean Architecture** e **BLoC Pattern**:

```
lib/
├── core/                    # Núcleo da aplicação
│   ├── database/           # SQLite (DatabaseHelper)
│   ├── services/           # Serviços (Auth, Notifications, Statistics)
│   └── repositories/       # Repositórios Firestore (legacy)
├── features/               # Funcionalidades por domínio
│   ├── auth/              # Autenticação
│   ├── tasks/             # Tarefas
│   │   ├── domain/        # Entidades e lógica de negócio
│   │   ├── data/          # Repositórios e fontes de dados
│   │   └── presentation/  # UI (Screens, Widgets, BLoCs)
│   ├── notes/             # Notas
│   └── dashboard/         # Dashboard e Estatísticas
└── shared/                # Componentes compartilhados
    └── theme/             # Tema da aplicação
```

## 🚀 Como Executar

### Pré-requisitos

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Emulador Android/iOS ou dispositivo físico

### Instalação

1. **Clone o repositório**

```bash
git clone <repository-url>
cd Notario
```

2. **Instale as dependências**

```bash
flutter pub get
```

3. **Configure o Firebase** (opcional, para sincronização)

- Adicione `google-services.json` em `android/app/`
- Adicione `GoogleService-Info.plist` em `ios/Runner/`

4. **Execute o app**

```bash
flutter run
```

## 📦 Dependências Principais

```yaml
dependencies:
  flutter_bloc: ^8.1.3          # Gerenciamento de estado
  equatable: ^2.0.5             # Comparação de objetos
  sqflite: ^2.3.0               # Banco de dados local
  intl: ^0.18.1                 # Internacionalização
  google_fonts: ^6.1.0          # Fontes do Google
  flutter_local_notifications   # Notificações locais
  firebase_core                 # Firebase Core
  firebase_auth                 # Autenticação Firebase
  cloud_firestore               # Firestore Database
  uuid: ^4.0.0                  # Geração de IDs únicos
```

## 🎨 Temas e Cores

O app possui suporte para **modo claro e escuro** com as seguintes cores principais:

- **Primary**: `#FF7A5C` (Coral)
- **Secondary**: `#FF9A62` (Laranja Claro)
- **Accent**: `#2B5BC7` (Azul)
- **Success**: `#2ECC71` (Verde)
- **Warning**: `#FF9800` (Laranja)
- **Error**: `#E53935` (Vermelho)

## 📊 Funcionalidades Detalhadas

### 1. Gestão de Tarefas

- **Criação**: Título, descrição, data/hora, duração, prioridade
- **Validação**: Verifica se o dia tem capacidade para a tarefa
- **Estados**: Pendente, Em Execução, Concluída, Pulada, Cancelada
- **Prioridades**: Alta, Média, Baixa

### 2. Modo Foco (Execution Mode)

- Timer visual com animação de ampulheta
- Controles: Pausar, Retomar, Finalizar
- Ações: Pular, Cancelar, Reagendar
- Notificações de tempo esgotado
- Tracking de tempo real vs. planejado

### 3. Notas com Lembretes

- Criação de notas com título e conteúdo
- Lembretes opcionais com data/hora
- Notificações automáticas
- Busca por texto
- Indicadores visuais de status

### 4. Dashboard & Analytics

- **Calendário de Calor**: Visualização semanal com cores
  - 🟢 Verde: Dia livre
  - 🔵 Azul: Espaço disponível
  - 🔴 Vermelho: Dia cheio
- **Estatísticas**:
  - Taxa de conclusão
  - Sequência de dias (streak)
  - Horas planejadas vs. reais
  - Breakdown semanal
- **Conquistas**: Melhor sequência, sequência atual

## 🔔 Sistema de Notificações

### Tipos de Notificações

1. **Lembrete de Tarefa**: 15 min antes do início
2. **Aviso de Timer**: 5 min antes do fim
3. **Fim de Timer**: Quando o tempo acaba
4. **Lembrete de Nota**: No horário configurado

### Configuração

As notificações são gerenciadas pelo `NotificationService` e usam:

- `flutter_local_notifications` para notificações locais
- Canais separados para cada tipo
- Suporte a `fullScreenIntent` no Android

## 💾 Banco de Dados

### Estrutura SQLite

**Tabelas principais:**

- `users`: Dados do usuário
- `tasks`: Tarefas com todos os campos
- `notes`: Notas com lembretes
- `statistics`: Estatísticas diárias
- `sync_queue`: Fila de sincronização

### Sincronização

O app usa uma estratégia **offline-first**:

1. Todas as operações são salvas localmente primeiro
2. Tarefas são marcadas com `sync_status: pending`
3. Sincronização com Firestore acontece em background
4. Conflitos são resolvidos por timestamp (`atualizado_em`)

## 🧪 Testes

```bash
# Testes unitários
flutter test

# Testes de integração
flutter test integration_test/

# Análise de código
flutter analyze
```

## 📱 Build para Produção

### Android

```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 🔐 Segurança

- Autenticação via Firebase Auth
- Dados locais criptografados (SQLite)
- Regras de segurança do Firestore configuradas
- Validação de entrada em todos os formulários

## 🌍 Internacionalização

O app está configurado para **Português (PT-PT)** mas pode ser facilmente expandido:

```dart
MaterialApp(
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: [
    const Locale('pt', 'PT'),
  ],
)
```

## 📝 Roadmap Futuro

- [ ] Integração completa com Google Calendar
- [ ] Sincronização em tempo real
- [ ] Widgets para tela inicial
- [ ] Compartilhamento de tarefas
- [ ] Temas personalizáveis
- [ ] Backup e restauração
- [ ] Modo escuro automático
- [ ] Suporte a tablets

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👥 Autores

- **Agata Francisco** - _Desenvolvimento Inicial_

## 🙏 Agradecimentos

- Flutter Team pela excelente framework
- Comunidade Flutter pelos packages incríveis
- Google Fonts pela tipografia
- Todos os contribuidores

---

**Desenvolvido com ❤️ usando Flutter**

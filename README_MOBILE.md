# NOTÁRIO - Mobile

Aplicação mobile Flutter para o sistema NOTÁRIO - Motor de disciplina para gestão de tempo.

## 🚀 Tecnologias

- **Flutter 3.0+**
- **Dart 3.0+**
- **Firebase** (Backend as a Service)
  - **Firebase Authentication** (para login com Google)
  - **Cloud Firestore** (base de dados NoSQL em tempo real)
  - **Firebase Cloud Messaging** (para notificações e lembretes)
- **BLoC** (gestão de estado)
- **Google Calendar API**
- **Google Sign-In**
- **Table Calendar** (para visualização de eventos)
- **Intl** (para formatação de datas)

## 📁 Estrutura do Projeto

O projeto segue uma arquitetura limpa, orientada a funcionalidades e escalável.

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   ├── di/
│   │   └── services/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── bloc/
│   │   │   ├── models/
│   │   │   ├── presentation/
│   │   │   └── repository/
│   │   ├── calendar/
│   │   └── notes/
│   └── shared/
│       ├── models/
│       ├── widgets/
│       └── utils/
└── ...
```

## ✨ Funcionalidades Planeadas

- [X] **Autenticação Segura com Google:** Login rápido e seguro usando a conta Google do utilizador.
- [ ] **Sincronização com Google Calendar:** Visualização e gestão de eventos diretamente no app.
- [ ] **Gestão de Notas e Tarefas:** Crie, edite e organize notas e tarefas de forma intuitiva.
- [ ] **Agendamento Inteligente:** Programe eventos e defina prioridades.
- [ ] **Lembretes e Notificações:** Receba lembretes para não perder nenhum compromisso importante.
- [ ] **Modo Offline:** Acesso e gestão de dados mesmo sem conexão à internet.

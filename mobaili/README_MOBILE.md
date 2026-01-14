# NOTÁRIO Mobile

Aplicação mobile Flutter para o sistema NOTÁRIO - Motor de disciplina para gestão de tempo.

## 🚀 Tecnologias

- **Flutter 3.0+**
- **Dart 3.0+**
- **SQLite** (base de dados local)
- **BLoC** (gestão de estado)
- **Google Sign-In**
- **Google Calendar API**
- **Flutter Local Notifications**

## 📁 Estrutura do Projeto

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   ├── database/
│   │   ├── di/
│   │   ├── network/
│   │   └── services/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── tasks/
│   │   ├── notes/
│   │   ├── execution/
│   │   └── statistics/
│   └── shared/
│       ├── widgets/
│       ├── theme/
│       └── constants/
├── pubspec.yaml
└── android/ios/
```

## ⚙️ Configuração

1. **Instalar dependências:**

```bash
flutter pub get
```

2. **Configurar Google Sign-In:**

- Adicionar `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
- Configurar OAuth 2.0 no Google Cloud Console

3. **Gerar código:**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🏃 Executar

```bash
# Debug
flutter run

# Release
flutter run --release
```

## 📝 Próximos Passos

- [ ] Implementar autenticação Google
- [ ] Implementar CRUD de tarefas
- [ ] Implementar sincronização offline
- [ ] Implementar notificações locais
- [ ] Implementar dashboard
- [ ] Implementar modo de execução
- [ ] Implementar estatísticas

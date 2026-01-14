# NOTÁRIO

Sistema de gestão de tempo inteligente para pessoas que se esquecem, se sobrecarregam e entram em transe de foco.

**NOTÁRIO = Notas + Calendário**

---

## 📁 Estrutura do Projeto

```
Notario/
├── backend/          # Backend em Go
│   ├── cmd/
│   ├── internal/
│   ├── pkg/
│   └── go.mod
│
└── mobaili/          # App mobile Flutter
    ├── lib/
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

---

## 🚀 Tecnologias

### Backend

- **Go 1.21+**
- **PostgreSQL 14+**
- **Gin** (framework web)
- **Google Calendar API**
- **Google OAuth 2.0**

### Mobile

- **Flutter 3.0+**
- **Dart 3.0+**
- **SQLite** (base de dados local)
- **BLoC** (gestão de estado)
- **Google Sign-In**
- **Google Calendar API**

---

## ⚙️ Como Começar

### Backend

```bash
cd backend

# Instalar dependências
go mod download

# Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas credenciais

# Criar base de dados
createdb notario_db

# Executar servidor
go run cmd/server/main.go
```

### Mobile

```bash
cd mobaili

# Instalar dependências
flutter pub get

# Executar app
flutter run
```

---

## 📖 Documentação

Consulte os documentos técnicos em `.gemini/antigravity/brain/`:

- **implementation_plan.md** - Arquitetura completa
- **decisoes_tecnicas.md** - Justificações técnicas
- **walkthrough.md** - Progresso de implementação
- **task.md** - Roadmap de desenvolvimento

---

## 🎯 Funcionalidades Principais

- ✅ **Integração Google Calendar** - Tudo sincronizado
- ✅ **Agendamento Inteligente** - Valida sobrecarga
- ✅ **Sistema de Prioridades** - Protege tarefas importantes
- ✅ **Modo de Execução** - Timer e controlo de tempo
- ✅ **Sincronização Offline** - Funciona sem internet
- ✅ **Estatísticas** - Pontuação de produtividade

---

## 📝 Estado Atual

**Backend (50%):**

- ✅ Modelos de domínio
- ✅ Repositórios
- ✅ Algoritmo de agendamento
- ⏳ APIs REST
- ⏳ Google Calendar API

**Mobile (30%):**

- ✅ Estrutura base
- ✅ Modelos
- ✅ Tema
- ⏳ UI
- ⏳ BLoCs
- ⏳ Sincronização

---

## 👥 Equipa

Desenvolvido como um **motor de disciplina**, não uma lista passiva de tarefas.

---

## 📄 Licença

Projeto privado.

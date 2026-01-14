# NOTÁRIO Backend

Backend em Go para o sistema NOTÁRIO - Motor de disciplina para gestão de tempo.

## 🚀 Tecnologias

- **Go 1.21+**
- **PostgreSQL 14+**
- **Gin** (framework web)
- **Google Calendar API**
- **Google OAuth 2.0**

## 📁 Estrutura do Projeto

```
backend/
├── cmd/
│   └── server/          # Ponto de entrada
├── internal/
│   ├── api/             # Handlers e rotas
│   ├── domain/          # Modelos e lógica de negócio
│   ├── repository/      # Acesso a dados
│   └── config/          # Configurações
├── pkg/
│   ├── database/        # Conexão PostgreSQL
│   └── utils/           # Utilitários
├── go.mod
└── .env.example
```

## ⚙️ Configuração

1. **Copiar ficheiro de ambiente:**

```bash
cp .env.example .env
```

2. **Configurar variáveis de ambiente:**

- `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET`: Obter em [Google Cloud Console](https://console.cloud.google.com/)
- `JWT_SECRET`: Gerar chave secreta forte
- `DB_PASSWORD`: Senha do PostgreSQL

3. **Criar base de dados PostgreSQL:**

```bash
createdb notario_db
```

## 🏃 Executar

```bash
# Instalar dependências
go mod download

# Executar servidor
go run cmd/server/main.go
```

## 📝 Próximos Passos

- [ ] Implementar autenticação Google OAuth
- [ ] Implementar CRUD de tarefas
- [ ] Implementar algoritmo de agendamento
- [ ] Integrar Google Calendar API
- [ ] Implementar sincronização offline

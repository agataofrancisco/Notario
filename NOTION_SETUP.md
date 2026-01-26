# Configuração do Notion - Guia Rápido

## Passos para Configurar a Integração

### 1. Criar Integração no Notion

1. Acesse: https://www.notion.so/my-integrations
2. Clique em **"+ New integration"**
3. Preencha:
   - **Name**: Notário App
   - **Associated workspace**: Escolha seu workspace
   - **Type**: Internal
4. Clique em **Submit**
5. **COPIE O TOKEN** que aparece (começa com `ntn_...`) - você já forneceu este token ✓

### 2. Criar Bancos de Dados no Notion

#### Banco de Dados: Tarefas Notário

1. No Notion, crie uma nova página
2. Digite `/database` e escolha **"Table - Full page"**
3. Nomeie como **"Tarefas Notário"**
4. Adicione as seguintes propriedades (colunas):
   - **Name** (Title) - já existe por padrão
   - **Status** (Checkbox)
   - **Description** (Text)
   - **Start Date** (Date)
   - **Duration (mins)** (Number)
   - **Priority** (Select) - adicione opções: `baixa`, `media`, `alta`

#### Banco de Dados: Notas Notário

1. Crie outra página com `/database`
2. Nomeie como **"Notas Notário"**
3. Adicione as propriedades:
   - **Name** (Title) - já existe
   - **Content** (Text)
   - **Date** (Date)

### 3. Compartilhar Bancos de Dados com a Integração

Para CADA banco de dados criado:

1. Clique nos **"..."** (três pontos) no canto superior direito
2. Vá em **"Connections"** ou **"Add connections"**
3. Procure e selecione **"Notário App"** (a integração que você criou)

### 4. Obter os Database IDs

Para cada banco de dados:

1. Abra o banco de dados em página completa
2. Olhe para a URL no navegador, ela será algo como:
   ```
   https://www.notion.so/SEU_WORKSPACE/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX?v=...
   ```
3. O **Database ID** é a parte `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` (32 caracteres)

### 5. Configurar no App

Abra o arquivo `lib/core/config/app_config.dart` e preencha:

```dart
// TODO: Usuário deve preencher estes IDs
static const String notionTaskDatabaseId = 'COLE_AQUI_O_ID_DO_BANCO_DE_TAREFAS';
static const String notionNoteDatabaseId = 'COLE_AQUI_O_ID_DO_BANCO_DE_NOTAS';
```

## Verificação

Após configurar:

1. Compile e execute o app
2. Crie uma tarefa ou nota
3. Verifique se aparece no Notion
4. No Notion Calendar, conecte o banco de dados "Tarefas Notário" para visualizar no calendário

## Troubleshooting

**Erro de autenticação**: Verifique se o token está correto e se a integração tem acesso aos bancos de dados.

**Propriedades não aparecem**: Certifique-se de que os nomes das propriedades correspondem EXATAMENTE aos nomes no código (case-sensitive).

**Nada aparece no Notion**: Verifique os logs do app (modo debug) para ver mensagens de erro da API do Notion.

# Notion Integration Setup

A integração com Notion está **desabilitada** até que seja configurada corretamente.

## Problemas Identificados

1. **Database ID inválido**: O valor `'notariodb'` não é um ID válido do Notion
2. **Token de API**: Precisa ser verificado se ainda é válido

## Como Configurar

### 1. Obter o Database ID

1. Abra o seu database no Notion
2. Clique em "Share" → "Copy link"
3. O link terá este formato: `https://www.notion.so/workspace/DATABASE_ID?v=...`
4. Copie o `DATABASE_ID` (32 caracteres hexadecimais)

### 2. Atualizar a Configuração

Edite o arquivo `lib/core/config/app_config.dart`:

```dart
// Substituir 'notariodb' pelos IDs reais
static const String notionTaskDatabaseId = 'SEU_DATABASE_ID_AQUI';
static const String notionNoteDatabaseId = 'SEU_DATABASE_ID_AQUI';
```

### 3. Verificar o Token

O token atual começa com `ntn_562462600888...`. Verifique se:

- Ainda está válido
- Tem permissões para criar páginas nos databases
- Foi criado na integração correta

### 4. Estrutura do Database

O database do Notion deve ter as seguintes propriedades:

**Para Tasks:**

- `Name` (Title)
- `Status` (Checkbox)
- `Description` (Rich Text) - opcional
- `Start Date` (Date)
- `Duration (mins)` (Number)
- `Priority` (Select) - com opções: "Baixa", "Média", "Alta"

**Para Notes:**

- `Name` (Title)
- `Content` (Rich Text)
- `Date` (Date)

## Status Atual

A integração está **silenciosamente desabilitada**. Quando o Database ID for inválido, o serviço simplesmente retorna `null` sem causar erros na aplicação.

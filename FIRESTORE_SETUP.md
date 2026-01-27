# 🚨 CONFIGURAÇÃO URGENTE - Firestore Database

## Erro Atual

```
Status{code=NOT_FOUND, description=The database (default) does not exist for project notario-6961f
Please visit https://console.cloud.google.com/datastore/setup?project=notario-6961f
```

**O que significa:** O banco de dados Firestore não foi criado no projeto Firebase.

---

## Solução: Criar Firestore Database

### Passo 1: Acessar Firebase Console

1. Abra: https://console.firebase.google.com/
2. Selecione o projeto **"notario-6961f"**

### Passo 2: Criar Firestore Database

1. No menu lateral, clique em **"Firestore Database"** ou **"Build" → "Firestore Database"**
2. Clique em **"Create database"**
3. Escolha o modo:
   - ⚠️ **Test mode** (para desenvolvimento) - RECOMENDADO AGORA
   - 🔒 **Production mode** (para produção)

### Passo 3: Escolher Localização

1. Selecione a localização mais próxima:
   - **europe-west1** (Bélgica) - RECOMENDADO para Portugal
   - **europe-west3** (Frankfurt)
2. Clique em **"Enable"**
3. Aguarde 1-2 minutos para criação

---

## Regras de Segurança (Test Mode)

Se escolheu **Test mode**, as regras serão:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2026, 3, 1);
    }
  }
}
```

⚠️ **ATENÇÃO:** Estas regras expiram em 1 de Março de 2026!

---

## Regras de Segurança (Production Mode - Recomendado)

Para produção, use estas regras:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Tarefas - apenas o dono pode acessar
    match /tasks/{taskId} {
      allow read, write: if request.auth != null &&
                          request.auth.uid == resource.data.userId;
      allow create: if request.auth != null &&
                     request.auth.uid == request.resource.data.userId;
    }

    // Notas - apenas o dono pode acessar
    match /notes/{noteId} {
      allow read, write: if request.auth != null &&
                          request.auth.uid == resource.data.userId;
      allow create: if request.auth != null &&
                     request.auth.uid == request.resource.data.userId;
    }
  }
}
```

---

## Após Criar o Database

### 1. Reiniciar o App

- Feche completamente o app
- Reabra e faça login novamente

### 2. Verificar Funcionamento

- ✅ Criar uma tarefa
- ✅ Deve aparecer no dashboard
- ✅ Deve sincronizar com Firestore

### 3. Verificar no Firebase Console

1. Vá em **Firestore Database**
2. Deve ver a coleção **"tasks"**
3. Dentro, verá os documentos das tarefas criadas

---

## Estrutura de Dados Esperada

### Collection: `tasks`

```
tasks/
  └── {taskId}/
      ├── id: string
      ├── userId: string
      ├── titulo: string
      ├── descricao: string
      ├── dataInicio: timestamp
      ├── dataFim: timestamp
      ├── duracaoMinutos: number
      ├── prioridade: string
      ├── estado: string
      ├── criadoEm: timestamp
      └── atualizadoEm: timestamp
```

### Collection: `notes`

```
notes/
  └── {noteId}/
      ├── id: string
      ├── userId: string
      ├── titulo: string
      ├── conteudo: string
      ├── lembrete: timestamp (opcional)
      └── criadoEm: timestamp
```

---

## Troubleshooting

### Erro persiste após criar database?

1. Verifique se está usando o projeto correto
2. Aguarde 2-3 minutos
3. Limpe cache do app:
   ```bash
   flutter clean
   flutter pub get
   ```
4. Reinstale o app

### Como verificar se database existe?

1. Firebase Console → Firestore Database
2. Deve ver a aba "Data" com opção de adicionar coleção

### Custo do Firestore

- **Gratuito** até:
  - 50.000 leituras/dia
  - 20.000 escritas/dia
  - 20.000 exclusões/dia
  - 1 GB armazenamento

Para uso pessoal/desenvolvimento, **não terá custos**.

---

## Link Direto

👉 **Criar Database Agora:**
https://console.cloud.google.com/datastore/setup?project=notario-6961f

---

## Próximos Passos Após Configuração

1. ✅ Criar Firestore Database
2. ✅ Configurar regras de segurança
3. ✅ Reiniciar app
4. ✅ Testar criação de tarefa
5. ✅ Verificar sincronização

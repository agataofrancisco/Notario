# 🔥 Ativar Google Sign-In no Firebase

## ⚡ Passos Rápidos (2 minutos)

### 1. Abrir Firebase Console

Vá para: https://console.firebase.google.com/project/notario-6961f/authentication/providers

### 2. Ativar Google Sign-In

1. Clique em **"Sign-in method"** (se não estiver já lá)
2. Clique em **"Google"**
3. Ative o botão **"Enable"**
4. **Email de suporte do projeto:** coloque seu email
5. Clique em **"Save"**

### 3. Adicionar SHA-1 (Android)

Para Android funcionar, precisa adicionar SHA-1:

```bash
# No terminal, execute:
cd android
./gradlew signingReport

# Ou no Windows:
gradlew.bat signingReport
```

Copie o **SHA-1** que aparece e adicione no Firebase:

1. Firebase Console → Project Settings
2. Scroll até "Your apps"
3. Clique no app Android
4. Adicione o SHA-1 em "SHA certificate fingerprints"

### 4. Baixar Novo google-services.json

Depois de adicionar SHA-1:

1. Baixe o novo `google-services.json`
2. Substitua em `android/app/google-services.json`

---

## ✅ Pronto!

Agora execute:

```bash
flutter run
```

O Google Sign-In real vai funcionar! 🎉

---

## 🔍 Verificar se Está Ativo

No Firebase Console, em Authentication → Sign-in method, deve aparecer:

- ✅ Google: **Enabled**

---

## ⚠️ Problemas Comuns

### "Sign in failed"

- Verifique se o SHA-1 está correto
- Baixe o novo `google-services.json`

### "Developer error"

- SHA-1 não foi adicionado
- Execute `gradlew signingReport` e adicione

### "Network error"

- Backend não está rodando
- Verifique `http://localhost:8080/health`

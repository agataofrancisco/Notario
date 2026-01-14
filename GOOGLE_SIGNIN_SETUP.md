# Configuração do Google Sign-In

## ⚠️ IMPORTANTE: Configurar antes de executar

O app NOTÁRIO usa Google Sign-In para autenticação. Você precisa configurar as credenciais do Google Cloud antes de executar.

## 📋 Passos para Configurar

### 1. Criar Projeto no Google Cloud Console

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Ative a **Google Calendar API** e **Google Sign-In API**

### 2. Criar Credenciais OAuth 2.0

#### Para Web (Flutter Web)

1. Vá em **APIs & Services** → **Credentials**
2. Clique em **Create Credentials** → **OAuth client ID**
3. Escolha **Web application**
4. Configure:
   - **Name:** NOTÁRIO Web
   - **Authorized JavaScript origins:**
     - `http://localhost:8080` (desenvolvimento)
     - Seu domínio de produção (se houver)
   - **Authorized redirect URIs:**
     - `http://localhost:8080`
5. Copie o **Client ID** gerado

#### Para Android

1. Crie outro **OAuth client ID**
2. Escolha **Android**
3. Configure:
   - **Name:** NOTÁRIO Android
   - **Package name:** `com.example.notario` (ou o seu)
   - **SHA-1:** Execute `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
4. Copie o **Client ID** gerado

#### Para iOS

1. Crie outro **OAuth client ID**
2. Escolha **iOS**
3. Configure:
   - **Name:** NOTÁRIO iOS
   - **Bundle ID:** `com.example.notario` (ou o seu)
4. Copie o **Client ID** gerado

### 3. Configurar no Projeto

#### Web

Edite `web/index.html` e substitua `YOUR_CLIENT_ID`:

```html
<meta
  name="google-signin-client_id"
  content="SEU_CLIENT_ID_WEB.apps.googleusercontent.com"
/>
```

#### Android

1. Baixe o arquivo `google-services.json` do Google Cloud Console
2. Coloque em `android/app/google-services.json`

#### iOS

1. Baixe o arquivo `GoogleService-Info.plist` do Google Cloud Console
2. Coloque em `ios/Runner/GoogleService-Info.plist`

### 4. Configurar Backend

Edite `backend/.env` e adicione:

```env
GOOGLE_CLIENT_ID=SEU_CLIENT_ID_WEB.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=SEU_CLIENT_SECRET
JWT_SECRET=uma_chave_secreta_forte_aqui
```

## 🚀 Executar Após Configuração

### Backend

```bash
cd backend
go run cmd/server/main.go
```

### Mobile

```bash
cd mobaili
flutter pub get
flutter run
```

## 📝 Notas

- **Desenvolvimento:** Use `http://localhost` para testar
- **Produção:** Configure domínios reais nas origens autorizadas
- **Segurança:** Nunca commite credenciais no Git
- **Calendar API:** Certifique-se de que está ativada no Google Cloud Console

## ❓ Problemas Comuns

### "ClientID not set"

- Verifique se o Client ID está correto em `web/index.html`
- Certifique-se de que não há espaços extras

### "Unauthorized"

- Verifique se a origem está nas **Authorized JavaScript origins**
- Para localhost, use `http://localhost:PORTA` (sem trailing slash)

### "Access blocked"

- Configure a tela de consentimento OAuth em Google Cloud Console
- Adicione seu email como usuário de teste

## 🔗 Links Úteis

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Sign-In para Flutter](https://pub.dev/packages/google_sign_in)
- [Google Calendar API](https://developers.google.com/calendar)

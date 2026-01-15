# NOTÁRIO - Configuração Firebase ✅

## ✅ O Que Já Está Configurado

### 1. Ficheiros de Configuração

- ✅ `android/app/google-services.json` - Movido para local correto
- ✅ `ios/Runner/GoogleService-Info.plist` - Movido para local correto

### 2. Android

- ✅ `android/build.gradle` - Google Services plugin adicionado
- ✅ `android/app/build.gradle` - Plugin aplicado + minSdk 21
- ✅ MultiDex ativado

### 3. Dependências Flutter

- ✅ `firebase_core` - Core do Firebase
- ✅ `firebase_auth` - Autenticação
- ✅ `firebase_messaging` - Notificações push
- ✅ `firebase_analytics` - Analytics
- ✅ `firebase_crashlytics` - Crash reporting
- ✅ `google_sign_in` - Login com Google

### 4. Código

- ✅ `lib/main.dart` - Inicialização do Firebase
- ✅ `lib/core/services/auth_service.dart` - Serviço de autenticação
- ✅ `lib/firebase_options.dart` - Configurações (precisa atualizar valores)

---

## ⚠️ PRÓXIMOS PASSOS OBRIGATÓRIOS

### 1. Atualizar `firebase_options.dart`

Precisas extrair os valores do `google-services.json` e `GoogleService-Info.plist`:

#### Do `google-services.json` (Android):

```json
{
  "project_info": {
    "project_id": "...", // Copiar para projectId
    "storage_bucket": "..." // Copiar para storageBucket
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "..." // Copiar para appId (Android)
      },
      "api_key": [
        {
          "current_key": "..." // Copiar para apiKey (Android)
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "..." // Sender ID
            }
          ]
        }
      }
    }
  ]
}
```

#### Do `GoogleService-Info.plist` (iOS):

```xml
<key>API_KEY</key>
<string>...</string>  <!-- Copiar para apiKey (iOS) -->

<key>GOOGLE_APP_ID</key>
<string>...</string>  <!-- Copiar para appId (iOS) -->
```

### 2. Executar `flutter pub get`

```bash
cd mobaili
flutter pub get
```

### 3. Configurar iOS (Podfile)

Editar `ios/Podfile` e adicionar no topo:

```ruby
platform :ios, '13.0'  # Firebase requer iOS 13+
```

### 4. Instalar Pods (iOS)

```bash
cd ios
pod install
```

---

## 🔐 Configuração Google Sign-In

### Android

Já está configurado automaticamente pelo `google-services.json` ✅

### iOS

Precisas adicionar o **URL Scheme** ao `Info.plist`:

1. Abrir `GoogleService-Info.plist`
2. Copiar o valor de `REVERSED_CLIENT_ID`
3. Adicionar ao `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>COLE_AQUI_O_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

## 🧪 Testar

### 1. Executar o App

```bash
flutter run
```

### 2. Testar Login

```dart
// No teu código
final authService = AuthService();
final user = await authService.signInWithGoogle();
print('Utilizador: ${user.nome}');
```

---

## 📝 Ficheiros Criados/Modificados

### Criados:

- `lib/firebase_options.dart`
- `lib/core/services/auth_service.dart`

### Modificados:

- `pubspec.yaml`
- `lib/main.dart`
- `android/build.gradle`
- `android/app/build.gradle`

### Movidos:

- `google-services.json` → `android/app/`
- `GoogleService-Info.plist` → `ios/Runner/`

---

## ❓ Dúvidas Comuns

### "Firebase não inicializa"

- Verificar se `firebase_options.dart` tem os valores corretos
- Verificar se `google-services.json` está em `android/app/`

### "Google Sign-In não funciona no iOS"

- Verificar se adicionaste o `REVERSED_CLIENT_ID` ao `Info.plist`
- Verificar se `GoogleService-Info.plist` está em `ios/Runner/`

### "Erro de build no Android"

- Executar `flutter clean`
- Executar `flutter pub get`
- Rebuild

---

## 🎯 Próximo: Implementar UI de Login

Queres que eu crie a tela de login com o botão "Entrar com Google"?

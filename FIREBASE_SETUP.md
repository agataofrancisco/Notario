# Configuração do Firebase - NOTÁRIO

## 🔥 Passo a Passo

### 1. Instalar Firebase CLI

```bash
# Instalar Firebase CLI globalmente
npm install -g firebase-tools

# Ou usando curl (Windows PowerShell como Admin)
irm https://firebase.tools/bin/win/instant/latest -OutFile firebase-tools.exe
```

### 2. Login no Firebase

```bash
firebase login
```

### 3. Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 4. Configurar Firebase no Projeto

**Execute este comando na pasta `mobaili`:**

```bash
cd mobaili
flutterfire configure
```

Isso vai:

- ✅ Criar `firebase_options.dart` automaticamente
- ✅ Configurar Android
- ✅ Configurar iOS
- ✅ Configurar Web

### 5. Selecionar o Projeto

Quando perguntado, seleciona: **`notario-6961f`**

### 6. Selecionar Plataformas

Seleciona:

- ✅ Android
- ✅ iOS (se tiveres Mac)
- ⬜ Web (opcional)

---

## 📝 Alternativa Manual (se FlutterFire não funcionar)

Se o comando `flutterfire configure` não funcionar, podes criar o ficheiro manualmente:

### 1. Ir ao Firebase Console

https://console.firebase.google.com/project/notario-6961f/settings/general

### 2. Adicionar Apps

- Adicionar app Android
- Adicionar app iOS (opcional)

### 3. Copiar as configurações

Depois de adicionar as apps, o Firebase vai gerar as configurações que precisas copiar para `firebase_options.dart`.

---

## ✅ Verificar Configuração

Depois de executar `flutterfire configure`, deves ter:

```
mobaili/
├── lib/
│   └── firebase_options.dart  ← NOVO!
├── android/
│   └── app/
│       └── google-services.json  ← NOVO!
└── ios/
    └── Runner/
        └── GoogleService-Info.plist  ← NOVO!
```

---

## 🚀 Próximo Passo

Depois de configurar, executa:

```bash
flutter pub get
flutter run
```

---

## ⚠️ Problemas Comuns

### "Firebase CLI não encontrado"

```bash
# Adicionar ao PATH (Windows)
# Procurar por "firebase-tools.exe" e adicionar a pasta ao PATH do sistema
```

### "FlutterFire CLI não encontrado"

```bash
# Adicionar Dart pub global ao PATH
# Adicionar: %USERPROFILE%\AppData\Local\Pub\Cache\bin
```

### "Projeto não encontrado"

Certifica-te que estás logado na conta correta:

```bash
firebase logout
firebase login
```

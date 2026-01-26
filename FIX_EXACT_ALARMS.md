# 🔔 Solução: Erro de Alarmes Exatos no Android

## ❌ Erro Encontrado

```
PlatformException (PlatformException(exact_alarms_not_permitted, Exact alarms are not permitted, null, null))
```

## 🔍 Causa

No Android 12+ (API 31+), apps precisam de permissão explícita para agendar alarmes exatos. Isso é necessário para notificações precisas.

## ✅ Solução Implementada

### 1. Permissões Adicionadas no AndroidManifest.xml

```xml
<!-- Permissões para notificações -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

### 2. Método de Solicitação de Permissões Adicionado

No `NotificationService`, foi adicionado o método `_requestPermissions()`:

```dart
Future<void> _requestPermissions() async {
  final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    // Solicitar permissão para notificações
    await androidPlugin.requestNotificationsPermission();

    // Solicitar permissão para alarmes exatos (Android 12+)
    await androidPlugin.requestExactAlarmsPermission();
  }
}
```

### 3. AndroidScheduleMode Configurado

Todos os `zonedSchedule` já estão usando:

```dart
androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
```

## 🧪 Como Testar

### 1. Desinstalar o App Antigo

```bash
adb uninstall com.example.notario
```

### 2. Reinstalar o App

```bash
flutter run
```

### 3. Verificar Permissões

Quando o app iniciar pela primeira vez, você verá 2 diálogos:

1. **"Permitir que Notário envie notificações?"**
   - Clique em **Permitir**

2. **"Permitir que Notário defina alarmes exatos?"**
   - Clique em **Permitir**

### 4. Verificar Manualmente (se necessário)

Se os diálogos não aparecerem:

1. Vá em **Configurações** do Android
2. **Apps** > **Notário**
3. **Permissões**
4. Verifique se estão ativadas:
   - ✅ Notificações
   - ✅ Alarmes e lembretes

## 📱 Configuração Manual (Alternativa)

Se ainda houver problemas:

1. Abra **Configurações** do Android
2. **Apps** > **Notário**
3. **Permissões**
4. **Alarmes e lembretes** > **Permitir**
5. **Notificações** > **Permitir**

## 🔧 Verificar se Funcionou

### Teste Rápido:

1. Crie uma tarefa para **daqui a 20 minutos**
2. Aguarde 5 minutos
3. Aos 15 minutos antes, você deve receber a notificação

### Verificar Logs:

```bash
flutter logs
```

Procure por:

- ✅ `Notification scheduled successfully`
- ❌ `exact_alarms_not_permitted` (se ainda houver erro)

## 📋 Checklist de Solução

- [x] Permissões adicionadas no AndroidManifest.xml
- [x] Método `_requestPermissions()` implementado
- [x] `androidScheduleMode` configurado
- [x] Permissões solicitadas na inicialização
- [ ] App desinstalado e reinstalado
- [ ] Permissões concedidas pelo usuário
- [ ] Notificações testadas

## 🚨 Importante

**SEMPRE desinstale o app antigo antes de reinstalar** quando mudar permissões no AndroidManifest.xml:

```bash
# Desinstalar
adb uninstall com.example.notario

# Ou manualmente no dispositivo:
# Configurações > Apps > Notário > Desinstalar

# Depois reinstalar
flutter run
```

## 📖 Referências

- [Android Exact Alarms](https://developer.android.com/about/versions/12/behavior-changes-12#exact-alarm-permission)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Android Schedule Modes](https://developer.android.com/reference/android/app/AlarmManager)

---

**Status:** ✅ Correção implementada
**Próximo passo:** Desinstalar e reinstalar o app para aplicar as novas permissões

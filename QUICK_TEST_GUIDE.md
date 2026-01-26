# 🧪 Guia Rápido de Testes - NOTÁRIO

## ⚡ Testes Rápidos (5 minutos)

### 1️⃣ Teste de Validação do Dia (2 min)

**Objetivo:** Verificar se o bloqueio de dia cheio funciona

**Passos:**

1. Abra o app
2. Clique no botão **+** (canto inferior direito)
3. Preencha:
   - Título: "Tarefa Teste 1"
   - Duração: 8 horas (480 min)
4. Clique em **Salvar**
5. ✅ **Deve mostrar:** Diálogo verde "Dia Viável"
6. Clique em **Salvar Tarefa**
7. Volte ao dashboard

8. Clique no **+** novamente
9. Preencha:
   - Título: "Tarefa Teste 2"
   - Duração: 10 horas (600 min)
10. Clique em **Salvar**
11. ✅ **Deve mostrar:** Diálogo vermelho "Dia Cheio!"
12. ✅ **Deve ter:** Aviso laranja "Não é possível adicionar"
13. ✅ **NÃO deve ter:** Botão "Salvar Tarefa"
14. ✅ **Deve mostrar:** Lista de dias alternativos
15. Clique em um dia alternativo
16. ✅ **Deve:** Fechar diálogo e mostrar SnackBar verde
17. Clique em **Salvar** novamente
18. ✅ **Agora deve:** Mostrar "Dia Viável" e permitir salvar

---

### 2️⃣ Teste de Lista e Progresso (1 min)

**Objetivo:** Verificar filtro de tarefas e círculo de progresso

**Passos:**

1. No dashboard, veja a lista de tarefas
2. ✅ **Deve mostrar:** Apenas "Tarefa Teste 1" (pendente)
3. Veja o círculo no topo
4. ✅ **Deve mostrar:** "0% Concluído" (nenhuma concluída ainda)

5. Clique na "Tarefa Teste 1"
6. Clique em **Iniciar Execução**
7. Aguarde 2 segundos
8. Clique nos 3 pontos (menu)
9. Clique em **Finalizar Tarefa**
10. Confirme

11. Volte ao dashboard
12. ✅ **Deve mostrar:** Lista vazia ou "Nenhuma tarefa para hoje!"
13. ✅ **Círculo deve mostrar:** "100% Concluído"

---

### 3️⃣ Teste de Reagendamento (2 min)

**Objetivo:** Verificar se tarefa vai para novo dia após reagendar

**Passos:**

1. Crie uma nova tarefa para hoje:
   - Título: "Tarefa Reagendar"
   - Duração: 1 hora (60 min)
2. Salve
3. ✅ **Deve aparecer:** Na lista do dashboard

4. Clique na tarefa
5. Clique em **Iniciar Execução**
6. Clique nos 3 pontos (menu)
7. Clique em **Reagendar Tarefa**
8. Selecione: Amanhã
9. Selecione: 10:00
10. Confirme

11. ✅ **Deve:** Voltar ao dashboard automaticamente
12. ✅ **Deve:** Tarefa NÃO aparecer mais na lista de hoje
13. No calendário semanal (mini calendário), clique em amanhã
14. ✅ **Deve:** "Tarefa Reagendar" aparecer na lista de amanhã

---

## 🔔 Teste de Notificações (Opcional - 20 min)

### Preparação:

1. Certifique-se de que o app tem permissão para notificações
2. Mantenha o app em background (não feche)

### Teste:

1. Crie uma tarefa para **daqui a 20 minutos**
   - Exemplo: Se agora são 14:00, crie para 14:20
2. Salve a tarefa
3. Aguarde 5 minutos (até 14:05)
4. ✅ **Deve receber:** Notificação "Lembrete: [Nome da Tarefa] em 15 minutos"

5. Aos 14:20, inicie a execução da tarefa
6. Aguarde até faltar 5 minutos para acabar
7. ✅ **Deve receber:** Notificação "Aviso: 5 minutos restantes"

8. Aguarde o timer acabar
9. ✅ **Deve receber:** Notificação "Tempo Esgotado!" (fullScreen no Android)

---

## 🎯 Checklist Rápido

### Interface

- [ ] FAB mostra ícone **+** (não texto "Notário")
- [ ] Círculo de progresso atualiza quando tarefa é concluída
- [ ] Tarefas concluídas somem da lista
- [ ] Pull-to-refresh funciona

### Validação

- [ ] Dia cheio bloqueia salvamento
- [ ] Diálogo mostra aviso claro
- [ ] Dias alternativos aparecem
- [ ] Clicar em dia alternativo atualiza data

### Navegação

- [ ] Após salvar tarefa, volta ao dashboard
- [ ] Após concluir tarefa, volta ao dashboard
- [ ] Após reagendar, volta ao dashboard
- [ ] Dashboard atualiza automaticamente

### Dados

- [ ] Tarefas persistem após fechar app
- [ ] Reagendamento move tarefa para novo dia
- [ ] Não há erros de DateTime
- [ ] Estatísticas calculam corretamente

---

## 🐛 Se Encontrar Problemas

### Erro de DateTime:

```
Solução: Limpe os dados do app e tente novamente
Settings > Apps > Notário > Storage > Clear Data
```

### Notificações não aparecem:

```
Solução: Verifique permissões
Settings > Apps > Notário > Permissions > Notifications > Allow
```

### Dashboard não atualiza:

```
Solução: Pull-to-refresh (arraste para baixo)
```

### Tarefa não salva:

```
Solução: Verifique se o dia não está cheio
Se estiver, escolha um dia alternativo
```

---

## ✅ Resultado Esperado

Após todos os testes:

- ✅ Validação funciona e bloqueia dias cheios
- ✅ Lista mostra apenas tarefas pendentes
- ✅ Círculo de progresso atualiza corretamente
- ✅ Reagendamento move tarefas para novo dia
- ✅ Dashboard recarrega automaticamente
- ✅ Notificações aparecem nos horários corretos
- ✅ Sem erros ou crashes

---

## 📱 Comandos Úteis

### Rodar o app:

```bash
cd "c:\Users\agata\OneDrive\Documents\Gitchi Habi\Notario"
flutter run
```

### Ver logs:

```bash
flutter logs
```

### Limpar e reconstruir:

```bash
flutter clean
flutter pub get
flutter run
```

### Build release:

```bash
flutter build apk --release
```

---

**Boa sorte com os testes! 🚀**

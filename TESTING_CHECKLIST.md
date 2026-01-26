# ✅ NOTÁRIO - Checklist de Testes

## 📱 Testes Funcionais

### Autenticação

- [ ] Login com Google funciona
- [ ] Logout funciona corretamente
- [ ] Estado de autenticação persiste após fechar app
- [ ] Redirecionamento correto após login/logout

### Tarefas - CRUD

- [ ] Criar nova tarefa
- [ ] Editar tarefa existente
- [ ] Deletar tarefa
- [ ] Listar tarefas do dia
- [ ] Filtrar tarefas por estado
- [ ] Validação de formulário funciona

### Tarefas - Validação de Sobrecarga

- [ ] Validação detecta dia cheio
- [ ] Sugestão de dias alternativos funciona
- [ ] Bloqueio de salvamento quando inviável
- [ ] Mensagens de feedback corretas

### Modo Foco (Execution)

- [ ] Timer inicia corretamente
- [ ] Pause funciona
- [ ] Resume funciona
- [ ] Finish completa a tarefa
- [ ] Skip marca como pulada
- [ ] Cancel marca como cancelada
- [ ] Reschedule abre date/time picker
- [ ] Reschedule atualiza a tarefa
- [ ] Animação de ampulheta funciona
- [ ] Cores mudam conforme progresso
- [ ] Notificação de tempo esgotado

### Notas

- [ ] Criar nova nota
- [ ] Editar nota existente
- [ ] Deletar nota
- [ ] Listar notas
- [ ] Adicionar lembrete
- [ ] Remover lembrete
- [ ] Notificação de lembrete funciona

### Dashboard

- [ ] Calendário semanal exibe corretamente
- [ ] Cores do calendário refletem status
- [ ] Indicadores de progresso corretos
- [ ] Status do dia atualiza
- [ ] Tempo livre calculado corretamente
- [ ] Navegação entre dias funciona

### Estatísticas

- [ ] Resumo geral exibe dados corretos
- [ ] Taxa de conclusão calculada corretamente
- [ ] Streak atual correto
- [ ] Melhor streak correto
- [ ] Calendário de calor semanal funciona
- [ ] Breakdown semanal exibe dados
- [ ] Conquistas exibem corretamente

### Notificações

- [ ] Lembrete de tarefa (15 min antes)
- [ ] Aviso de timer (5 min antes)
- [ ] Fim de timer (fullScreenIntent)
- [ ] Lembrete de nota
- [ ] Navegação via payload funciona
- [ ] Cancelamento de notificações funciona

---

## 🎨 Testes de UI/UX

### Tema

- [ ] Modo claro funciona
- [ ] Modo escuro funciona
- [ ] Transição entre temas suave
- [ ] Cores consistentes em todas as telas

### Responsividade

- [ ] Layout adapta a diferentes tamanhos
- [ ] Textos não cortam
- [ ] Botões acessíveis
- [ ] Scroll funciona em listas longas

### Animações

- [ ] Ampulheta anima suavemente
- [ ] Transições de tela suaves
- [ ] Loading indicators aparecem
- [ ] Feedback visual em ações

### Acessibilidade

- [ ] Textos legíveis
- [ ] Contraste adequado
- [ ] Botões com tamanho mínimo
- [ ] Tooltips informativos

---

## 💾 Testes de Dados

### Banco de Dados Local

- [ ] Criação de registros
- [ ] Leitura de registros
- [ ] Atualização de registros
- [ ] Deleção de registros
- [ ] Queries complexas funcionam
- [ ] Índices otimizam buscas

### Sincronização (se habilitada)

- [ ] Dados locais sincronizam com Firestore
- [ ] Conflitos são resolvidos
- [ ] sync_status atualiza corretamente
- [ ] Retry em caso de falha

### Persistência

- [ ] Dados persistem após fechar app
- [ ] Dados persistem após reiniciar device
- [ ] Logout limpa dados locais
- [ ] Backup/restore funciona (se implementado)

---

## 🔔 Testes de Notificações

### Android

- [ ] Notificações aparecem
- [ ] Sons tocam
- [ ] Vibração funciona
- [ ] fullScreenIntent funciona
- [ ] Canais separados funcionam
- [ ] Permissões solicitadas

### iOS

- [ ] Notificações aparecem
- [ ] Sons tocam
- [ ] Badges atualizam
- [ ] Permissões solicitadas
- [ ] Interrupção adequada

---

## ⚡ Testes de Performance

### Carregamento

- [ ] App inicia em < 3 segundos
- [ ] Telas carregam rapidamente
- [ ] Listas renderizam suavemente
- [ ] Sem lag em animações

### Memória

- [ ] Uso de memória estável
- [ ] Sem memory leaks
- [ ] Imagens otimizadas
- [ ] Cache gerenciado

### Bateria

- [ ] Consumo de bateria aceitável
- [ ] Background tasks otimizados
- [ ] Notificações não drenam bateria

---

## 🐛 Testes de Erro

### Validações

- [ ] Campos obrigatórios validados
- [ ] Formatos de data/hora validados
- [ ] Limites de caracteres respeitados
- [ ] Mensagens de erro claras

### Casos Extremos

- [ ] Lista vazia exibe estado correto
- [ ] Sem conexão exibe mensagem
- [ ] Erro de servidor tratado
- [ ] Timeout tratado
- [ ] Dados inválidos rejeitados

### Recuperação

- [ ] App recupera de crashes
- [ ] Dados não corrompem
- [ ] Estado consistente após erro
- [ ] Retry funciona

---

## 🔒 Testes de Segurança

### Autenticação

- [ ] Token expira corretamente
- [ ] Refresh token funciona
- [ ] Logout limpa sessão
- [ ] Dados sensíveis não expostos

### Dados

- [ ] SQLite criptografado (se habilitado)
- [ ] Comunicação HTTPS
- [ ] Validação server-side
- [ ] Regras Firestore configuradas

---

## 📱 Testes de Dispositivos

### Android

- [ ] Android 8.0+ (API 26+)
- [ ] Diferentes tamanhos de tela
- [ ] Diferentes densidades
- [ ] Diferentes fabricantes

### iOS

- [ ] iOS 12.0+
- [ ] iPhone (diferentes modelos)
- [ ] iPad (se suportado)
- [ ] Diferentes orientações

---

## 🚀 Testes de Build

### Debug

- [ ] Build debug funciona
- [ ] Hot reload funciona
- [ ] Hot restart funciona
- [ ] Debug console sem erros

### Release

- [ ] Build release funciona
- [ ] APK/IPA gerado corretamente
- [ ] Tamanho do app aceitável
- [ ] Obfuscação funciona
- [ ] Sem warnings críticos

---

## 📊 Métricas de Qualidade

### Cobertura de Código

- [ ] Testes unitários > 70%
- [ ] Testes de integração > 50%
- [ ] Testes de widget > 60%

### Análise Estática

- [ ] 0 erros de lint
- [ ] 0 warnings críticos
- [ ] Complexidade ciclomática < 10
- [ ] Duplicação de código < 5%

### Performance

- [ ] FPS > 55 em animações
- [ ] Tempo de resposta < 100ms
- [ ] Uso de memória < 200MB
- [ ] Tamanho do app < 50MB

---

## ✅ Checklist de Release

### Pré-Release

- [ ] Todos os testes passam
- [ ] Documentação atualizada
- [ ] README completo
- [ ] CHANGELOG atualizado
- [ ] Versão incrementada

### Store

- [ ] Screenshots preparados
- [ ] Descrição escrita
- [ ] Ícone otimizado
- [ ] Feature graphic criado
- [ ] Política de privacidade publicada

### Pós-Release

- [ ] Monitoramento de crashes
- [ ] Analytics configurado
- [ ] Feedback dos usuários
- [ ] Plano de updates

---

**Data do Checklist**: 21 de Janeiro de 2026
**Versão**: 1.0.0
**Status**: Pronto para Testes

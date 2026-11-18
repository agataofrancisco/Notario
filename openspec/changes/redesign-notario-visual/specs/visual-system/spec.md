# Requisitos: sistema visual do Notário

## Requisito: Consistência entre telas

O sistema SHALL apresentar cores, tipografia, espaçamento, superfícies, cabeçalhos, controlos e navegação consistentes em todas as telas existentes.

### Cenário: Abrir destinos principais

- **WHEN** o utilizador percorre dashboard, tarefas, notas, estatísticas, formulários e execução em foco
- **THEN** margens, níveis de título, ações primárias, raios, ícones e estados equivalentes seguem os mesmos tokens e componentes
- **AND** nenhum ecrã introduz um gradiente ou estilo de cartão próprio sem uma razão semântica especificada

## Requisito: Alinhamento adaptável

O sistema SHALL alinhar cabeçalhos e conteúdo numa grelha comum, preservar legibilidade e manter ações utilizáveis em dimensões móveis suportadas.

### Cenário: Ecrã compacto ou conteúdo ampliado

- **WHEN** o espaço horizontal é reduzido ou o utilizador aumenta o tamanho do texto
- **THEN** conteúdo reflowa verticalmente sem sobreposição, corte de ações essenciais ou scroll horizontal
- **AND** os controlos interativos mantêm alvos táteis adequados e respeitam áreas seguras e teclado

## Requisito: Cor semântica acessível

O sistema SHALL usar roxo moderado para ação/foco e cores semânticas consistentes, comunicando prioridade e estado também por rótulo, forma ou ícone.

### Cenário: Interpretar prioridade ou estado

- **WHEN** uma tarefa está pendente, em foco, concluída, pulada, atrasada ou tem prioridade
- **THEN** o estado é identificável sem depender apenas da perceção da cor
- **AND** pares de texto/fundo mantêm contraste legível nos temas suportados

## Requisito: Hierarquia orientada à próxima ação

Cada ecrã SHALL destacar a decisão ou ação primária apropriada ao contexto, reduzindo decoração e opções concorrentes.

### Cenário: Criar e guardar tarefa

- **WHEN** o utilizador cria ou edita uma tarefa
- **THEN** título, descrição, planeamento, prioridade e opções avançadas aparecem numa ordem compreensível
- **AND** erros de validação surgem junto ao campo, valores introduzidos são preservados e a ação Guardar permanece alcançável com o teclado aberto

### Cenário: Executar tarefa em foco

- **WHEN** o utilizador executa uma tarefa
- **THEN** tarefa atual, tempo e progresso têm maior hierarquia visual que ilustração ou decoração
- **AND** concluir, pausar/retomar, pular, reagendar e sair têm rótulos e resultados distinguíveis

## Requisito: Estados de interface completos

As listas e fluxos SHALL oferecer tratamento visual compreensível para carregamento, vazio, erro, sucesso, operação offline e conteúdo indisponível quando aplicável.

### Cenário: Lista sem dados ou com falha

- **WHEN** uma lista não contém itens ou não pode ser carregada
- **THEN** a tela explica a situação e oferece a ação de recuperação apropriada
- **AND** uma falha não é apresentada como lista vazia nem como carregamento infinito

## Requisito: Navegação fiel às capacidades

A navegação SHALL apresentar destinos operacionais existentes e manter indicação clara do destino ativo.

### Cenário: Navegar entre secções principais

- **WHEN** o utilizador alterna entre destinos principais
- **THEN** ícone, rótulo e estado selecionado permanecem consistentes
- **AND** não é apresentado um destino sem percurso funcional associado

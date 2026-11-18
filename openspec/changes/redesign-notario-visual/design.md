# Design: sistema visual do Notário

## Objetivo de experiência

O Notário deve parecer uma ferramenta de trabalho pessoal: calma, precisa, confiável e focada. A interface ajuda a decidir o próximo passo sem competir com a tarefa. A referência serve como inventário de conteúdo e intenção — resumo do dia, agenda, notas, tarefa e temporizador — não como prescrição literal de acabamento.

## Direção visual

- Tema segue a preferência claro/escuro do sistema; a aparência clara é a base visual e o tema escuro tem tokens e superfícies próprios.
- Fundo em cinza muito claro quente; superfícies brancas; texto principal em carvão e texto auxiliar em cinza legível.
- Roxo profundo moderado para ação primária, seleção e foco. Token aplicado: `#6254C7`.
- Roxo claro apenas para fundos de seleção suaves. Gradientes, brilho, sombras coloridas e efeitos translúcidos não são decoração padrão; gradiente só pode aparecer num elemento de destaque singular quando aumentar a compreensão.
- Verde para conclusão/progresso, âmbar para atenção e vermelho para erro/urgência. Prioridade deve ser reconhecível por texto e forma além da cor.
- Tipografia sans-serif simples, com escala definida e pesos contidos. Reservar tamanhos grandes a título de página, número de progresso e temporizador.
- Ícones de uma mesma família, traço e tamanho; ilustrações apenas em estados vazios ou na experiência de foco quando contribuam para compreensão.

## Inventário implementado

As rotas e telas existentes foram inventariadas em `lib`: dashboard com navegação interna para Tarefas e Notas; listas autónomas de tarefas e notas usadas por rotas/notificações; formulários de criação/edição; execução em foco; estatísticas; login/registo; seletor de data; calendário semanal; capacidade e resumo do dia; reagendamento inteligente; cartões e estados vazios/erro. Não há tela de Perfil, nem destino de navegação primário para Estatísticas; a referência não foi usada para criar destinos sem fluxo implementado.

O tema global define as paletas clara/escura e os componentes Material. As telas mantêm temas semânticos por função (prioridade, estado, erro e sucesso), mas não valores próprios para a cor primária da marca. A execução usa controlos com texto visível para pausar/retomar/concluir e uma ampulheta sem animação decorativa contínua.

## Grelha e alinhamento

- Usar a mesma margem horizontal de 20 px em telemóveis compactos e 24 px em ecrãs largos; conteúdo centrado com largura máxima apropriada em tablet.
- Espaçamento baseado em múltiplos de 4 px. Separação entre secções maior que o espaço entre título, descrição e conteúdo da mesma secção.
- Alinhar cabeçalho, secções, listas e ações ao mesmo eixo vertical. Evitar cartões de larguras arbitrárias na mesma linha; grelha de duas colunas só para informação curta e comparável.
- Altura mínima de 48 px para controlos tocáveis. Respeitar áreas seguras, teclado, orientação e texto ampliado.
- Usar superfícies planas separadas por espaço e divisores subtis como padrão. Cartão com borda/sombra só quando representar uma unidade ou interação distinta; raios consistentes e moderados.

## Navegação e estrutura

- Navegação inferior representa apenas destinos existentes e frequentes; não desenhar Estatísticas ou Perfil como destinos primários até estarem ligados a percursos funcionais. Rever a entrada atual com Tarefas e Notas para manter rótulos, estados selecionados e FAB consistentes.
- Barra superior de páginas internas usa título alinhado de modo consistente e ação de voltar. Não usar gradientes diferentes por tela.
- Ação de criação contextual fica acessível sem encobrir listas, navegação ou teclado. Rótulo explícito em ecrãs onde o ícone isolado possa ser ambíguo.
- Fluxo: destino principal → seleção de data/filtro contextual → lista ou resumo → criar/editar → feedback de sucesso/erro. Iniciar foco abre uma superfície dedicada; sair, concluir, pular e reagendar têm hierarquia e significado visual distintos.

## Hierarquia por ecrã

### Dashboard / tarefas do dia

1. Cabeçalho curto com saudação ou título e data selecionada.
2. Progresso diário apresentado como resumo secundário claro, com valor e texto (ex.: concluídas de total), sem competir com a agenda.
3. Seletor de data compacto, alinhado e utilizável com leitores de ecrã.
4. Agenda agrupada por período/horário, com hora, título, contexto e prioridade em ordem estável.
5. Criar tarefa como ação principal contextual; vazio oferece uma ação direta para criar a primeira tarefa.

### Notas

- Cabeçalho e filtro pertencem à mesma grelha e não devem deslocar a lista horizontalmente.
- Cartões de nota priorizam título, prévia e tipo/data. Limitar prévias a linhas consistentes e evitar menus ou badges concorrentes.
- Diferenciar lembrete e ideia também por rótulo/ícone, não apenas por âmbar/roxo.

### Criar/editar tarefa

- Começar por título; descrição é opcional e claramente identificada.
- Agrupar data/hora e duração numa secção de planeamento; prioridade e lembrete em opções secundárias.
- Opções avançadas (negociável, margem de segurança, integração) recolhidas ou visualmente secundárias, sem as ocultar de leitores de ecrã.
- Erro aparece junto ao campo, preservando valores. Guardar é a única ação primária fixa; teclado não cobre o botão nem o campo ativo.

### Execução em foco

- Superfície silenciosa e focada: tarefa, duração/temporizador, progresso e controlos essenciais.
- Roxo é adequado como sinal de estado de foco, mas o cronómetro e a legibilidade vêm antes de qualquer ilustração/efeito.
- Concluir recebe a ênfase principal; pausar/retomar e sair são secundários; pular/reagendar exigem rótulo claro e resultado previsível.
- Diferenciar tempo restante, progresso e duração planeada. Atualizar progresso e acessibilidade sem animação excessiva.

### Estatísticas e autenticação

- Reutilizar títulos, grelha, tipografia e cores semânticas. Gráficos têm legenda, unidades e alternativa textual; não depender só da cor.
- Login deve focar identidade, promessa e ação de autenticação, com erros e carregamento explícitos e sem ornamentos que reduzam a confiança.

## Componentes e responsabilidades

- `AppTheme`: fonte única para tokens, temas claro/escuro, tipografia e temas de componentes Material.
- Componentes partilhados: cabeçalho de página, secção, estado vazio, estado de erro com tentar novamente, indicador de prioridade/status, campo de formulário e ação primária.
- Widgets de domínio mantêm os seus dados e callbacks; não copiam regras de negócio para componentes visuais.
- Cada tela é responsável por compor os componentes e conectar estado existente via BLoC. Estados de carregamento, vazio, erro, offline e sucesso devem ser desenhados explicitamente.

## Cores: avaliação da referência

O roxo combina com foco, intenção e a identidade do tema original (`#667EEA`/`#764BA2`). A paleta da imagem, porém, está perto de estética gaming/futurista: preto quase absoluto, violeta fluorescente, brilho e verde menta saturado em simultâneo. Isso pode comunicar energia, mas reduz a sensação de calma e leitura prolongada para planeamento diário. Manter roxo moderado como acento (`#6254C7`), neutralizar as superfícies e reservar verde para conclusão/progresso torna a mesma ideia mais adulta, consistente e confortável.

## Limites de verificação

- A referência mostra Estatísticas e Perfil na barra inferior, mas a implementação principal tem Tarefas e Notas; não foram criados destinos sem percurso funcional.
- Algumas telas auxiliares existem com rotas próprias, enquanto o dashboard contém navegação interna; a linguagem foi consolidada sem alterar esses percursos.
- TalkBack/leitor de ecrã, tamanhos de texto maiores e teclado aberto não foram simulados no aparelho; os controlos nativos, labels, scroll e redimensionamento foram revistos no código.

## Evidência desta implementação

- `flutter analyze` concluiu sem problemas.
- `flutter build apk --debug` concluiu para a versão final. Um APK desta mudança foi instalado e arrancou num Android real (itel A665L, 360 × 806 dp, escala do sistema 1,0); o aparelho desligou antes da instalação da última revisão de limites de largura.
- A inspeção visual no aparelho confirmou a área segura superior, os sete dias visíveis no seletor semanal e ausência de overflow no cabeçalho da agenda; o formulário foi aberto sem guardar alterações.
- Teclado aberto, tamanhos de texto maiores e TalkBack não foram simulados. A adaptação depende de `SingleChildScrollView`, redimensionamento padrão da `Scaffold`, controlos Material e layouts fluídos; esta parte foi revista no código.

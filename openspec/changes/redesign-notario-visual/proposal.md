# Proposta: Redesign visual do Notário

## Motivo

As telas atuais foram evoluindo com estilos locais e inconsistentes. O resultado tem cabeçalhos, cartões, cores, espaços e navegação que não parecem pertencer ao mesmo produto. A referência fornecida aponta para um produto de produtividade em modo foco, mas seu excesso de gradientes, brilhos, superfícies escuras e destaques concorrentes pode fazer a interface parecer genérica e artificial.

## O que muda

- Definir um sistema visual único para tarefas, notas, dashboard, estatísticas, formulários, autenticação e execução em foco.
- Padronizar grelha, margens, tipografia, cores semânticas, superfícies, botões, campos, cartões, navegação e estados.
- Reorganizar a hierarquia visual de cada ecrã em torno da ação principal, mantendo as capacidades e os percursos existentes.
- Usar o roxo como assinatura de foco e ação primária, reduzindo sua saturação e reservando gradientes para ocasiões pontuais.
- Especificar adaptação a ecrãs pequenos, texto ampliado, acessibilidade e estados de carregamento, vazio, erro e operação offline.

## Fora de âmbito

- Alterar regras de negócio, dados, sincronização ou funcionalidades.
- Acrescentar secções de produto que não existem apenas para copiar a imagem de referência.
- Exigir um tema escuro como aparência única; a direção deverá estabelecer uma aparência padrão e deixar preparado o suporte consistente aos temas claro e escuro.

## Impacto

Tema global em `lib/shared/theme/app_theme.dart`; dashboard e navegação em `lib/features/dashboard`; listas e formulários de tarefas/notas; estatísticas; autenticação; execução e componentes partilhados.

# Blueprint do Projeto NOTÁRIO

## Visão Geral

O NOTÁRIO é uma aplicação de produtividade e gestão de tempo, projetada para ajudar os utilizadores a manterem-se disciplinados e focados nos seus objetivos. A aplicação irá utilizar o Firebase para autenticação, armazenamento de dados e outras funcionalidades de backend.

## Funcionalidades e Design Implementados (Até Agora)

Nesta fase inicial, o foco foi a reestruturação e estabilização do projeto. As seguintes ações foram concluídas:

*   **Limpeza de Dependências:** O arquivo `pubspec.yaml` foi completamente reescrito para remover pacotes obsoletos e conflituosos.
*   **Remoção de Código Legado:** Todo o código relacionado com uma arquitetura de backend anterior (baseada em Go e `sqflite`) foi removido.
*   **Estabilização do Ambiente:** As dependências foram resolvidas para criar um ambiente de desenvolvimento estável, pronto para a integração com o Firebase.
*   **Estrutura de UI Básica:** O `main.dart` foi simplificado para exibir uma tela de carregamento básica, servindo como ponto de partida para a nova aplicação.

## Plano de Ação Atual: Integração do Firebase e Autenticação

O próximo objetivo é implementar a autenticação de utilizadores usando o Firebase Authentication.

1.  **Configurar o Firebase:** Executar `flutterfire configure` para conectar a aplicação a um projeto Firebase e gerar o arquivo de configuração `firebase_options.dart`.
2.  **Inicializar o Firebase:** Atualizar o `main.dart` para inicializar o Firebase de forma assíncrona antes de a aplicação ser executada.
3.  **Implementar a Tela de Login:** Criar uma nova tela de login com um design limpo e um botão para "Entrar com o Google".
4.  **Criar o `AuthRepository`:** Desenvolver uma classe de repositório para abstrair as chamadas ao Firebase Authentication, lidando com a lógica de login com o Google.
5.  **Criar o `AuthBloc`:** Implementar um BLoC para gerir o estado da autenticação (autenticado, não autenticado, a carregar, erro).
6.  **Criar a Rota de Decisão:** Desenvolver um widget "splash" ou de "decisão" que escute o estado do `AuthBloc` e navegue o utilizador para a tela de login ou para a tela principal da aplicação, dependendo se ele está autenticado ou não.

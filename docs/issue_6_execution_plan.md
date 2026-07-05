# Plano de Execução - Issue #6: [App] Tela de Login com Testes de Interface

## Objetivo
Implementar a interface de login no aplicativo Flutter (`app/`) com suporte a Login Social (Google/Apple) e persistência local da sessão de usuário, utilizando uma camada de serviço mockada por enquanto (independente do backend real).

## Dependências
- Conclusão da Issue #9 (Design System).

## Divisão de Tarefas

### DEV-FRONT
1. Adicionar o pacote `shared_preferences` (ou similar) no `pubspec.yaml` para persistir o token de sessão localmente.
2. Criar a tela de login (`lib/screens/login_screen.dart`) baseada no design do app (logotipo, slogan e os botões "Entrar com Google" e "Entrar com Apple" usando o `CustomButton`).
3. Criar uma classe simples de gerência de estado de autenticação (`lib/auth/auth_provider.dart` ou similar) contendo estados: deslogado, carregando, logado e erro.
4. Criar um repositório mockado (`lib/auth/auth_repository.dart`) para simular a chamada da API do backend. Ela deve retornar um token JWT fictício e os dados do usuário ("João Silva") de forma simulada.
5. Configurar o redirecionamento de telas no `main.dart`: se o usuário já possuir um token salvo, vai para o Styleguide/Dashboard; caso contrário, exibe a tela de login.
6. Criar testes de Widget em `test/screens/login_screen_test.dart` validando os componentes da tela de login, o clique nos botões e a exibição do loading.
7. Criar testes unitários para a gerência de estado da sessão do usuário.

### QA
- Validar se o fluxo visual e as cores da tela de login estão 100% alinhados com o Design System.
- Testar a persistência local (fechar e reabrir o app simulado e verificar se a sessão se mantém).
- Executar os testes de widget e unitários criados no frontend (`C:\src\flutter\bin\flutter.bat test`) e verificar se todos passam com sucesso.

## Critérios de Aceite (Acceptance Criteria)
- Tela de login fiel à imagem (logo "Meu Correspondente", slogan, botões bem alinhados).
- Clique no login social exibe indicador de carregamento e simula a autenticação com sucesso.
- Token e sessão persistidos localmente (simulação de login persistente).
- Testes automatizados criados e com sucesso.

## Definition of Done (DoD)
- Telas, gerência de estado, mocks e testes desenvolvidos.
- Testes passando com sucesso na CLI.
- QA validou a fidelidade ao design e integridade da sessão.
- Alterações enviadas à branch `main`.

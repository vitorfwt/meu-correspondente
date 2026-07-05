# Plano de Execução - Issue #3: [Backend] API de Autenticação com Testes

## Objetivo
Implementar as rotas e regras de negócio para autenticação na API Node.js, incluindo validação de tokens JWT, integração com login social e registro de novos usuários no banco de dados.

## Dependências
- Conclusão da Issue #2 (Modelagem de Banco de Dados).

## Divisão de Tarefas

### DEV-BACK
1. Configurar dependências de autenticação no backend (ex: `jsonwebtoken`, `bcrypt` ou bibliotecas específicas para autenticação como `passport`, `google-auth-library` para verificar tokens do Google).
2. Criar a estrutura de rotas de autenticação:
   - `POST /api/auth/social-login`: Recebe o provedor (Google ou Apple) e o token de ID do provedor (idToken).
   - O backend valida o token com o provedor correspondente.
   - Procura o usuário por e-mail no banco de dados. Se não existir, cria-o (definindo papel inicial como `client`).
   - Retorna um token JWT do "Meu Correspondente" e as informações do usuário.
3. Criar um middleware de autenticação (`auth.middleware.ts`) para proteger rotas futuras e injetar o usuário autenticado na requisição.
4. Implementar testes unitários para a geração e verificação de tokens JWT.
5. Implementar testes de integração usando Vitest e Supertest para simular chamadas HTTP para `POST /api/auth/social-login` (mockando a validação externa dos provedores).

### DEV-FRONT
- *Nenhuma tarefa nesta Issue.* (Standby).

### QA
- Executar e validar as suítes de testes de autenticação no Vitest.
- Testar os fluxos de sucesso (registro e login) e fluxos de erro (token inválido, dados ausentes).
- Confirmar que as rotas protegidas barram acessos não autenticados.

## Critérios de Aceite (Acceptance Criteria)
- O endpoint `/api/auth/social-login` deve processar tokens do Google/Apple, registrar o usuário se novo, e retornar um JWT válido.
- O JWT deve possuir um tempo de expiração razoável (ex: 7 dias) e conter o ID e papel (role) do usuário.
- O middleware de autenticação deve validar com sucesso o JWT e barrar requisições não autorizadas com código HTTP `401 Unauthorized`.
- Os testes unitários e de integração de autenticação devem rodar e passar com 100% de sucesso.

## Definition of Done (DoD)
- Código de rotas, middlewares, e testes de autenticação criados.
- Testes passando via CLI.
- QA aprovou a entrega e registrou o relatório.
- Código integrado e enviado à branch `main`.

# Plano de Execução - Issue #1: [Setup] Inicialização do Monorepo e Configuração de Testes

## Objetivo
Estruturar o monorepo do projeto e configurar o ambiente de testes unitários e de integração básicos para o frontend e backend.

## Dependências
Nenhuma. Esta é a issue inicial.

## Divisão de Tarefas

### DEV-BACK
1. Criar a pasta `api/` para o backend em Node.js.
2. Inicializar o projeto Node.js (`npm init -y`) e configurar TypeScript.
3. Configurar o framework de testes (Vitest ou Jest).
4. Criar um teste de fumaça simples (smoke test) para validar a configuração.
5. Criar a pasta `crawler/` para futuros scripts de extração.
6. Criar o arquivo `.gitignore` e `README.md` na raiz do monorepo.

### DEV-FRONT
1. Criar a pasta `app/` para o frontend.
2. Inicializar o projeto Flutter na pasta `app/` com suporte a Android e iOS.
3. Garantir que o ambiente de testes padrão do Flutter (`flutter test`) está configurado e que o teste de widget padrão passa.

### QA
1. Validar a estrutura de diretórios criada.
2. Executar e validar a suíte de testes do backend (`api/`).
3. Executar e validar a suíte de testes do frontend (`app/`).
4. Entregar o relatório de testes confirmando o status de "pronto".

## Critérios de Aceite (Acceptance Criteria)
- A estrutura de pastas deve respeitar a divisão: `app/` (Flutter), `api/` (Node.js) e `crawler/` (Scripts).
- O backend em `api/` deve executar testes unitários com o comando `npm run test`.
- O frontend em `app/` deve executar testes de widget com o comando `flutter test`.
- Todas as suítes de testes iniciais devem passar sem falhas.

## Definition of Done (DoD)
- Todas as pastas criadas e estruturadas.
- Configurações de testes implementadas e executadas com sucesso.
- QA aprovou a estrutura e os testes de fumaça.
- Alterações enviadas para a branch `main` do repositório no GitHub.

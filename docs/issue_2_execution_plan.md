# Plano de Execução - Issue #2: [Backend] Modelagem do Banco de Dados e Seeds de Teste

## Objetivo
Estruturar a modelagem e migrações do banco de dados PostgreSQL para suportar o MVP do Meu Correspondente e criar dados iniciais (seeds) de bancos e taxas para viabilizar os testes.

## Dependências
- Conclusão da Issue #1 (Monorepo Setup).

## Divisão de Tarefas

### DEV-BACK
1. Configurar um ORM (recomendamos **Prisma ORM** por simplicidade com TypeScript, ou **Knex.js** caso prefira migrações SQL cruas).
2. Criar a estrutura e tabelas no banco de dados para as seguintes entidades:
   - `users`: ID, nome, e-mail, papel (cliente/corretor), data de criação.
   - `institutions`: ID, nome do banco, url do logo, status ativo.
   - `interest_rates`: ID, ID do banco, tipo de amortização (SAC, Price), taxa de juros (a.a.), LTV máximo (ex: 80%), prazo mínimo/máximo, idade máxima permitida.
   - `simulations`: ID, ID do usuário (opcional se anônimo), dados inseridos (valor do imóvel, entrada, renda, idade, prazo) e resultado final gerado.
3. Criar scripts de migração (`migrations`) e arquivo de `seed` para popular dados fictícios (ex: Banco do Brasil, Caixa Econômica, Itaú com taxas médias de financiamento).
4. Configurar testes de integração no Vitest para validar a inserção de usuários, busca de taxas ativas por banco e salvamento do histórico de simulações.

### DEV-FRONT
- *Nenhuma tarefa nesta Issue.* (Conforme as regras do PO, tarefas sem dependência visual direta podem deixar o DEV-FRONT livre ou em standby).

### QA
- Validar a execução das migrações e seeds em um ambiente local de testes (Docker/PostgreSQL local).
- Executar os testes de integração de banco de dados do Vitest e validar se todos passam.
- Verificar a integridade das relações e tipos de dados no banco modelado.

## Critérios de Aceite (Acceptance Criteria)
- As tabelas e chaves estrangeiras devem refletir a estrutura de dados mapeada para o MVP.
- O script `npm run db:migrate` (ou equivalente) deve rodar sem erros.
- O script `npm run db:seed` deve popular o banco com pelo menos 3 instituições financeiras e suas respectivas taxas de simulação.
- Devem existir testes de banco de dados que passem com 100% de sucesso.

## Definition of Done (DoD)
- Migrações, seeds e testes de banco implementados.
- Testes locais passando via terminal.
- QA validou e emitiu o relatório do BD.
- Código integrado e enviado para a branch `main`.

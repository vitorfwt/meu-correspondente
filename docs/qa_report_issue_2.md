# Relatório de QA - Issue #2: [Backend] Modelagem do Banco de Dados e Seeds de Teste

- **Data do Relatório**: 2026-07-05
- **Status da Validação**: **APROVADO** 🟢
- **Validador**: Agente QA (Antigravity)

---

## 1. Visão Geral
Este relatório apresenta a validação independente da implementação da **Issue #2**, que compreende a modelagem do banco de dados relacional PostgreSQL via **Prisma ORM**, a configuração de scripts de migração (`migrate dev`), o script de carga inicial de dados (`seed`), e os testes automatizados com o **Vitest**.

A validação foi executada diretamente contra a instância local do PostgreSQL rodando em Docker (container `meu-correspondente-db`).

---

## 2. Análise dos Arquivos do Repositório

### 2.1. [schema.prisma](file:///C:/repos/meu-correspondente/api/prisma/schema.prisma)
- Define a conexão com o banco e o uso do cliente JS.
- Mapeia com precisão todas as tabelas solicitadas com seus respectivos tipos e chaves estrangeiras.
- Adiciona boas práticas de exclusão referencial, como `onDelete: Cascade` para `InterestRate` e `onDelete: SetNull` para `SimulationHistory` (caso o usuário seja deletado).

### 2.2. [db.ts](file:///C:/repos/meu-correspondente/api/src/db.ts)
- Configura o cliente Prisma acoplado ao driver `pg` e seu `Pool`, permitindo o suporte adequado ao monorepo.
- Carrega as variáveis de ambiente utilizando o `dotenv`.

### 2.3. [seed.ts](file:///C:/repos/meu-correspondente/api/prisma/seed.ts)
- Limpa o banco de dados antes de executar (evitando duplicações).
- Cria 1 usuário de teste (`João Silva`).
- Cria as 3 instituições financeiras especificadas (`Caixa Econômica Federal`, `Banco do Brasil` e `Itaú Unibanco`) com suas respectivas tabelas de taxas SAC e Price (totalizando 6 registros de taxas).

### 2.4. [db.test.ts](file:///C:/repos/meu-correspondente/api/src/db.test.ts)
- Contém testes de integração reais cobrindo:
  - Inserção e busca de usuários.
  - Consulta de bancos e taxas ativas.
  - Persistência e associação de histórico de simulações com usuários e instituições.
- Garante limpeza dos dados criados durante os testes.

### 2.5. [package.json](file:///C:/repos/meu-correspondente/api/package.json)
- Configura corretamente os scripts:
  - `npm run test` -> `vitest run`
  - `npm run db:migrate` -> `prisma migrate dev`
  - `npm run db:seed` -> `tsx prisma/seed.ts`

---

## 3. Validação Estrutural do Banco de Dados
Foi executada uma consulta diagnóstica de metadados (`information_schema`) no banco PostgreSQL para validar a estrutura física gerada pelas migrações. Abaixo estão os resultados:

### 3.1. Tabelas Existentes no Schema `public`:
- `_prisma_migrations` (Controle do Prisma)
- `institutions`
- `interest_rates`
- `users`
- `simulations`

### 3.2. Estrutura da Tabela `users`
| Coluna | Tipo de Dado | Nulável? | Valor Padrão |
| :--- | :--- | :--- | :--- |
| `id` | `text` | Não | *Nenhum* |
| `name` | `text` | Não | *Nenhum* |
| `email` | `text` | Não | *Nenhum* (Unique index aplicado) |
| `role` | `text` | Não | *Nenhum* |
| `createdAt` | `timestamp without time zone` | Não | `CURRENT_TIMESTAMP` |

### 3.3. Estrutura da Tabela `institutions`
| Coluna | Tipo de Dado | Nulável? | Valor Padrão |
| :--- | :--- | :--- | :--- |
| `id` | `text` | Não | *Nenhum* |
| `name` | `text` | Não | *Nenhum* |
| `logoUrl` | `text` | Sim | *Nenhum* |
| `isActive` | `boolean` | Não | `true` |

### 3.4. Estrutura da Tabela `interest_rates`
| Coluna | Tipo de Dado | Nulável? | Valor Padrão |
| :--- | :--- | :--- | :--- |
| `id` | `text` | Não | *Nenhum* |
| `institutionId` | `text` | Não | *Nenhum* |
| `type` | `text` | Não | *Nenhum* |
| `rateValue` | `double precision` | Não | *Nenhum* |
| `maxLTV` | `double precision` | Não | *Nenhum* |
| `minTerm` | `integer` | Não | *Nenhum* |
| `maxTerm` | `integer` | Não | *Nenhum* |
| `maxAge` | `integer` | Não | *Nenhum* |

- **Chave Estrangeira**: `interest_rates_institutionId_fkey` apontando para `institutions.id`.

### 3.5. Estrutura da Tabela `simulations`
| Coluna | Tipo de Dado | Nulável? | Valor Padrão |
| :--- | :--- | :--- | :--- |
| `id` | `text` | Não | *Nenhum* |
| `userId` | `text` | Sim | *Nenhum* |
| `propertyValue` | `double precision` | Não | *Nenhum* |
| `downPayment` | `double precision` | Não | *Nenhum* |
| `monthlyIncome` | `double precision` | Não | *Nenhum* |
| `age` | `integer` | Não | *Nenhum* |
| `term` | `integer` | Não | *Nenhum* |
| `selectedInstitutionId` | `text` | Não | *Nenhum* |
| `resultMonthlyPayment` | `double precision` | Não | *Nenhum* |
| `status` | `text` | Não | *Nenhum* |
| `createdAt` | `timestamp without time zone` | Não | `CURRENT_TIMESTAMP` |

- **Chaves Estrangeiras**:
  - `simulations_userId_fkey` apontando para `users.id` (Nulável, atendendo o critério de simulações anônimas).
  - `simulations_selectedInstitutionId_fkey` apontando para `institutions.id`.

---

## 4. Evidências de Execução de Comandos e Testes

### 4.1. Execução de Migração (`npm run db:migrate`)
```bash
> api@1.0.0 db:migrate
> prisma migrate dev

Loaded Prisma config from prisma.config.ts.
Prisma schema loaded from prisma\schema.prisma.
Datasource "db": PostgreSQL database "meu_correspondente", schema "public" at "localhost:5432"

Already in sync, no schema change or pending migration was found.
```

### 4.2. Execução do Seeding (`npm run db:seed`)
```bash
> api@1.0.0 db:seed
> tsx prisma/seed.ts

Seeding database...
User created: João Silva
Institution created: Caixa Econômica Federal
Rates created for Caixa Econômica Federal
Institution created: Banco do Brasil
Rates created for Banco do Brasil
Institution created: Itaú Unibanco
Rates created for Itaú Unibanco
Database seeding finished successfully.
```

### 4.3. Execução dos Testes (`npm run test`)
```bash
> api@1.0.0 test
> vitest run

 RUN  v4.1.9 C:/repos/meu-correspondente/api

 ✓ src/smoke.test.ts (1 test) 2ms
 ✓ src/db.test.ts (3 tests) 369ms

 Test Files  2 passed (2)
      Tests  4 passed (4)
   Start at  01:49:28
   Duration  1.62s
```

---

## 5. Critérios de Aceite & Checklist de DoD

| Item / Critério | Requisito | Status | Observações |
| :--- | :--- | :---: | :--- |
| **CA #1** | Estrutura de tabelas e chaves reflete o planejado para o MVP | **OK** | Tabelas `users`, `institutions`, `interest_rates` e `simulations` criadas corretamente. |
| **CA #2** | Comando `npm run db:migrate` roda sem erros | **OK** | Migração executada com sucesso e sincronizada com banco. |
| **CA #3** | Comando `npm run db:seed` popula pelo menos 3 instituições e suas taxas | **OK** | Criou Caixa, Banco do Brasil, Itaú com taxas e um usuário. |
| **CA #4** | Testes de banco integrados passam com 100% de sucesso | **OK** | Todos os 4 testes de integração/fumaça executados e aprovados. |
| **DoD** | QA validou e emitiu o relatório do BD | **OK** | Este documento ([qa_report_issue_2.md](file:///C:/repos/meu-correspondente/docs/qa_report_issue_2.md)) foi gerado. |

---

## 6. Conclusão do QA
A modelagem física do banco de dados, o processo de migração, os dados iniciais do seed e a suíte de testes de integração cumprem rigorosamente com os requisitos da **Issue #2** definidos no plano de execução. 

A funcionalidade está **APROVADA** pelo QA para integração na branch principal (`main`).

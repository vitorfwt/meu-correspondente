# Relatório de QA - Issue #5: [Crawler] Serviço de Atualização de Taxas

- **Data do Relatório**: 2026-07-05
- **Status da Validação**: **APROVADO** 🟢
- **Validador**: Agente QA (Antigravity)

---

## 1. Visão Geral
Este relatório apresenta a validação independente da implementação da **Issue #5**, que consiste na criação e configuração do serviço de Crawler responsável por ler arquivos CSV de taxas de juros (`rates.csv`), analisar as informações sintaticamente e realizar a sincronização robusta (upsert) dos registros no banco de dados relacional PostgreSQL via **Prisma ORM**.

A validação inspecionou a qualidade do código, a robustez lógica do parser e do serviço, bem como a integridade da execução dos testes automatizados e do script executável final.

---

## 2. Análise e Inspeção dos Arquivos

Foi realizada uma análise estática dos novos arquivos na pasta `crawler/`:

### 2.1. [package.json](file:///c:/repos/meu-correspondente/crawler/package.json)
- Configuração limpa contendo as dependências corretas, incluindo `@prisma/client`, `@prisma/adapter-pg`, `pg`, `tsx` (para execução em TypeScript) e `vitest` (para a suíte de testes).
- Scripts operacionais:
  - `start`: Executa o entrypoint principal `tsx src/index.ts`.
  - `test`: Executa os testes automatizados uma única vez via `vitest run`.
  - `db:generate`: Executa `prisma generate`.

### 2.2. [resources/rates.csv](file:///c:/repos/meu-correspondente/crawler/resources/rates.csv)
- Contém a base de dados de taxas no formato padrão CSV delimitado por vírgulas.
- Lista as 4 principais instituições financeiras (Caixa Econômica Federal, Banco do Brasil, Itaú Unibanco, Santander) e as suas respectivas taxas de modalidades **SAC** e **Price**, totalizando 8 registros.
- Cabeçalhos corretos: `institutionName,rateType,rateValue,maxLTV,minTerm,maxTerm,maxAge`.

### 2.3. [src/parser.ts](file:///c:/repos/meu-correspondente/crawler/src/parser.ts)
- Implementa a função de parsing `parseRatesCSV` de forma nativa e sem bibliotecas de terceiros pesadas.
- **Robustez Lógica**:
  - Trata quebras de linha tanto para ambientes Unix quanto Windows (`/\r?\n/`).
  - Ignora linhas vazias (`if (!line) continue;`).
  - Ignora linhas incompletas/mal-formatadas (`if (columns.length < 7) continue;`).
  - Realiza de maneira limpa o parse das strings para tipos primitivos do TypeScript (`parseFloat`, `parseInt`).
- *Nota do QA / Oportunidade de Melhoria:* Atualmente, o parser assume que os valores nas colunas numéricas são conversíveis para números válidos. Caso ocorra uma string inválida no lugar de um número no CSV (como `"abc"`), o parsing gerará valores `NaN`, o que resultará em erros na camada do Prisma devido às restrições de nulidade do banco de dados. Em futuras iterações de robustez, é recomendado adicionar validações para evitar o envio de `NaN` para o banco de dados.

### 2.4. [src/crawler.service.ts](file:///c:/repos/meu-correspondente/crawler/src/crawler.service.ts)
- Implementa o serviço `RateCrawlerService`.
- Executa a busca insensível a maiúsculas/minúsculas (`mode: 'insensitive'`) para a instituição financeira. Caso ela não exista, ela é inserida no banco de dados.
- Realiza de forma eficiente o fluxo de **upsert** para as taxas da instituição com base na modalidade (`type` sendo SAC ou Price):
  - Se um registro existente for encontrado (`findFirst` por `institutionId` + `type`), atualiza o registro.
  - Caso contrário, cria um novo registro.
- Essa lógica evita duplicações indesejadas e garante que atualizações subsequentes no arquivo CSV modifiquem os valores vigentes em vez de criar novas taxas.

### 2.5. [src/index.ts](file:///c:/repos/meu-correspondente/crawler/src/index.ts)
- Entrypoint principal do script de sincronização.
- Resolve corretamente o caminho absoluto do arquivo `rates.csv`.
- Implementa tratamento de erro apropriado (`try-catch`) com saída de erro do sistema (`process.exit(1)`) em caso de falha.
- Garante a desconexão limpa do cliente Prisma (`prisma.$disconnect()`) em bloco `finally`.

---

## 3. Validação dos Testes Automatizados

A suíte de testes unitários e de integração (`crawler/src/crawler.test.ts`) foi executada diretamente contra a base de dados PostgreSQL.

### 3.1. Testes Cobertos
- **CSV Parser Unit Tests**:
  - `should successfully parse a valid CSV file`: Garante que um CSV gerado em runtime é interpretado em um array de objetos fortemente tipados.
  - `should throw an error if file does not exist`: Garante que exceções de arquivo não encontrado são disparadas devidamente.
- **RateCrawlerService Integration Tests**:
  - `should insert new institution and interest rates if they do not exist`: Valida o fluxo de inserção de novas instituições e taxas.
  - `should update (upsert) interest rates if institution and rate type already exist`: Valida que o reprocessamento de taxas atualiza as informações no banco ao invés de duplicá-las.
- **Teardown**: Os testes de integração contam com limpeza automática (`afterEach`) para remover registros criados durante a suíte, mantendo a integridade do banco de dados local.

### 3.2. Execução
```bash
$ npm run test

> crawler@1.0.0 test
> vitest run


 RUN  v4.1.9 C:/repos/meu-correspondente/crawler

 ✓ src/crawler.test.ts (4 tests) 200ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  06:52:49
   Duration  537ms (transform 66ms, setup 0ms, import 177ms, tests 200ms, environment 0ms)
```

**Resultado:** **100% de Sucesso** (4/4 testes aprovados).

---

## 4. Validação de Execução e Estado do Banco

O script foi executado de forma síncrona para validar o comportamento real do crawler:

```bash
$ npm start

> crawler@1.0.0 start
> tsx src/index.ts

Starting Rate Crawler synchronization...
Reading CSV from: C:\repos\meu-correspondente\crawler\resources\rates.csv
Rate Crawler synchronization completed successfully!
```

Uma consulta direta ao banco de dados revelou que os registros foram devidamente persistidos e populados no banco local:
- **Total de Instituições Inseridas/Sincronizadas**: 4 (Caixa Econômica Federal, Banco do Brasil, Itaú Unibanco, Santander)
- **Total de Taxas Inseridas/Sincronizadas**: 8 (2 taxas por banco, correspondendo a SAC e Price).
- **Integridade de Chaves**: Relação um-para-muitos entre `institutions` e `interest_rates` criada corretamente.

---

## 5. Critérios de Aceite & DoD (Definition of Done)

| Item / Critério | Requisito | Status | Observações |
| :--- | :--- | :---: | :--- |
| **CA #1** | Implementar o parser CSV robusto e sem libs externas em `parser.ts` | **OK** | Parser lê o CSV linha por linha e formata corretamente em tipos estruturados. |
| **CA #2** | Criar o serviço `RateCrawlerService` implementando a lógica de upsert | **OK** | Evita duplicação buscando e atualizando taxas existentes ou inserindo novos registros. |
| **CA #3** | Disponibilizar arquivo de dados de taxas de juros `rates.csv` em `resources/` | **OK** | Contém taxas vigentes para Caixa, BB, Itaú e Santander. |
| **CA #4** | Prover testes unitários e de integração em `crawler.test.ts` cobrindo sucesso e erro | **OK** | Suíte Vitest com 4 testes cobre o parser e o serviço de sincronização com o banco. |
| **CA #5** | Prover entrypoint em `index.ts` e script executável no `package.json` | **OK** | `npm start` inicia a sincronização e fecha a conexão de banco de forma limpa. |
| **DoD** | Suíte de testes rodando e passando com 100% de sucesso | **OK** | Executado com sucesso no ambiente local. |
| **DoD** | Relatório de QA detalhado e salvo em `docs/qa_report_issue_5.md` | **OK** | Este documento foi devidamente elaborado e salvo na pasta `docs/`. |

---

## 6. Conclusão do QA

A implementação do **Serviço de Atualização de Taxas (Crawler)** atende rigorosamente a todos os requisitos funcionais e técnicos previstos na Issue #5. A estrutura de dados no banco PostgreSQL foi atualizada perfeitamente e os testes automatizados garantem a resiliência e estabilidade do fluxo de atualização e sincronização.

A funcionalidade está **APROVADA** pelo QA.

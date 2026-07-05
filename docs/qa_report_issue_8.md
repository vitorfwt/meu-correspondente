# Relatório de QA (Quality Assurance) - Issue #8

## Identificação do Caso de Teste
* **Issue**: #8 - [App] Resultado e Restrições com Testes de Renderização
* **Objetivo**: Integrar o aplicativo Flutter com a API de simulação do backend, tratando restrições de crédito (renda comprometida e idade limite), exibição de loading/erro e testes de widget mockados.
* **Executor**: Agente QA (Equipe Meu Correspondente)
* **Data da Validação**: 2026-07-05
* **Status Geral**: ✅ **APROVADA**

---

## 1. Resumo da Execução de Testes Automatizados
A suíte de testes de widget e de unidade do frontend foi executada localmente na pasta `app/` utilizando o comando:
```bash
C:\src\flutter\bin\flutter.bat test
```

**Resultado dos Testes:**
* **Total de Testes:** 26
* **Passaram:** 26 (100% de sucesso)
* **Falharam:** 0

Os testes de widget em `simulation_result_screen_test.dart` e `simulator_form_screen_test.dart` passaram perfeitamente. Eles validaram com sucesso o comportamento do frontend sob dados mockados e contratos corrigidos:
1. Renderização correta dos cards dos bancos quando a chamada retorna dados normais.
2. Renderização das restrições de crédito (idade e renda) com bordas laranjas de espessura de 2px e opacidade reduzida a 0.45.
3. Exibição do spinner de loading.
4. Exibição de layout de erro e botão de tentar novamente (retry) funcionando.

---

## 2. Validação das Correções de Contrato e Regras

Após a correção das inconsistências apontadas no relatório anterior, as seguintes validações foram realizadas e confirmadas no código-fonte em `app/lib/simulation/simulation_repository.dart`:

### 1. Payload de Requisição (POST /api/simulate) em Inglês
* **Status**: ✅ **CORRIGIDO**
* **Detalhamento**: As chaves enviadas no corpo do JSON da requisição foram mapeadas para o inglês e seguem perfeitamente o contrato esperado pelo backend:
  - `propertyValue` mapeado de `input.valorImovel`
  - `downPayment` mapeado de `input.valorEntrada`
  - `monthlyIncome` mapeado de `input.rendaMensal`
  - `age` mapeado de `input.idade`
  - `term` mapeado de `input.prazoMeses`

### 2. Parse de Objetos Internos `sac` e `price`
* **Status**: ✅ **CORRIGIDO**
* **Detalhamento**: O método `BankSimulation.fromJson` agora extrai corretamente os dados estruturados de dentro das chaves aninhadas `sac` e `price` enviadas pelo backend:
  - Valores de juros e parcelas extraídos de `json['sac']` e `json['price']` dependendo da tabela de amortização.
  - Campos como `firstPayment`, `lastPayment` e `totalCost` são devidamente mapeados para suas respectivas variáveis no frontend.

### 3. Conversão de Taxas de Juros
* **Status**: ✅ **CORRIGIDO**
* **Detalhamento**: As taxas de juros anual e mensal recebidas do backend em formato decimal (ex: `0.09` para 9%) são multiplicadas por 100 para exibição correta em percentual no aplicativo (ex: `9.0%`):
  - `taxaJurosAnualVal = toDouble(sacJson['rateValue']) * 100` (ou do `priceJson`)
  - `taxaJurosMensalVal = toDouble(sacJson['monthlyRate']) * 100` (ou do `priceJson`)

### 4. Unificação de Restrições/Avisos (Warnings)
* **Status**: ✅ **CORRIGIDO**
* **Detalhamento**: Todos os avisos de restrição retornados pelo backend na raiz (`warnings`), no bloco do SAC (`sac.warnings`) e no bloco do PRICE (`price.warnings`) são fundidos em um único `Set<String>` (garantindo deduplicação) e repassados para a lista de `restricoes` do `BankSimulation`.

---

## 3. Insumos e Validação Visual

> [!NOTE]
> Devido a restrições do ambiente operacional atual (Antigravity Browser local não é suportado em Windows, apenas em Linux), não foi possível capturar capturas de tela dinâmicas em tempo de execução via subagente. Para mitigar isso, foi gerado um mockup visual com base nas especificações do layout visual de restrições de crédito.

O design de restrição exige que:
* **Bancos normais** sejam exibidos destacados e com tag de melhor opção caso aplicável.
* **Bancos com restrições** (idade limite ou comprometimento de renda) sejam renderizados com opacidade de **0.45**, borda de alerta na cor **laranja/vermelha** com largura **2.0px** e tags explicativas exibindo os avisos retornados de restrição.

Abaixo está o mockup representando o layout do card de simulação com restrição:

![Mockup do Card com Restrição de Crédito](file:///C:/Users/vitor/.gemini/antigravity/brain/b48eb623-f407-4e04-8f5d-618f48458135/simulation_restriction_mockup_1783229528826.jpg)

---

## 4. Conclusão da Validação de QA
Com base nos testes executados com sucesso e na verificação minuciosa do contrato da API (chaves de envio, parser de recebimento, conversão de juros e fusão de restrições), declaramos que a implementação da Issue #8 está **APROVADA** para integração em produção.

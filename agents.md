# DEPRECADO

> Este arquivo existe apenas para compatibilidade com versões antigas.

## IMPORTANTE

A partir desta versão, os agentes NÃO devem utilizar este arquivo como fonte de instruções.

Toda a configuração foi migrada para a pasta `.ai/`.

## Ordem de carregamento

1. `.ai/bootstrap.md`
2. `.ai/README.md`
3. `.ai/agents/`
4. `.ai/workflows/`
5. `.ai/rules/`
6. `.ai/templates/`
7. `.ai/memory/`

## Regras

- Ignore todo conteúdo antigo deste arquivo.
- Nunca utilize este arquivo como contexto operacional.
- Sempre utilize o Context Loader.
- Carregue apenas os documentos necessários.

# Relatório de QA - Issue #25: [Backend] API Endpoints (Profile, Partners, Indicators, Share)

**Status:** Aprovado ✅

## Detalhes da Validação

1. **Endpoints de Perfil (`/api/profile`):**
   * **`GET /api/profile`**: Validada a recuperação correta dos dados do usuário logado.
   * **`PUT /api/profile`**: Validada a atualização do perfil. Se o role for alterado para `broker`, a API exige CRECI (4-15 caracteres) e creciState/UF (2 caracteres), respondendo com `400 Bad Request` se os formatos forem inválidos ou ausentes.

2. **Endpoint de Parceiros (`GET /api/partners`):**
   * Confirmado o retorno de parceiros ativos (`isActive: true`), ordenados pelo nome de forma ascendente.
   * Campos retornados: `id`, `name`, `email`, `phone`, `company`, `photoUrl`.

3. **Endpoint de Indicadores (`GET /api/indicators`):**
   * Confirmada a recuperação de todos os indicadores da tabela do banco de dados (SELIC, IPCA, TR, POUPANCA).

4. **Endpoint de Compartilhamento (`POST /api/simulations/:id/share`):**
   * Validada a regra de autorização: apenas o dono da simulação ou um usuário com role `broker` pode disparar o compartilhamento da simulação (retorna `403 Forbidden` caso contrário).
   * Confirmado o retorno com resumo estruturado formatado (incluindo parcelas SAC/Price calculadas) e URL pública mockada.

5. **Testes de Integração (Vitest):**
   * Escritos 17 testes robustos no arquivo `api/src/new-endpoints.test.ts`.
   * Todos os testes de rotas cobrem autenticação JWT, validações e cenários de erro.
   * Executados na pasta `api/` com 100% de sucesso.

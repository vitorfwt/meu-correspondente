# Meu Correspondente

Plataforma de simulação de financiamento imobiliário. Compara taxas de múltiplos bancos em tempo real via SAC e PRICE, exibindo restrições de crédito, CET estimado e geração de proposta para compartilhamento.

## Estrutura do Monorepo

```
meu-correspondente/
├── api/          # Backend Node.js (TypeScript + Express + Prisma + PostgreSQL)
├── crawler/      # Scripts de extração de taxas de juros dos bancos
├── app/          # App mobile Flutter (Android / iOS)
├── docker-compose.yml
└── README.md
```

---

## Pré-requisitos

| Ferramenta | Versão mínima | Observação |
|---|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 4.x+ | Necessário para subir a API e o banco |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.x+ | Necessário para rodar o app |
| [Android Studio](https://developer.android.com/studio) | Koala+ | Necessário para o emulador Android |
| Node.js | 18+ | Opcional — apenas para rodar a API localmente sem Docker |

---

## 🐳 Subindo a API com Docker (Ambiente de Teste Integrado)

O `docker-compose.yml` na raiz do projeto sobe dois serviços:
- **`db`** — PostgreSQL 15 na porta `5432`
- **`api`** — Backend Node.js na porta `3000` (aguarda o banco, roda as migrations e o seed automaticamente)

### 1. Construir e subir os containers

Na raiz do repositório:

```bash
docker-compose up --build
```

> Na primeira execução, o processo pode levar alguns minutos para baixar as imagens e instalar as dependências.

Você verá no log algo como:

```
meu_correspondente_api  | Aguardando o banco de dados (db:5432) iniciar...
meu_correspondente_api  | Banco de dados disponível!
meu_correspondente_api  | Rodando as migrações do Prisma...
meu_correspondente_api  | Rodando o seed do banco de dados...
meu_correspondente_api  | Iniciando a API...
meu_correspondente_api  | Servidor rodando na porta 3000
```

### 2. Verificar se a API está no ar

```bash
curl http://localhost:3000/health
```

Ou abra no navegador: [http://localhost:3000/health](http://localhost:3000/health)

### 3. Parar os containers

```bash
docker-compose down
```

Para remover também o volume do banco de dados (reset completo):

```bash
docker-compose down -v
```

### 4. Recriar apenas a API (após mudanças no código)

```bash
docker-compose up --build api
```

---

## 📱 Rodando o App no Emulador Android

O app está configurado para detectar automaticamente o ambiente:

- **Emulador Android** → aponta para `http://10.0.2.2:3000` (loopback da máquina host)
- **iOS Simulator / Desktop** → aponta para `http://localhost:3000`

### 1. Criar e iniciar um emulador Android

No Android Studio: **Device Manager → Create Device → Pixel 8 → API 35** (ou superior).

Ou via linha de comando (se o Android SDK estiver configurado):

```bash
# Listar emuladores disponíveis
emulator -list-avds

# Iniciar o emulador
emulator -avd <nome_do_avd>
```

### 2. Instalar dependências do Flutter

```bash
cd app
flutter pub get
```

### 3. Verificar dispositivos conectados

```bash
flutter devices
```

Você deve ver o emulador Android listado, por exemplo:

```
sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x86_64 • Android 15
```

### 4. Rodar o app no emulador

```bash
flutter run
```

Para escolher um dispositivo específico:

```bash
flutter run -d emulator-5554
```

> **Importante:** Certifique-se de que os containers Docker estão rodando antes de iniciar o app. O app tentará se conectar à API em `http://10.0.2.2:3000` automaticamente no emulador.

---

## 🔄 Fluxo Completo de Teste Integrado

```bash
# Terminal 1 — Subir API + Banco
docker-compose up --build

# Terminal 2 — Iniciar o app no emulador
cd app && flutter run
```

1. No app, toque em **"Entrar com Google"** (mock em ambiente de desenvolvimento)
2. Navegue até a aba **"Simulações"**
3. Preencha os 3 passos do formulário e toque em **"Simular Financiamento"**
4. A tela de resultados exibirá as propostas vindas da API rodando no Docker

---

## 🧪 Rodando os Testes

### Testes do Backend (Unitários)

```bash
cd api
npm install
npm run test
```

### Testes do Frontend (Widget Tests)

```bash
cd app
flutter test
```

---

## 🛠️ Desenvolvimento Local da API (sem Docker)

Caso prefira rodar a API sem Docker, é necessário ter um PostgreSQL local:

```bash
# Configurar variável de ambiente
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/meu_correspondente?schema=public"

cd api
npm install

# Rodar migrations e seed
npx prisma migrate dev
npm run db:seed

# Iniciar o servidor
npm run start
```

---

## Variáveis de Ambiente

### API (`api/`)

| Variável | Padrão (Docker) | Descrição |
|---|---|---|
| `DATABASE_URL` | `postgresql://postgres:postgres@db:5432/meu_correspondente?schema=public` | URL de conexão com o PostgreSQL |
| `PORT` | `3000` | Porta em que a API escuta |

---

## Portas utilizadas

| Serviço | Porta |
|---|---|
| API (Node.js) | `3000` |
| PostgreSQL | `5432` |

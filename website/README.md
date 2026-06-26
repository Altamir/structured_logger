# Website

Site de documentação e blog do pacote **structured_logger**, gerado com [Docusaurus](https://docusaurus.io/).

**Produção:** [https://structured-logger.altamir.dev](https://structured-logger.altamir.dev)

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `../docs/` | Documentação em português (locale padrão) |
| `../docs/en/` | Documentação em inglês (**fonte canônica**) |
| `../docs/blog/` | Blog em português |
| `../docs/en/blog/` | Blog em inglês |
| `blog/` | Blog pt-BR gerado pelo sync |
| `i18n/en/` | Conteúdo en gerado pelo sync |
| `src/css/` | Tema customizado |
| `static/` | Assets estáticos (logo, social card) |

## Pré-requisitos

- Node.js 20
- npm

## Desenvolvimento

```bash
cd website
npm install
npm start
```

Abre em [http://localhost:3000/](http://localhost:3000/).

O comando `npm run build` (e `prebuild`) sincroniza:

- `docs/blog/` → `website/blog/` (pt-BR)
- `docs/en/` → `website/i18n/en/docusaurus-plugin-content-docs/current/`
- `docs/en/blog/` → `website/i18n/en/docusaurus-plugin-content-blog/`

Use o seletor de idioma na navbar para alternar entre **Português** e **English**.

## Build de produção

```bash
npm run build
npm run serve
```

## Deploy (Cloudflare Pages)

O workflow `.github/workflows/deploy-docs.yml` publica no **Cloudflare Pages** a cada push em `main` ou `master`.

### 1. Criar o projeto no Cloudflare

1. [Cloudflare Dashboard](https://dash.cloudflare.com) → **Workers & Pages** → **Create**
2. Escolha **Pages** → **Connect to Git** (opcional) ou crie projeto vazio com nome **`structured-logger`**
3. O deploy via GitHub Actions usa o mesmo nome de projeto

### 2. Secrets no GitHub

Em **Settings → Secrets and variables → Actions**, adicione:

| Secret | Onde obter |
|--------|------------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare → My Profile → API Tokens → Create Token → template **Edit Cloudflare Workers** (inclui Pages) |
| `CLOUDFLARE_ACCOUNT_ID` | `9da0c90849945330726c5272d56b74d8` (conta Altamir) |

Permissões mínimas do token: **Account → Cloudflare Pages → Edit**.

### 3. Domínio customizado

O domínio **`structured-logger.altamir.dev`** já foi registrado no projeto Pages.

Se ainda não resolver, confira o DNS em **Cloudflare → altamir.dev → DNS**:

| Tipo | Nome | Conteúdo | Proxy |
|------|------|----------|-------|
| CNAME | `structured-logger` | `structured-logger.pages.dev` | Ativado |

Ou em **Workers & Pages → structured-logger → Custom domains** → aguarde status **Active** (SSL pode levar alguns minutos).

### 4. Deploy manual (opcional)

```bash
cd website
npm run build
npx wrangler pages deploy build --project-name=structured-logger
```

Requer `wrangler login` ou `CLOUDFLARE_API_TOKEN` no ambiente.

### Build settings (se usar Git direto no Cloudflare)

Alternativa ao GitHub Actions — conectar o repo no Cloudflare Pages:

| Campo | Valor |
|-------|-------|
| Build command | `bash website/scripts/sync-content.sh && cd website && npm ci && npm run build` |
| Build output directory | `website/build` |
| Node.js version | `20` |
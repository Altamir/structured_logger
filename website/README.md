# Website

Site de documentação e blog do pacote **structured_logger**, gerado com [Docusaurus](https://docusaurus.io/).

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `../doc/` | Documentação (Markdown) |
| `../doc/blog/` | Posts do blog (**fonte canônica**) |
| `blog/` | Cópia gerada pelo sync (não editar manualmente) |
| `src/css/` | Tema customizado |
| `static/` | Assets estáticos (logo, social card) |

## Pré-requisitos

- Node.js 18+
- npm

## Desenvolvimento

```bash
cd website
npm install
npm start
```

Abre em [http://localhost:3000/structured_logger/](http://localhost:3000/structured_logger/).

O comando `npm run build` (e `prebuild`) sincroniza `doc/blog/` → `website/blog/` automaticamente.

## Build de produção

```bash
npm run build
npm run serve
```

## Deploy (GitHub Actions)

O workflow `.github/workflows/deploy-docs.yml` publica o site no GitHub Pages a cada push em `main` ou `master` que altere `doc/` ou `website/`.

### Configuração no repositório

1. **Settings → Pages → Build and deployment**
2. **Source:** GitHub Actions
3. Após o primeiro push com o workflow, o site ficará em:
   `https://altamir.github.io/structured_logger/`

### Deploy manual (opcional)

```bash
GIT_USER=<seu-usuario> npm run deploy
```
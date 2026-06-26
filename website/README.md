# Website

Site de documentação e blog do pacote **structured_logger**, gerado com [Docusaurus](https://docusaurus.io/).

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `../doc/` | Documentação em português (locale padrão) |
| `../doc/en/` | Documentação em inglês (**fonte canônica**) |
| `../doc/blog/` | Blog em português |
| `../doc/en/blog/` | Blog em inglês |
| `blog/` | Blog pt-BR gerado pelo sync |
| `i18n/en/` | Conteúdo en gerado pelo sync |
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

O comando `npm run build` (e `prebuild`) sincroniza:

- `doc/blog/` → `website/blog/` (pt-BR)
- `doc/en/` → `website/i18n/en/docusaurus-plugin-content-docs/current/`
- `doc/en/blog/` → `website/i18n/en/docusaurus-plugin-content-blog/`

Use o seletor de idioma na navbar para alternar entre **Português** e **English**.

## Build de produção

```bash
npm run build
npm run serve
```

## Deploy (GitHub Actions)

O workflow `.github/workflows/deploy-docs.yml` publica o site no GitHub Pages a cada push em `main` ou `master` que altere `doc/` ou `website/`.

### Configuração no repositório (obrigatório, uma vez)

1. Abra **Settings → Pages → Build and deployment**
2. Em **Source**, selecione **GitHub Actions** (não "Deploy from a branch")
3. Salve e rode o workflow novamente (**Actions → Deploy documentation → Run workflow**)

Sem esse passo o job `deploy` falha com `404` / "Ensure GitHub Pages has been enabled".

Após o deploy, o site ficará em: `https://altamir.github.io/structured_logger/`

### Deploy manual (opcional)

```bash
GIT_USER=<seu-usuario> npm run deploy
```
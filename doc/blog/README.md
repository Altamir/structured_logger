# Blog

Escreva os posts aqui. Antes do build (local ou CI), o script `website/scripts/sync-blog.sh` copia este conteúdo para `website/blog/`, que é o que o Docusaurus usa.

```bash
# manual
bash website/scripts/sync-blog.sh

# ou via npm (roda automaticamente no prebuild)
cd website && npm run build
```
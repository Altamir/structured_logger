# Blog (pt-BR)

Posts em português. Antes do build, `website/scripts/sync-content.sh` copia para `website/blog/`.

Posts em inglês ficam em `doc/en/blog/` e são sincronizados para `website/i18n/en/`.

```bash
bash website/scripts/sync-content.sh
# ou: cd website && npm run build
```
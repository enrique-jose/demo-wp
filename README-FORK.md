# demo-wp: fork de WordPress

Este repositorio es un **fork manual de [WordPress/WordPress](https://github.com/WordPress/WordPress)**, el mirror ya compilado de WordPress core. Se despliega en Cloud Run del proyecto `cool-academy-489503-f3`, sobre la infraestructura de [`enrique-jose/iac-wp-gcp-cicd`](https://github.com/enrique-jose/iac-wp-gcp-cicd).

- `main` parte de una **release** de WordPress (ahora **7.1.4**), no de `master`.
- Lo propio del fork está en `Dockerfile`, `.dockerignore`, `cloudbuild.yaml`, este archivo y el código que añadamos en `wp-content/` (temas, plugins y mu-plugins).

El `readme.html` original de WordPress no se ha modificado.

## CI/CD

Los triggers de Cloud Build están definidos en `iac-wp-gcp-cicd/bootstrap`:

| Trigger | Evento | Qué hace |
|---|---|---|
| `wp-cicd-app-pr` | PR a `main` | `php -l` sobre `wp-content/` y `docker build`. No sube ni despliega nada |
| `wp-cicd-app-deploy` | push a `main` | Lo mismo, más push a Artifact Registry y `gcloud run services update` por digest. Después hace un smoke test contra el LB y, **si falla, devuelve el tráfico a la revisión anterior** |

La imagen se basa en `wordpress:php8.3-apache` y sustituye su código por el del fork. Conserva el entrypoint oficial, que genera `wp-config.php` a partir de las variables `WORDPRESS_DB_*` y `WORDPRESS_CONFIG_EXTRA` que inyecta Terraform. Además incluye el plugin **Redis Object Cache** y el drop-in `object-cache.php`, que conectan con Memorystore for Valkey.

## Actualizar WordPress (sincronizar con upstream)

```bash
git fetch upstream --tags
git checkout -b upgrade/7.1.5 main
git merge 7.1.5            # tag de la release nueva
git push -u origin upgrade/7.1.5   # abrir PR → wp-cicd-app-pr valida el build
```

Al hacer merge del PR, `wp-cicd-app-deploy` despliega la versión nueva. Antes de actualizar a una versión mayor, revisa en el changelog de WordPress los cambios que afectan a la base de datos.

## Probar en local

```bash
docker build -t demo-wp .
docker run --rm -p 8080:80 -e WORDPRESS_DB_HOST=host.docker.internal \
  -e WORDPRESS_DB_USER=wp -e WORDPRESS_DB_PASSWORD=wp -e WORDPRESS_DB_NAME=wp demo-wp
```

#!/usr/bin/env bash
set -e

# 1) Démarrer le daemon Docker dans le Codespace (feature docker-in-docker)
sudo systemctl enable --now docker

# 2) Installer Composer via conteneur (pas besoin de PHP local)
if [ ! -d vendor ]; then
  docker run --rm -u $(id -u):$(id -g) \
    -v "$PWD":/app -w /app \
    composer:2 composer install --no-interaction --prefer-dist --ignore-platform-reqs || true
fi

# 3) Ajouter Sail si absent
if [ ! -f vendor/bin/sail ]; then
  docker run --rm -u $(id -u):$(id -g) \
    -v "$PWD":/app -w /app \
    composer:2 composer require laravel/sail --dev --no-interaction

  # Installer Sail (stack: mysql, redis, mailpit) sans prompt
  bash vendor/bin/sail artisan sail:install --with=mysql,redis,mailpit
fi

# 4) .env & clé app
if [ ! -f .env ]; then cp .env.example .env || touch .env; fi
grep -q '^APP_KEY=' .env || bash vendor/bin/sail artisan key:generate || true

# 5) Node deps dans le conteneur (vous pourrez aussi faire `sail npm run dev`)
bash vendor/bin/sail npm ci || bash vendor/bin/sail npm install

# 6) Lancer l'infra Docker
bash vendor/bin/sail up -d

# 7) Migrer
bash vendor/bin/sail artisan migrate --force || true

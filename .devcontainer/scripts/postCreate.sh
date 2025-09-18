#!/usr/bin/env bash
set -e

# 1) Dépendances système utiles
sudo apt-get update -y
sudo apt-get install -y zip unzip libzip-dev libpng-dev libonig-dev

# 2) Extensions PHP (pdo_mysql déjà là en général, on vérifie/assure)
php -m | grep -q pdo_mysql || sudo docker-php-ext-install pdo_mysql

# 3) Si le projet Laravel n'existe pas encore, on l'initialise
if [ ! -f artisan ]; then
  composer create-project laravel/laravel . "12.*" --no-interaction
fi

# 4) .env + APP_KEY + DB
cp -n .env.example .env
php artisan key:generate

# Configure DB pour le MySQL de la Feature
# (Codespaces: host = 127.0.0.1, port = 3306, user/pass = laravel/laravel)
php -r '
$env = file_get_contents(".env");
$env = preg_replace("/^DB_CONNECTION=.*/m", "DB_CONNECTION=mysql", $env);
$env = preg_replace("/^DB_HOST=.*/m", "DB_HOST=127.0.0.1", $env);
$env = preg_replace("/^DB_PORT=.*/m", "DB_PORT=3306", $env);
$env = preg_replace("/^DB_DATABASE=.*/m", "DB_DATABASE=laravel", $env);
$env = preg_replace("/^DB_USERNAME=.*/m", "DB_USERNAME=laravel", $env);
$env = preg_replace("/^DB_PASSWORD=.*/m", "DB_PASSWORD=laravel", $env);
file_put_contents(".env", $env);
'

# 5) Node/Vite
if [ -f package.json ]; then
  npm ci || npm install
else
  npm init -y
  npm install
fi

# 6) Migrations de base (silencieux si rien à migrer)
php artisan migrate --force || true

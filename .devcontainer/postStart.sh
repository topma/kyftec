#!/usr/bin/env bash
set -e

# S'assurer que Docker tourne (au cas où)
sudo systemctl is-active --quiet docker || sudo systemctl start docker

# Démarrer l'app si arrêtée
bash vendor/bin/sail up -d || true

# Vite HMR (optionnel, si pas déjà en dev ailleurs)
pgrep -f "vite" >/dev/null || bash vendor/bin/sail npm run dev >/tmp/vite.log 2>&1 &

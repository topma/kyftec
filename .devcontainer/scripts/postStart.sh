#!/usr/bin/env bash
set -e

# Vite en Codespaces : host public + HMR ok
# On patch vite.config.ts/js si présent pour le HMR
if [ -f vite.config.ts ] || [ -f vite.config.js ]; then
  node - <<'NODE'
const fs = require('fs');

function patch(file) {
  if (!fs.existsSync(file)) return;
  let c = fs.readFileSync(file, 'utf8');
  if (!/server:\s*{/.test(c)) {
    c = c.replace(/defineConfig\(\{\s*/m, m => m + `server: { host: true, hmr: { clientPort: 443 } },\n`);
  } else if (!/hmr:/.test(c)) {
    c = c.replace(/server:\s*{[^}]*}/m, (m)=> m.replace(/}$/, `, hmr: { clientPort: 443 } }`));
  }
  fs.writeFileSync(file, c);
  console.log(file + ' patched for Codespaces HMR.');
}
patch('vite.config.ts');
patch('vite.config.js');
NODE
fi

# Lancer Laravel + Vite si pas déjà en cours
pgrep -f "php artisan serve" >/dev/null || (php artisan serve --host 0.0.0.0 --port 8000 >/tmp/laravel.log 2>&1 &)
pgrep -f "vite" >/dev/null || (npm run dev >/tmp/vite.log 2>&1 &)

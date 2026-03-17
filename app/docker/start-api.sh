#!/bin/sh

set -eu

if [ ! -d node_modules ] || [ -z "$(ls -A node_modules 2>/dev/null)" ]; then
  npm ci
fi

npx prisma generate
npx prisma migrate deploy
exec npx nx serve api
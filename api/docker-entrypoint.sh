#!/bin/sh
set -e

echo "Aguardando o banco de dados (db:5432) iniciar..."
while ! nc -z db 5432; do
  sleep 1
done
echo "Banco de dados disponível!"

echo "Rodando as migrações do Prisma..."
npx prisma migrate deploy

echo "Rodando o seed do banco de dados..."
npm run db:seed

echo "Iniciando a API..."
exec npm run start

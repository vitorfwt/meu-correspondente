#!/bin/sh

echo "Aguardando o banco de dados (db:5432) iniciar..."
until nc -z db 5432; do
  sleep 1
done
echo "Banco de dados disponível!"

echo "Rodando as migrações do Prisma..."
npx prisma migrate deploy
if [ $? -ne 0 ]; then
  echo "AVISO: Falha nas migrações, tentando continuar..."
fi

echo "Rodando o seed do banco de dados..."
npm run db:seed || echo "AVISO: Seed falhou ou já foi executado, continuando..."

echo "Iniciando a API..."
exec npm run start

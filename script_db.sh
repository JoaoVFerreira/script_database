#!/bin/bash

# Variavies
POSTGRES_CONTAINER_NAME="testesDinheirow"
POSTGRES_DB="postgres"
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="admin123"
DUMP_FILE="$1"

# Verificar se o arquivo de dump foi especificado
if [ -z "$DUMP_FILE" ]; then
    echo "O caminho do arquivo de dump não foi especificado."
    exit 1
fi

# Verificar se o arquivo de dump existe
if [ ! -f "$DUMP_FILE" ]; then
    echo "O arquivo de dump '$DUMP_FILE' não existe."
    exit 1
fi

# Verificar se o container já está em execução
if [ "$(docker ps -aq -f name=$POSTGRES_CONTAINER_NAME)" ]; then
    echo "O container $POSTGRES_CONTAINER_NAME já está em execução. Interrompendo e excluindo..."
    docker stop $POSTGRES_CONTAINER_NAME
    docker rm $POSTGRES_CONTAINER_NAME
fi

# Verificar se o container já existe
if [ "$(docker ps -aq -f name=$POSTGRES_CONTAINER_NAME)" ]; then
    echo "O container $POSTGRES_CONTAINER_NAME já existe."
else
    # Criar e iniciar um novo container
    echo "Criando e iniciando o container $POSTGRES_CONTAINER_NAME..."
    docker run -d --name $POSTGRES_CONTAINER_NAME -e POSTGRES_DB=$POSTGRES_DB -e POSTGRES_USER=$POSTGRES_USER -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD -p 5432:5432 postgres:12
fi

# Aguardar um breve período de tempo para garantir que o servidor PostgreSQL esteja em execução
echo "Aguardando o servidor PostgreSQL iniciar..."
sleep 5

echo "Copiando o dump de dados $DUMP_FILE..."
docker cp $DUMP_FILE $POSTGRES_CONTAINER_NAME:/schema

echo "Migrando as informações para o banco de dados $POSTGRES_DB..."
sleep 5
docker exec $POSTGRES_CONTAINER_NAME pg_restore -d $POSTGRES_DB schema -c -U $POSTGRES_USER

if echo "$DUMP_FILE" | grep -q "dev"; then

    sleep 5
    echo "Rodando migration para o dump $DUMP_FILE"
    npx sequelize-cli db:migrate

    sleep 5
    echo "Rodando seeds para o dump $DUMP_FILE"
    npx sequelize-cli db:seed:all
else
    echo "Rodando migration para o dump $DUMP_FILE"
    npx sequelize-cli db:migration
fi
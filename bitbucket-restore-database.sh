#!/bin/bash

BITBUCKET_BACKUPS_CONTAINER=$(docker ps -aqf "name=bitbucket_backups")

echo "--> All available database backups:"

for entry in $(docker container exec -it $BITBUCKET_BACKUPS_CONTAINER sh -c "ls /srv/bitbucket-postgres/backups/")
do
  echo "$entry"
done

echo "--> Copy and paste the backup name from the list above to restore database and press [ENTER]
--> Example: bitbucket-postgres-backup-YYYY-MM-DD_hh-mm.gz"
echo -n "--> "

read SELECTED_DATABASE_BACKUP

echo "--> $SELECTED_DATABASE_BACKUP was selected"

echo "--> Scaling service down..."
docker service scale bitbucket_bitbucket=0

echo "--> Restoring database..."
docker exec -it $BITBUCKET_BACKUPS_CONTAINER sh -c 'PGPASSWORD="$(cat $POSTGRES_PASSWORD_FILE)" dropdb -h postgres -p 5432 bitbucketdb -U bitbucketdbuser \
&& PGPASSWORD="$(cat $POSTGRES_PASSWORD_FILE)" createdb -h postgres -p 5432 bitbucketdb -U bitbucketdbuser \
&& PGPASSWORD="$(cat $POSTGRES_PASSWORD_FILE)" gunzip -c /srv/bitbucket-postgres/backups/'$SELECTED_DATABASE_BACKUP' | PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -h postgres -p 5432 bitbucketdb -U bitbucketdbuser'
echo "--> Database recovery completed..."

echo "--> Scaling service up..."
docker service scale bitbucket_bitbucket=1

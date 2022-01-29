#! /bin/bash

# exit dès que qqch se passe mal
set -e
# sortir si "unbound variable"
#set -u


if [ -z "$1" ]
  then
    echo "Pas de millésime en argument --> stop"
    exit 1
fi

# lecture du fichier de configuration
. config.sh



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Sauvegarde de données pour la BD Redadeg $millesime"
echo ""

# la date du jour
#declare -a ladate=`date +"%Y.%m.%d"`
ladate=$(date +%Y-%m-%d)

# on se déplace
cd $rep_data/backup/

# le répertoire de destination
backup_item=${DB_NAME}_${ladate}

# nettoyage au cas où
rm -rf $backup_item

# création du répertoire avec la date
mkdir $backup_item

Tables=(
  "secteur"
  "phase_1_trace"
  "phase_2_pk_secteur"
  "phase_2_point_nettoyage"
  "phase_2_trace_pgr"
  "phase_2_trace_troncons"
  "phase_3_pk"
  "public.phase_5_pk"
)

for table in ${Tables[@]}; do
  
  echo ">> $table"

  PGPASSWORD=$DB_PASSWD pg_dump --file "$backup_item/$table.sql" \
    --host "$DB_HOST" --port "$DB_PORT" --username "$DB_USER" --no-password \
    --format=p --data-only --no-owner --no-privileges \
    --table "public.$table" "$DB_NAME"

  echo "fait"

done

echo ""
echo "zip du répertoire"

src=$backup_item
zip_file="$backup_item.zip"
zip -qr ${zip_file} ${src}

# on supprime le répertoire
rm -rf $backup_item

echo "fait"

echo ""
echo "FIN"


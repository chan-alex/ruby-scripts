#!/bin/bash


# A simple bash script for performing mysqldump backups. To be run from a slave.

BACKUP_DIR="/extra_storage/backups/mysqldump"
IGNORE_DB="'information_schema', 'performance_schema', 'sys'"   #Part of SQL. Comma and quotes important.

# --dump-slave=2 is for PITR. "2" sets encloses the info in SQL comments.
MYSQL_DUMP_OPTS="--opt  --set-gtid-purged=OFF  --single-transaction  --hex-blob --complete-insert --triggers --routines --events --dump-slave=2"   
TAG="MYSQLDUMP"   # for tagging syslog messages.
FILE_PREFIX="westus_"  # for prefixing backup files.


## start backup ##
function msg() {
  echo $1
  logger -t ${TAG} $1  # log to syslog.
}


if [ ! -d "${BACKUP_DIR}" ]; then
  msg "${BACKUP_DIR} does seem to exist. Exiting."
  exit 1
fi

## cleanup older than 1 month ##
msg "Purging old files at ${BACKUP_DIR}"
find ${BACKP_DIR}  -mtime +30 -exec rm -f {} \;



# Start mysqldump backup.

dbs=`mysql -Bse "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME NOT IN (${IGNORE_DB});\G"`

for db in $dbs
do
    msg "Backing up ${db} schema."
    
    NOW="$(date +"%d-%m-%Y")"
    DUMPFILE="${BACKUP_DIR}/${FILE_PREFIX}${db}.${NOW}.sql"
    CMD="mysqldump --defaults-file=/root/.my.cnf ${MYSQL_DUMP_OPTS} ${db}"

    echo "-- MySQL dump started on  $(date +'%d-%m-%Y %H%Mhrs')" >> ${DUMPFILE}
    echo "-- Command = ${CMD} "  >> ${DUMPFILE}
    echo " "  >> ${DUMPFILE}
    ${CMD} >> ${DUMPFILE}

    gzip ${DUMPFILE}
    
    SCHEMAFILE="${BACKUP_DIR}/${FILE_PREFIX}${db}_schema.${NOW}.sql"
    mysqldump --defaults-file=/root/.my.cnf --no-data --routines  --triggers --events  ${db} > ${SCHEMAFILE}

    msg "Done backing up ${db} schema."
done

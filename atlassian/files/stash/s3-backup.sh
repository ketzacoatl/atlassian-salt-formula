{%- set version = '3.7.1' %}
{%- set app = 'stash' %}

{%- set db_user = salt['pillar.get']('atlassian:stash:db:user', 'stash') %}
{%- set db_pass = salt['pillar.get']('atlassian:stash:db:pass', 'stash') %}
{%- set db_name = salt['pillar.get']('atlassian:stash:db:name', 'stash') %}
{%- set db_host = salt['pillar.get']('atlassian:stash:db:host', 'localhost') %}

{%- set home_dir = '/opt/atlassian/stash/current' %}
{%- set data_dir = '/opt/atlassian/stash/data' %}

{%- set aws_creds = '/usr/local/etc/bucket-info.csv' %}

#!/bin/bash
### DB Config
NOW=$(date +"%Y%m%d_%H%M%S" -u)
VER={{ version }}
APP={{ app }}
FILE=$APP.$VER.$NOW.sql.xz
DB_USER={{ db_user }}
DB_PASS="{{ db_pass }}"
DB_NAME={{ db_name }}
DB_HOST={{ db_host }}
export PGPASSWORD=$DB_PASS

### DIR Config
HOME={{ home_dir }}
DATA={{ data_dir }}
BACKUPDIR="$APP.$VER.$NOW"

### AWS Config
AWS_CREDS={{ aws_creds }}
export AWS_DEFAULT_REGION=$(awk -F "," '{print $1}' $AWS_CREDS)
S3_BASE=$(awk -F "," '{print $2}' $AWS_CREDS)
S3_PATH="$S3_BASE/$APP/"
export AWS_ACCESS_KEY_ID=$(awk -F "," '{print $3}' $AWS_CREDS)
export AWS_SECRET_ACCESS_KEY=$(awk -F "," '{print $4}' $AWS_CREDS)

### Exec
echo "Creating backup directory: $BACKUPDIR"
mkdir -p $BACKUPDIR/home $BACKUPDIR/data
echo "Copying $HOME to $BACKUPDIR/home"
cp -r $HOME/* $BACKUPDIR/home/.
echo "Copying $HOME to $BACKUPDIR/home: Done!"
echo "Copying $DATA to $BACKUPDIR/data"
cp -r $DATA/* $BACKUPDIR/data/.
echo "Copying $DATA to $BACKUPDIR/data: Done!"
echo "Dumping database, $DB_NAME, to $BACKUPDIR/$FILE"
pg_dump -U $DB_USER -d $DB_NAME -h $DB_HOST | xz > $BACKUPDIR/$FILE
echo "Dumping database, $DB_NAME, to $BACKUPDIR/$FILE: Done!"
echo "Archiving and compressing $BACKUPDIR to $BACKUPDIR.tar.xz"
tar c $BACKUPDIR | xz > $BACKUPDIR.tar.xz
echo "Archiving and compressing $BACKUPDIR to $BACKUPDIR.tar.xz: Done!"
echo "Moving $BACKUPDIR.tar.xz to $S3_PATH"
aws s3 mv $BACKUPDIR.tar.xz $S3_PATH
echo "Moving $BACKUPDIR.tar.xz to $S3_PATH: Done!"
rm -rf $BACKUPDIR
echo "Backup complete!"

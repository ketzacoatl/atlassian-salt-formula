{%- set version = '7.1.0' %}
{%- set app = 'jira' %}

{%- set db_user = salt['pillar.get']('atlassian:jira:db:user', 'jira') %}
{%- set db_pass = salt['pillar.get']('atlassian:jira:db:pass', 'jira') %}
{%- set db_name = salt['pillar.get']('atlassian:jira:db:name', 'jira') %}
{%- set db_host = salt['pillar.get']('atlassian:jira:db:host', 'localhost') %}

{%- set home_dir = '/opt/atlassian/jira/current' %}
{%- set data_dir = '/opt/atlassian/jira/data' %}

{%- set aws_creds = '/usr/local/etc/bucket-info.csv' %}

#!/bin/bash
FILE=$1 #specify the backup to restore from

### DB Config
APP={{ app }}
DB_USER={{ db_user }}
DB_PASS="{{ db_pass }}"
DB_NAME={{ db_name }}
DB_HOST={{ db_host }}
export PGPASSWORD=$DB_PASS

### DIR Config
HOME={{ home_dir }}
DATA={{ data_dir }}

### AWS Config
AWS_CREDS={{ aws_creds }}
export AWS_DEFAULT_REGION=$(awk -F "," '{print $1}' $AWS_CREDS)
S3_BASE=$(awk -F "," '{print $2}' $AWS_CREDS)
S3_PATH="$S3_BASE/$APP/"
export AWS_ACCESS_KEY_ID=$(awk -F "," '{print $3}' $AWS_CREDS)
export AWS_SECRET_ACCESS_KEY=$(awk -F "," '{print $4}' $AWS_CREDS)

### Exec
TAR=${FILE%.*}
DIR=${TAR%.*}
echo "Copying $S3_PATH$FILE to local directory"
aws s3 cp $S3_PATH$FILE .
echo "Copying $S3_PATH$FILE to local directory: Done!"
echo "Uncompressing and unarchiving $FILE"
tar xf $FILE
echo "Uncompressing and unarchiving $FILE: Done!"
echo "Stopping $APP"
service $APP stop
echo "Stopping $APP: Done!"
#If database exists, destroy it (you have a backup after all)
if bash -c 'sudo -u postgres psql -c "\l" | grep $APP' > /dev/null;
  then
      echo "Dropping database: $DB_NAME"
      sudo -u postgres dropdb $DB_NAME
      echo "Dropping database: $DB_NAME: Done!"
fi
echo "Creating database: $DB_NAME"
salt-call --local state.sls atlassian.$APP.db
echo "Creating database: $DB_NAME: Done!"
echo "Restoring database: $DB_NAME"
xzcat $DIR/$DIR.sql.xz | psql -U $DB_USER -d $DB_NAME -h $DB_HOST
echo "Restoring database: $DB_NAME: Done!"
echo "Restoring home directory"
cp -r $DIR/home/* $APP_HOME
echo "Restoring home directory: Done!"
echo "Restoring data directory"
cp -r $DIR/data/* $APP_DATA
echo "Restoring data directory: Done!"
echo "Starting $APP"
service $APP start
echo "Starting $APP: Done!"
rm -rf $DIR
echo "Restoration complete!"
{%- set version = '3.7.1' %}
{%- set app = 'stash' %}

{%- set home_dir = '/opt/atlassian/stash/current' %}
{%- set data_dir = '/opt/atlassian/stash/data' %}

{%- set aws_creds = '/usr/local/etc/bucket-info.csv' %}

#!/bin/bash
FILE=$1 #specify the backup to restore from

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
#echo "Restoring home directory"
#cp -r $DIR/home/* $APP_HOME
#echo "Restoring home directory: Done!"
echo "Restoring data directory"
cp -r $DIR/data/* $APP_DATA
echo "Restoring data directory: Done!"
rm -rf $DIR
echo "Migrate complete!"
echo "===Next steps==="
echo "1. Delete app and plugin caches"
echo "2. Configure dbconfig.xml if database was changed"
echo "3. Start $APP again"

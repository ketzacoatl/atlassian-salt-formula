#!/bin/bash
# S3 Backup/Restore Tool for Atlassian Suite
### General Config
APP={{ app }}
VER={{ version }}
ENV={{ deploy_env }}

### DB Config
DB_USER={{ db_user }}
DB_PASS='{{ db_pass }}'
DB_NAME={{ db_name }}
DB_HOST={{ db_host }}

### DIR Config
APP_HOME={{ app_home }}
APP_DATA={{ app_data }}
TEMP_DIR={{ temp_dir }}

### S3 Config
BUCKET={{ s3_bucket }}
PROFILE={{ s3_profile }}
S3_PATH="s3://$BUCKET/$ENV"


function backup {
    ### File Config
    NOW=$(date +"%Y%m%d_%H%M%S" -u)
    DB_BACKUP=$APP.$VER.$NOW.sql.xz
    BACKUPDIR="$APP.$VER.$NOW"
    ARCHIVE="$BACKUPDIR.tar.xz"

    ### DB Config
    export PGPASSWORD=$DB_PASS

    ### Exec
    echo "Beginning $APP Backup: $NOW"
    echo "Operating out of $TEMP_DIR"
    mkdir -p $TEMP_DIR
    cd $TEMP_DIR
    echo "Creating backup directory: $BACKUPDIR"
    mkdir -p $BACKUPDIR/home $BACKUPDIR/data
    echo "Copying $APP_HOME to $BACKUPDIR/home"
    cp -r $APP_HOME/* $BACKUPDIR/home/.
    echo "Copying $APP_HOME to $BACKUPDIR/home: Done!"
    echo "Copying $APP_DATA to $BACKUPDIR/data"
    cp -r $APP_DATA/* $BACKUPDIR/data/.
    echo "Copying $APP_DATA to $BACKUPDIR/data: Done!"
    echo "Dumping database, $DB_NAME, to $BACKUPDIR/$DB_BACKUP"
    pg_dump -U $DB_USER -d $DB_NAME -h $DB_HOST | xz > $BACKUPDIR/$DB_BACKUP
    echo "Dumping database, $DB_NAME, to $BACKUPDIR/$DB_BACKUP: Done!"
    echo "Archiving and compressing $BACKUPDIR to $ARCHIVE"
    tar c $BACKUPDIR | xz > $ARCHIVE
    echo "Archiving and compressing $BACKUPDIR to $ARCHIVE: Done!"
    echo "Moving $ARCHIVE to $S3_PATH/$ARCHIVE"
    aws s3 mv $ARCHIVE $S3_PATH/$ARCHIVE --profile $PROFILE
    echo "Moving $ARCHIVE to $S3_PATH/$ARCHIVE: Done!"
    rm -rf $BACKUPDIR
    echo "Backup complete!"
}

function restore {
    ### DB Config
    export PGPASSWORD=$DB_PASS

    ### Exec
    echo "Beginning restore of $APP using $FILE"
    echo "Operating out of $TEMP_DIR"
    mkdir -p $TEMP_DIR
    cd $TEMP_DIR
    TAR=${FILE%.*}
    DIR=${TAR%.*}
    echo "Copying $S3_PATH/$FILE to $TEMP_DIR"
    aws s3 cp $S3_PATH/$FILE . --profile $PROFILE
    echo "Copying $S3_PATH/$FILE to local directory: Done!"
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
    rm -rf $DIR
    echo "Restoration complete!"
    echo "===Next steps==="
    echo "1. Delete app and plugin caches"
    echo "2. Start $APP again"
}

function migrate {
    ### Exec
    echo "Beginning restore of $APP using $FILE"
    echo "Operating out of $TEMP_DIR"
    mkdir -p $TEMP_DIR
    cd $TEMP_DIR
    TAR=${FILE%.*}
    DIR=${TAR%.*}
    echo "Copying $S3_PATH/$FILE to $TEMP_DIR"
    aws s3 cp $S3_PATH/$FILE . --profile $PROFILE
    echo "Copying $S3_PATH/$FILE to local directory: Done!"
    echo "Uncompressing and unarchiving $FILE"
    tar xf $FILE
    echo "Uncompressing and unarchiving $FILE: Done!"
    echo "Stopping $APP"
    service $APP stop
    echo "Stopping $APP: Done!"
    echo "Restoring data directory"
    cp -r $DIR/data/* $APP_DATA
    echo "Restoring data directory: Done!"
    rm -rf $DIR
    echo "Migrate complete!"
    echo "===Next steps==="
    echo "1. Delete app and plugin caches"
    echo "2. Configure dbconfig.xml if database was changed"
    echo "3. Start $APP again"
}

# Loop through command-line flags and collect values
while [[ $# > 0 ]]
do
key="$1"

case $key in
    -m|--mode) # specify mode: backup, restore or migrate
    MODE="$2"
    shift
    ;;
    -f|--file) # specify a backup file when restoring
    FILE="$2"
    shift
    ;;
    *)
    ;;
esac
shift
done

if [ -z "$MODE" ]; then
    echo "Set flag -m|--mode to specify mode: backup, restore or migrate"
    exit
fi

# Evaluate mode
case $MODE in
    backup)
        backup
    ;;
    restore)
        if [ -z "$FILE" ]; then
            echo "Use flag -f|--file to specify a file to restore from"
            exit
        else
            restore
        fi
    ;;
    migrate)
        if [ -z "$FILE" ]; then
            echo "Use flag -f|--file to specify a file to restore from"
            exit
        else
            migrate
        fi
    ;;
esac

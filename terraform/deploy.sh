#!/bin/bash

set -x

INGEST_FILE='ingest'
ETL_FILE='etl'
CURR_DIR=$(pwd)

pip install virtualenv
   

function create_zip(){
    PYTHON_FILE=$1
    rm -rf $PYTHON_FILE
    mkdir -p $PYTHON_FILE
    virtualenv -p python3 $PYTHON_FILE >> /dev/null
    source $PYTHON_FILE/bin/activate 
    pip install boto3 >> /dev/null
    deactivate >> /dev/null
    cp lambda/$PYTHON_FILE.py $PYTHON_FILE/lib/python3.6/site-packages/
    cd $PYTHON_FILE/lib/python3.6/site-packages
    zip -r9 $PYTHON_FILE.zip * >> /dev/null
    cp $PYTHON_FILE.zip $CURR_DIR/
    cd $CURR_DIR
    rm -rf $PYTHON_FILE
}

create_zip $INGEST_FILE
create_zip $ETL_FILE

docker run --net=host ubuntu:16.04 \
       -
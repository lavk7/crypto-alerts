#!/bin/bash

while getopts "s:" arg; do
  case $arg in
    s)
      echo $OPTARG
      S3_BUCKET=$OPTARG
      ;;
  esac
done

echo "Using bucket as $S3_BUCKET"
set -x
function deploy(){
    [ -z "$S3_BUCKET" ] &&  echo 'S3 BUCKET not provided' && exit 1
    sed -i "s/default =.*/default = \"$S3_BUCKET\"/g" main.tf
    INGEST_FILE='ingest'
    ETL_FILE='etl'
    CURR_DIR=$(pwd)

    pip install virtualenv
    

    create_zip $INGEST_FILE
    create_zip $ETL_FILE

    [ ! "$(docker ps -a | grep crypto-alert)" ] || docker rm -f crypto-alert

    [ -f terraform/terraform.zip ] && rm terraform/terraform.zip
    curl https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip --output terraform.zip
    unzip -o terraform.zip
    docker run -d -t --net=host --name=crypto-alert \
        -v $(pwd):/data \
        -v $(dirname ~/$(whoami))/.aws/credentials:/root/.aws/credentials \
        ubuntu:16.04 \
        /bin/sh /data/entrypoint.sh
}

function create_zip(){
    PYTHON_FILE=$1
    rm -rf $PYTHON_FILE
    mkdir -p $PYTHON_FILE
    virtualenv -p python3 $PYTHON_FILE >> /dev/null
    source $PYTHON_FILE/bin/activate 
    pip install boto3 >> /dev/null
    SITE_DIR=$(python -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib())')
    cp lambda/$PYTHON_FILE.py $SITE_DIR
    cd $SITE_DIR
    zip -r9 $PYTHON_FILE.zip * >> /dev/null
    cp $PYTHON_FILE.zip $CURR_DIR/
    cd $CURR_DIR
    deactivate >> /dev/null
    rm -rf $PYTHON_FILE
}

function destroy(){
    docker exec -it crypto-alert /bin/sh -c "cd data; terraform init; terraform destroy -auto-approve"
}

function apply(){
    docker exec -it crypto-alert /bin/sh -c "cd data; terraform init;  terraform apply -auto-approve"
}

echo "$@"
for arg in "$@"; do
        case $arg in
        "deploy")
                deploy
                ;;
        "destroy")
                destroy
                ;;
        "update")
                apply
                ;;
        esac
done


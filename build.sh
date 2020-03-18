#!/bin/bash
cd $(dirname $0)
SCRIPT_DIR=$(pwd)

echo "Cleaning build folder"
rm -rf $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build

echo "Creating BYOL stack"
folder=$(mktemp -d "cloudera-XXXXX")

mkdir -p $folder
cd $folder
cp $SCRIPT_DIR/*.tf .
cp $SCRIPT_DIR/*.yaml .
cp -R $SCRIPT_DIR/modules/ .
cp -R $SCRIPT_DIR/scripts/ .
rm -rf .terraform
ls -la
zip -r $SCRIPT_DIR/build/cloudera-byol.zip *
cd $SCRIPT_DIR
rm -rf $folder
ls -la $SCRIPT_DIR/build

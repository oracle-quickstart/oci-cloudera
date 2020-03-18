#!/bin/bash
cd $(dirname $0)
SCRIPT_DIR=$(pwd)

echo "-->Cleaning build folder"
rm -rf $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build

echo "-->Creating BYOL stack"
folder=$(mktemp -d "cloudera-XXXXX")
mkdir -p $folder
cd $folder
echo "-->Copying Terraform stack"
rsync -apxrv $SCRIPT_DIR/ --exclude=build --exclude=.github --exclude=.git --exclude=$folder .
echo "-->Cleanup .terraform"
rm -rf .terraform
echo "-->Showing contents of build root:"
ls -la
echo "-->Creating ZIP archive"
zip -r $SCRIPT_DIR/build/cloudera-byol.zip *
echo "-->Cleanup $SCRIPT_DIR"
cd $SCRIPT_DIR
rm -rf $folder
echo "-->Showing contents of $SCRIPT_DIR/build"
ls -la $SCRIPT_DIR/build

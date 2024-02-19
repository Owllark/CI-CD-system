#!/bin/bash

handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}

trap 'handle_error $BASH_COMMAND' ERR

cp -f config.json ../jenkins/
cp -f config.json ../elk/
cp -f config.json ../argocd/
echo "config.json copied to necessary directories"

cp -f utils.sh ../jenkins/
cp -f utils.sh ../elk/
cp -f utils.sh ../argocd/
echo "utils.sh copied to necessary directories"

echo "Configuration updated!"
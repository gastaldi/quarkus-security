#!/bin/bash

set -e -u -o pipefail
shopt -s failglob

if [ ! -f LICENSE.txt ]; then
    echo "ERROR: This script has to be run from the root of the quarkus-http project"
    exit 1
fi

# Set up jbang alias, we are using latest released transformer version
jbang alias add --name transform org.eclipse.transformer:org.eclipse.transformer.cli:0.2.0

# Function to help transform a particular Maven module using Eclipse Transformer
transform_module () {
  local modulePath="$1"
  local transformationTemp="JAKARTA_TEMP"
  rm -Rf $transformationTemp
  mkdir $transformationTemp
  echo "  - Transforming $modulePath"
  jbang transform -o $modulePath $transformationTemp
  rm -Rf "$modulePath"
  mv "$transformationTemp" "$modulePath"
  echo "    > Transformation done"
}

# Rewrite a module with OpenRewrite
rewrite_module () {
  local modulePath="$1"
  echo "  - Rewriting $modulePath"
  mvn -B rewrite:run -f "${modulePath}/pom.xml" -N
  echo "    > Rewriting done"
}

convert_service_file () {
  local newName=${1/javax/jakarta}
  mv "$1" "$newName"
}

rewrite_module .
transform_module src

mvn versions:set -DnewVersion=2.0.0-SNAPSHOT -DprocessAllModules -DgenerateBackupPoms=false

git add .
git commit -m 'Transform sources to Jakarta EE 10'

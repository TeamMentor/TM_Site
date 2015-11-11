#!/bin/bash

if [ ! -f ./node_modules/html-file-cov/package.json ]; then
  echo 'Installing coverage dependencies'
  npm install jscover
  npm install coffee-coverage
  npm install html-file-cov
fi

#set -o errexit # Exit on error
echo 'Removing cache files'
rm -R ./.tmCache
mkdir ./.tmCache

export NODE_COV_DIR=../_tm_website-node-cov
echo "Creating instrumented node files (for CoffeeScript) in $NODE_COV_DIR"


coffeeCoverage --path relative ./src $NODE_COV_DIR/src
coffeeCoverage --path relative ./test $NODE_COV_DIR/test
cp -R node_modules $NODE_COV_DIR/node_modules

#echo '    deleting node-cov *.coffee files'
#find . -path ".$NODE_COV_DIR/**/*.coffee" -delete

echo 'Running Tests locally with (html-file-cov)'
mocha -R html-file-cov $NODE_COV_DIR/test  --recursive

echo 'Removing instrumented node files'
rm -R $NODE_COV_DIR

mv coverage.html .tmCache/coverage.html
echo 'Opening browser with coverage.html'

open .tmCache/coverage.html
#!/bin/sh

command -v md5sum >/dev/null 2>&1 && cmd=md5sum || command -v md5 >/dev/null 2>&1 && cmd=md5 || exit 1

echo "{" > manifest.json

sum=`$cmd < static/master.js | cut -d " " -f 1`
file="master-${sum}.js"
echo "\"master.js\": \"$file\", " >> manifest.json
mv static/master.js static/$file

sum=`$cmd < static/master.css | cut -d " " -f 1`
file="master-${sum}.css"
echo "\"master.css\": \"$file\"" >> manifest.json
mv static/master.css static/$file

echo "}" >> manifest.json


#!/bin/bash

typeset DART=/usr/lib/dart/bin/dart
export https_proxy="http://10.230.1.1:8080"
export no_proxy="127.0.0.1,localhost"
typeset TARGETHOST
typeset FILES2STAGE="lib/src/globals.dart settings.json"
shopt -s nocasematch
[[ "$2" =~ "dev" ]] && TARGETHOST=nightscout-dev.home.local
[[ "$2" =~ "ref" ]] && TARGETHOST=nightscout-stage.home.local
[[ "$2" =~ "prod" ]] && TARGETHOST=nightscout.home.local
if [[ "$1" =~ "all" ]]
then
  echo "======================"
  echo "refreshing build stack"
  echo "======================"
  $DART pub get
  $DART pub global activate webdev 2.7.2
fi

if [[ "$1" =~ "all" || "$1" =~ "build" ]]
then
  echo 
  echo "======================"
  echo "applying stage"
  echo "======================"
  for FILE in $FILES2STAGE
  do
    sed -e"s/https:\/\/.*\/NightScoutReporter\//https:\/\/$TARGETHOST\/NightScoutReporter\//g" < $FILE > /tmp/nsr.stage
    [ $? -eq 0 ] && cp /tmp/nsr.stage $FILE
  done
  echo 
  echo "======================"
  echo "running build"
  echo "======================"
  $DART pub global run webdev build --output=web:build
fi

typeset INSTALLDIR=/tmp/NightScoutReporter.$$
echo 
echo "======================"
echo "installing to $INSTALLDIR"
echo "======================"
rm -rf $INSTALLDIR
mkdir $INSTALLDIR
cp -r build/* $INSTALLDIR
cp settings.json $INSTALLDIR
unrar x nr-pdfmake.rar $INSTALLDIR
tar -cvzf /tmp/NightScoutReporter.tar.gz -C $INSTALLDIR .
typeset TARGETLOCATION=myroot@$TARGETHOST:/home/myroot/Software/NightScoutReporter
echo 
echo "======================"
echo "deploying to $TARGETLOCATION"
echo "======================"
ssh $(echo $TARGETLOCATION | cut -d":" -f1) "rm -rf $(echo $TARGETLOCATION | cut -d":" -f2-)/*"
scp /tmp/NightScoutReporter.tar.gz $TARGETLOCATION
ssh $(echo $TARGETLOCATION | cut -d":" -f1) "cd $(echo $TARGETLOCATION | cut -d":" -f2-) && tar -xvzf NightScoutReporter.tar.gz && rm -f NightScoutReporter.tar.gz"
echo 
echo "======================"
echo "deployed"
echo "FINISHED"
echo "======================"


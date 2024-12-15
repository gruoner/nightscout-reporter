#!/bin/bash

typeset DART=/usr/lib/dart/bin/dart
export https_proxy="http://10.230.1.1:8080"
echo "======================"
echo "refreshing build stack"
echo "======================"
$DART pub get
$DART pub global activate webdev 2.7.2
echo 
echo "======================"
echo "running debug"
echo "======================"
$DART pub global run webdev serve web:3001

echo "======================"
echo "FINISHED"
echo "======================"


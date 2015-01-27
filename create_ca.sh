#!/bin/bash

CONF=dev
KEYNAME=test
CA=mediaca
PROMPT=false
HELP=false

#source config file.
. conf/config

while [[ $# > 0 ]]
do
  key="$1"
  shift

  case $key in
    --conf)
      CONFILE=$1
      shift
      # Override the default conf file
      . conf/config.$CONFILE
    ;;
    -pp|--passphase)
      PASSPHASE=$1
      shift
    ;;
    -p|--prompt)
      PROMPT=true
    ;;
    -h|--help|-?|--?)
      HELP=true
    ;;
    *)
      # unknown option
    ;;
  esac
done

if $HELP; then
  echo "create_ca"
  echo " "
  echo "Create the CA ssh keys"
  echo "-p|--prompt           Prompt for the password"
  exit
  exit
fi

if $PROMPT; then
  read -p "Enter SSH passphase: " PASSPHASE
else
  PASSPHASE=
fi

CAROOT=ssl/$CA/$CONF
CAKEY=$CAROOT/private/$CA-root.key
CADER=$CAROOT/certs/$CA-root.der
CAPEM=$CAROOT/certs/$CA-root.pem


mkdir -p $CAROOT/certs
mkdir -p $CAROOT/private
mkdir -p $CAROOT/crl
mkdir -p $CAROOT/conf
echo "01" > $CAROOT/serial
touch $CAROOT/index.txt

#1. Create root ca.
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out $CAPEM -outform PEM -keyout $CAKEY -config $CAROOT/ca.cnf

openssl x509 -in $CAPEM -outform DER -out $CADER

#openssl genrsa -out $CAKEY 2048 -des3
#openssl req -x509 -new -nodes -key sCAKEY -days 1024 -out $CAPEM
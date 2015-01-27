#!/bin/bash

#defaults
PROMPT=false
HELP=false
NEWCA=false
CONF=dev
KEYNAME=test
SELFSIGN=false
CA=mediaca

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
    -k|--key)
      KEYNAME=$1
      shift
    ;;
    -ou|--ou)
      OU=$1
      shift
    ;;
    -cn|--commonname)
      CN=$1
      shift
    ;;
    -dns|--dnsname)
      DNSNAME=$1
      shift
    ;;
    -s|--selfsigned)
      SELFSIGN=true
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
  echo "create_certificate"
  echo " "
  echo "Source"
  echo "Create the ssh keys"
  echo "-p|--prompt           Prompt for the password (empty to ignore"
  echo "-s|--selfsigned       Create a self-signed certificate"
  echo "-k|--keyname          The certificate key name"
  
  exit
fi

if $SELFSIGN; then
  echo "Creating self-signed ssl certifcate"
  CAROOT=ssl/$KEYNAME
else
  echo "Creating ssl certifcate signed by $CA"
  CAROOT=ssl/$CA/$CONF
fi

CAKEY=$CAROOT/private/$CA-root.key
CAPEM=$CAROOT/certs/$CA-root.pem
CAREQ=$CAROOT/conf/$KEYNAME.cnf
RANDFILE=$CAROOT/private/$KEYNAME.rand

if [ ! -d $CAROOT ]; then
  mkdir -p $CAROOT/private
  mkdir -p $CAROOT/certs
  mkdir -p $CAROOT/conf
fi

echo "Exporting files to:"
echo "  certificates: $CAROOT/certs"
echo "  configuration: $CAROOT/conf"

if $PROMPT; then
  read -p "Enter SSH passphase: " PASSPHASE
else
  PASSPHASE=
fi

#2. Create service cerficate.
#openssl genrsa -out build/ssl/couchpotato.key 2048
#openssl req -new -key build/ssl/couchpotato.key  -out build/ssl/couchpotato.csr
#openssl x509 -req -in build/ssl/couchpotato.csr -CA ssl/media-rootca.pem -CAkey ssl/media-rootca.key -CAcreateserial -out build/ssl/couchpotato.crt -days 500

# Create request file
echo "RANDFILE               = $RANDFILE" > $CAREQ
echo "[ req ]" >> $CAREQ
echo "default_bits           = 1024" >> $CAREQ
echo "default_keyfile        = $CAROOT/certs/$KEYNAME.key" >> $CAREQ
echo "distinguished_name     = req_distinguished_name" >> $CAREQ
echo "attributes             = req_attributes" >> $CAREQ
echo "prompt                 = no" >> $CAREQ
echo "output_password        = $PASSWD" >> $CAREQ
echo " " >> $CAREQ
echo "[ req_distinguished_name ]" >> $CAREQ
echo "C                      = $C" >> $CAREQ
echo "ST                     = $ST" >> $CAREQ
echo "L                      = $L" >> $CAREQ
echo "O                      = $O" >> $CAREQ
echo "OU                     = $OU" >> $CAREQ
echo "CN                     = $CN" >> $CAREQ
echo "emailAddress           = $EMAIL" >> $CAREQ
echo "" >> $CAREQ
echo "[ req_attributes ]" >> $CAREQ
echo "challengePassword      = $PASSWD" >> $CAREQ

# Generate SSL Req
#openssl req -batch -new -key my.website.com.key -out my.website.com.csr -config config-file.txt
#openssl req -newkey rsa:1024 -nodes -sha1 -keyout $CAROOT/certs/$KEYNAME.key -keyform PEM -out $CAROOT/certs/$KEYNAME.req -outform PEM 
#openssl req -batch -newkey rsa:1024 -nodes -sha1 -new -key $CAROOT/certs/$KEYNAME.key -out $CAROOT/certs/$KEYNAME.req -config $CAREQ
echo "Generating SSL Request and Private Key"
openssl req -batch -newkey rsa:1024 -nodes -sha1 -keyout $CAROOT/certs/$KEYNAME.key -keyform PEM -out $CAROOT/certs/$KEYNAME.req -outform PEM  -config $CAREQ
echo "------------------------------------------------"
# check key
echo "Check the private key"
openssl rsa -in $CAROOT/certs/$KEYNAME.key -check
echo "------------------------------------------------"
# Check SSL Rer
echo "Check the SSL request"
openssl req -text -noout -verify -in $CAROOT/certs/$KEYNAME.req
echo "------------------------------------------------"
#Sign SSH
if $SELFSIGN; then
  echo "Creating a selfsigned SSL certificate "
  openssl x509 -req -days 3650 -in $CAROOT/certs/$KEYNAME.req -signkey $CAROOT/certs/$KEYNAME.key -out $CAROOT/certs/$KEYNAME.pem
else
  echo "Signing the SSL certificate with the CA"
  openssl ca -config $CAROOT/ca.cnf -batch -notext -in $CAROOT/certs/$KEYNAME.req -out $CAROOT/certs/$KEYNAME.pem
fi
echo "------------------------------------------------"
# Check cert
echo "Created SSL Key"
openssl x509 -in $CAROOT/certs/$KEYNAME.pem -text -noout
# add the root to the bottom of the cert
echo "------------------------------------------------"


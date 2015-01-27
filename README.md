# Set of scripts to create a self-signed SSL or sign a certificate based on a CA

Settings can be inputed via the configuration files in conf/conf.environment

## To create ca

  Edit conf/config

  Run the script (no password on the private key)
  > create_ca.sh

  Run the script (no password on the private key)
  > create_ca.sh -p

  The certificates are exported to ssl/

## To create certificate

### Self-signed

  Edit conf/config.environment

  Run the script
  > create_certificate.sh --conf config.environment -s

### Using CA

  Edit conf/config.environment

  Run the script
  > create_certificate.sh --conf config.environment
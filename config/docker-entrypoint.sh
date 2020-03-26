#!/bin/bash
set -e

# Load Apache environment variables
. /etc/apache2/envvars

# Remove existing PID file
if [ -f /var/run/apache2/apache2.pid ]; then
  rm -f /var/run/apache2/apache2.pid
fi

# Configure Xdebug
if [ "${APACHE2_ENABLE_XDEBUG}" == "yes" ]; then
  echo "=> Enabling Xdebug..."
  phpenmod xdebug
else
  echo "=> Disabling Xdebug..."
  phpdismod xdebug
fi

# Configure MSMTP
if [ ! -z "${APACHE2_MSMTP_HOST}" ]; then
  echo "=> Enabling MSMTP... [${APACHE2_MSMTP_HOST}]"
  phpenmod msmtp
  echo "host ${APACHE2_MSMTP_HOST}" > /var/www/.msmtprc
  if [ ! -z "${APACHE2_MSMTP_FROM}" ]; then
    echo "from ${APACHE2_MSMTP_FROM}" >> /var/www/.msmtprc
  fi
else
  echo "=> Disabling SMTP relay..."
  phpdismod msmtp
fi

exec apache2 -DFOREGROUND "$@"

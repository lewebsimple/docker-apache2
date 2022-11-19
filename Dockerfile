FROM ubuntu:jammy
LABEL maintainer "Pascal Martineau <pascal@lewebsimple.ca>"

# Default Apache2 UID / GID
ENV APACHE2_UID 1000
ENV APACHE2_GID 1000

# Install Apache2 and useful libraries
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  apache2 \
  msmtp \
  apt-transport-https build-essential ca-certificates gnupg software-properties-common \
  curl git imagemagick less iputils-ping nano openssh-client rsync wget \
  language-pack-fr-base tzdata \
  ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Install PHP 8.1
RUN add-apt-repository ppa:ondrej/php \
  && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  php8.1 php8.1-cli php8.1-curl php8.1-dev php8.1-gd php8.1-intl php8.1-mbstring php8.1-mysql php-pear php8.1-xdebug php8.1-xml php8.1-zip \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY config/ /

# Configure Apache2 / PHP
RUN set -ex \
  # Load Apache2 environment variables
  && . /etc/apache2/envvars \
  # Enable Apache2 configurations
  && a2enconf fqdn conf-extra \
  # Enable Apache2 modules
  && a2enmod expires headers remoteip rewrite vhost_alias \
  # Enable Apache2 vhosts
  && a2ensite vhosts \
  && apache2ctl graceful \
  # Remove SSL vhostn
  && rm /etc/apache2/sites-available/default-ssl.conf \
  # Disable Indexes everywhere
  && sed -e '/Options Indexes FollowSymLinks/ s/^#*/#/' -i /etc/apache2/apache2.conf \
  # Output error log to stderr
  && ln -sfT /dev/stderr "${APACHE_LOG_DIR}/error.log" \
  && ln -sfT /dev/stdout "${APACHE_LOG_DIR}/access.log" \
  # Create Xdebug directory
  && mkdir -p /tmp/xdebug \
  # Change UID/GID of www-data to match local user
  && usermod --non-unique --uid ${APACHE2_UID} www-data \
  && groupmod --non-unique --gid ${APACHE2_GID} www-data \
  # Adjust directory permissions
  && chown -R www-data:www-data /var/www /tmp \
  # Reload Apache2
  # Generate fr_CA locale
  && locale-gen fr_CA.utf8

# Install NPM packages
RUN npm i -g \
  pnpm \
  yarn

VOLUME ["/etc/apache2/conf-extra","/var/www/html","/tmp"]
WORKDIR /var/www/html

EXPOSE 80

CMD ["/docker-entrypoint.sh"]

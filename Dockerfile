FROM ubuntu:bionic
LABEL maintainer "Pascal Martineau <pascal@lewebsimple.ca>"

# Default Apache2 UID / GID
ENV APACHE2_UID 1000
ENV APACHE2_GID 1000

# Install Apache2
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  apache2 \
  msmtp \
  apt-transport-https build-essential ca-certificates gnupg software-properties-common \
  curl git imagemagick less iputils-ping nano openssh-client rsync wget \
  language-pack-fr-base tzdata \
  && rm -rf /var/lib/apt/lists/*

# Install PHP
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" > /etc/apt/sources.list.d/ondrej-php-xenial.list \
  && echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list.d/ondrej-php-xenial.list \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C \
  && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  php php-cli php-curl php-dev php-gd php-intl php-mbstring php-mysql php-pear php-xdebug php-xml php-zip \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js 13.x
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - \
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
  && a2enmod expires headers rewrite vhost_alias \
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
  # Install Xdebug with pecl
  && pecl install xdebug \
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

VOLUME ["/etc/apache2/conf-extra","/var/www/html","/tmp"]
WORKDIR /var/www/html

EXPOSE 80

CMD ["/docker-entrypoint.sh"]
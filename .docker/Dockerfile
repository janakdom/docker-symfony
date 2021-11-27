FROM php:7.4-apache

# set main params
ARG BUILD_ARGUMENT_DEBUG_ENABLED=false
ENV DEBUG_ENABLED=$BUILD_ARGUMENT_DEBUG_ENABLED
ARG BUILD_ARGUMENT_ENV=dev
ENV ENV=$BUILD_ARGUMENT_ENV
ENV APP_HOME /app
ARG COMPOSE_PROJECT_NAME

ARG GID=1000
ARG USERNAME
ARG ROOT_PASSWORD
ARG UID=1000

# check environment
RUN if [ "$BUILD_ARGUMENT_ENV" = "default" ]; then echo "Set BUILD_ARGUMENT_ENV in docker build-args like --build-arg BUILD_ARGUMENT_ENV=dev" && exit 2; \
    elif [ "$BUILD_ARGUMENT_ENV" = "dev" ]; then echo "Building development environment."; \
    elif [ "$BUILD_ARGUMENT_ENV" = "test" ]; then echo "Building test environment."; \
    elif [ "$BUILD_ARGUMENT_ENV" = "staging" ]; then echo "Building staging environment."; \
    elif [ "$BUILD_ARGUMENT_ENV" = "prod" ]; then echo "Building production environment."; \
    else echo "Set correct BUILD_ARGUMENT_ENV in docker build-args like --build-arg BUILD_ARGUMENT_ENV=dev. Available choices are dev,test,staging,prod." && exit 2; \
    fi

# install all the dependencies and enable PHP modules
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
      procps \
      nano \
      git \
      mc \
      unzip \
      libicu-dev \
      zlib1g-dev \
      libxml2 \
      libxml2-dev \
      libreadline-dev \
      libzip-dev \
      libpng-dev \
      libwebp-dev \
      libfreetype6-dev \
      libsodium-dev \
      libc-client-dev \
      libkrb5-dev \
      supervisor \
      cron \
      sudo \
      libzip-dev \
      wget \
      librabbitmq-dev \
    && pecl install amqp-1.11.0beta
RUN docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure gd --with-freetype \
    && docker-php-ext-configure zip \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-install \
      pdo_mysql \
      sockets \
      sodium \
      opcache \
      intl \
      opcache \
      zip \
    && docker-php-ext-enable amqp \
    && rm -rf /tmp/* \
    && rm -rf /var/list/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN pecl install apcu && docker-php-ext-enable apcu

# disable default site and delete all default files inside APP_HOME
RUN a2dissite 000-default.conf
RUN rm -rf $APP_HOME

# create document root, fix permissions for www-data user and change owner to www-data
RUN mkdir -p $APP_HOME/public && \
    mkdir -p /home/$USERNAME && chown $USERNAME:$USERNAME /home/$USERNAME \
    && usermod -u $UID $USERNAME -d /home/$USERNAME \
    && groupmod -g $GID $USERNAME \
    && chown -R ${USERNAME}:${USERNAME} $APP_HOME

RUN mkdir -p /home/$USERNAME/.ssh \
    && ssh-keyscan -H github.com >> /home/$USERNAME/.ssh/known_hosts \
    && ssh-keyscan -H gitlab.com >> /home/$USERNAME/.ssh/known_hosts

RUN echo "root:${ROOT_PASSWORD}" | chpasswd

# put apache and php config for Symfony, enable sites
COPY ./apache2/apache2.conf /etc/apache2/apache2.conf
COPY ./apache2/docker-php.conf /etc/apache2/conf-available/docker-php.conf
COPY ./apache2/symfony.conf /etc/apache2/sites-available/symfony.conf
COPY ./apache2/symfony-ssl.conf /etc/apache2/sites-available/symfony-ssl.conf
RUN a2ensite symfony.conf && a2ensite symfony-ssl
COPY ./php/php.$BUILD_ARGUMENT_ENV.ini /usr/local/etc/php/php.ini

# enable apache modules
RUN a2enmod rewrite
RUN a2enmod ssl

# install local-php-security-checker
RUN curl -s https://api.github.com/repos/fabpot/local-php-security-checker/releases/latest | \
    grep -E "browser_download_url(.+)linux_amd64" | \
    cut -d : -f 2,3 | \
    tr -d \" | \
    xargs -I{} wget -O local-php-security-checker {} \
    && mv local-php-security-checker /usr/local/bin/local-php-security-checker \
    && chmod +x /usr/local/bin/local-php-security-checker

# install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN chmod +x /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN composer --version

# add symfony-cli
RUN wget https://get.symfony.com/cli/installer -O - | bash && \
    mv /root/.symfony/bin/symfony /usr/local/bin/symfony

# install Xdebug in case dev/test environment
COPY ./scripts/do_we_need_xdebug.sh /tmp/
COPY ./php/xdebug.ini /tmp/
RUN chmod u+x /tmp/do_we_need_xdebug.sh && /tmp/do_we_need_xdebug.sh

# add supervisor
#RUN mkdir -p /var/log/supervisor
#RUN chmod 0600 /var/spool/cron/crontabs/root
#RUN chown -R root:crontab /var/spool/cron/crontabs/root

#install mailhog/mhsendmail
RUN if [ "$BUILD_ARGUMENT_ENV" = "dev" ] || [ "$BUILD_ARGUMENT_ENV" = "test" ]; then \
      wget https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 -O /usr/local/sbin/mhsendmail ; \
          chmod +x /usr/local/sbin/mhsendmail ; \
          echo "sendmail_path=\"/usr/local/sbin/mhsendmail --smtp-addr=${COMPOSE_PROJECT_NAME}_mailhog:1026\"" >> /usr/local/etc/php/php.ini ; \
    fi

# generate certificates
# TODO: change it and make additional logic for production environment
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem -subj "/C=CZ/ST=Prague/L=Prague/O=Security/OU=Development/CN=dominikjanak.loc"

# MC conf
RUN mkdir -p echo /root/.config/mc/; \
    echo '[Layout]\n\
    command_prompt=0' >> /root/.config/mc/ini

RUN mkdir -p echo ../../../.config/mc/; \
    echo '[Layout]\n\
    command_prompt=0' >> ../../../.config/mc/ini

ENV TZ=Europe/Prague
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# set working directory
WORKDIR $APP_HOME

USER ${USERNAME}


# install all PHP dependencies
#RUN if [ "$BUILD_ARGUMENT_ENV" = "dev" ] || [ "$BUILD_ARGUMENT_ENV" = "test" ]; then \
#      COMPOSER_MEMORY_LIMIT=-1 composer install --working-dir=$APP_HOME --optimize-autoloader --no-interaction --no-progress; \
#    else \
#      export APP_ENV=$BUILD_ARGUMENT_ENV && COMPOSER_MEMORY_LIMIT=-1 composer install --working-dir=$APP_HOME --optimize-autoloader --no-interaction --no-progress --no-dev; \
#    fi

# create cached config file .env.local.php in case staging/prod environment
RUN if [ "$BUILD_ARGUMENT_ENV" = "staging" ] || [ "$BUILD_ARGUMENT_ENV" = "prod" ]; then \
      composer dump-env $BUILD_ARGUMENT_ENV --working-dir=$APP_HOME; \
    fi

USER root

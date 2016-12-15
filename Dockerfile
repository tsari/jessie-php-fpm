FROM tsari/php
MAINTAINER Tibor Sári <tiborsari@gmx.de>

ENV AMQP_VERSION=1.7.1
ENV MAILPARSE_VERSION=3.0.1

# update, install project dependent modules and clean up to minimize the image size
RUN \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        librabbitmq-dev \
        php7.0-apcu \
        php7.0-curl \
        php7.0-dev \
        php7.0-fpm \
        php7.0-imagick \
        php7.0-intl \
        php7.0-memcached \
        php7.0-mbstring \
        php7.0-pgsql \
        php7.0-sqlite3 \
        php7.0-xml \
        php-zip \
        php-imap \
        php-pear \
        php-soap \
    && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install some pecl modules
# mailparse must be pre-processed due to https://bugs.php.net/bug.php?id=71813
RUN cd /usr/src && \
    pecl download mailparse-$MAILPARSE_VERSION && \
    tar xf mailparse-$MAILPARSE_VERSION.tgz && \
    cd mailparse-$MAILPARSE_VERSION && \
    phpize && \
    ./configure && \
    sed -i 's/^\(#error .* the mbstring extension!\)/\/\/\1/' mailparse.c && \
    make && \
    make install && \
    echo "extension=`find / -name "mailparse.so"`" > /etc/php/7.0/mods-available/mailparse.ini && \
    phpenmod mailparse

RUN pecl install amqp-$AMQP_VERSION
RUN echo "extension=`find / -name "amqp.so"`" > /etc/php/7.0/mods-available/amqp.ini && \
    phpenmod amqp

RUN pecl install mongodb
RUN echo "extension=`find / -name "mongodb.so"`" > /etc/php/7.0/mods-available/mongodb.ini && \
    phpenmod mongodb

# this is copied from official php-fpm repo
COPY docker.conf /etc/php/7.0/fpm/pool.d/docker.conf
COPY zz-docker.conf /etc/php/7.0/fpm/pool.d/zz-docker.conf

RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini

VOLUME /var/www
WORKDIR /var/www

EXPOSE 9000
CMD ["php-fpm7.0"]
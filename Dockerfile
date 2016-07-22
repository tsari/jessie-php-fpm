FROM buildpack-deps:jessie
MAINTAINER Tibor Sári <tiborsari@gmx.de>

ENV DEBIAN_FRONTEND noninteractive

ENV AMQP_VERSION=1.7.1

## add dotdeb to apt sources list
RUN echo 'deb http://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/dotdeb.list
RUN echo 'deb-src http://packages.dotdeb.org jessie all' >> /etc/apt/sources.list.d/dotdeb.list

## add dotdeb key for apt
RUN curl http://www.dotdeb.org/dotdeb.gpg | apt-key add -

# pin the versions
COPY dotdeb.pin /etc/apt/preferences.d/php

# we need this for the php-fpm pid file
VOLUME /run/php

# update, install and clean up to minimize the image size
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
        sudo \
    && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# build and install php-amqp due to missing php7 support for php-pear (pecl)
RUN cd /usr/src && \
    wget https://pecl.php.net/get/amqp-$AMQP_VERSION.tgz && \
    tar xvf amqp-$AMQP_VERSION.tgz && \
    cd amqp-$AMQP_VERSION && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    cd /usr/src && rm -rf amqp-$AMQP_VERSION amqp-$AMQP_VERSION.tgz && \
    echo "extension=`find / -name "amqp.so"`" > /etc/php/7.0/mods-available/amqp.ini && \
    phpenmod amqp

# this is copied from official php-fpm repo
COPY docker.conf /etc/php/7.0/fpm/pool.d/docker.conf
COPY zz-docker.conf /etc/php/7.0/fpm/pool.d/zz-docker.conf

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
#RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/fpm/php.ini && \
#    sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.0/fpm/php.ini

#COPY entrypoint.sh /usr/local/bin/entrypoint.sh
#RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

# Set up the command arguments
#ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm7.0"]
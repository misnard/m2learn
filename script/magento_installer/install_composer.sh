#!/bin/sh

if ! [ -x "$(command -v composer)" ]; then

    echo "installing composer"
    echo

    EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    RESULT=$?
    mv composer.phar /usr/local/bin/composer.phar
    # Be sure to bypass memory limit
    echo "php -d memory_limit=-1 /usr/local/bin/composer.phar \$@" > /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    rm composer-setup.php
    exit ${RESULT}

else
    echo "composer is already installed"
    echo
fi

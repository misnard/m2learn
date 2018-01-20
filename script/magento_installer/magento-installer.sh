#!/bin/bash

if ! [ -f $MAGENTO_ROOT/index.php ]; then

    [ "$DEBUG" = "true" ] && set -x

    AUTH_JSON_FILE="$(composer -g config data-dir 2>/dev/null)/auth.json"

    if [ -f "$AUTH_JSON_FILE" ]; then
        # Get composer auth information into an environment variable to avoid "you need
        # to be using an interactive terminal to authenticate".
        COMPOSER_AUTH=`cat $AUTH_JSON_FILE`
    fi

    MAGENTO_COMMAND="$MAGENTO_ROOT/bin/magento"

    if [ ! -f "$MAGENTO_ROOT/composer.json" ]; then
        echo "Creating Magento ($M2SETUP_VERSION) project from composer"

        # Clean Magento root
        rm -rf $MAGENTO_ROOT/*
        rm -rf $MAGENTO_ROOT/.*

        composer create-project \
            --repository-url=https://repo.magento.com/ \
            magento/project-community-edition=$M2SETUP_VERSION \
            --no-interaction \
            $MAGENTO_ROOT

        # Magento forces Composer to use $MAGENTO_ROOT/var/composer_home as the home directory
        # when running any Composer commands through Magento, e.g. sampledata:deploy, so copy the
        # credentials over to it to prevent Composer from asking for them again
        if [ -f "$AUTH_JSON_FILE" ]; then
            mkdir -p $MAGENTO_ROOT/var/composer_home
            cp $AUTH_JSON_FILE $MAGENTO_ROOT/var/composer_home/auth.json
        fi
    else
        echo "Magento installation found in $MAGENTO_ROOT, installing composer dependencies"
        composer --working-dir=$MAGENTO_ROOT install
    fi

    if [ ! "$M2SETUP_INSTALL_DB" = "false" ]; then

        echo "Install Magento"

        INSTALL_COMMAND="$MAGENTO_COMMAND setup:install \
            --db-host=$M2SETUP_DB_HOST \
            --db-name=$M2SETUP_DB_NAME \
            --db-user=$M2SETUP_DB_USER \
            --db-password=$M2SETUP_DB_PASSWORD \
            --base-url=$M2SETUP_BASE_URL \
            --use-rewrites=1 \
            --use-secure=1 \
            --cleanup-database \
            --admin-firstname=$M2SETUP_ADMIN_FIRSTNAME \
            --admin-lastname=$M2SETUP_ADMIN_LASTNAME \
            --admin-email=$M2SETUP_ADMIN_EMAIL \
            --admin-user=$M2SETUP_ADMIN_USER \
            --admin-password=$M2SETUP_ADMIN_PASSWORD"

        # Use a separate value for secure base URL, if the variable is set
        if [ -n "$M2SETUP_SECURE_BASE_URL" ]; then
            INSTALL_COMMAND="$INSTALL_COMMAND --base-url-secure=$M2SETUP_SECURE_BASE_URL"
        fi

        # Only define a backend-frontname if the variable is set, or not empty.
        if [ -n "$M2SETUP_BACKEND_FRONTNAME" ]; then
            INSTALL_COMMAND="$INSTALL_COMMAND --backend-frontname=$M2SETUP_BACKEND_FRONTNAME"
        fi

        if [ "$M2SETUP_USE_SAMPLE_DATA" = "true" ]; then

          $MAGENTO_COMMAND sampledata:deploy
          composer --working-dir=$MAGENTO_ROOT update

          INSTALL_COMMAND="$INSTALL_COMMAND --use-sample-data"
        fi

        $INSTALL_COMMAND
        $MAGENTO_COMMAND index:reindex
        $MAGENTO_COMMAND setup:static-content:deploy

    else
        echo "Skipping DB installation"
    fi

    echo "Fixing file permissions.."

    [ -f "$MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php" ] \
      && sed -i 's/0770/0775/g' $MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php

    [ -f "$MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php" ] \
      && sed -i 's/0660/0664/g' $MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php

    find $MAGENTO_ROOT/pub -type f -exec chmod 664 {} \;
    find $MAGENTO_ROOT/pub -type d -exec chmod 775 {} \;
    find $MAGENTO_ROOT/var/generation -type d -exec chmod g+s {} \;

    echo "Creating cache and report folders"
    mkdir -p $MAGENTO_ROOT/var/page_cache
    mkdir -p $MAGENTO_ROOT/var/cache
    mkdir -p $MAGENTO_ROOT/var/report
    chmod -R 777 $MAGENTO_ROOT/var/page_cache
    chmod -R 777 $MAGENTO_ROOT/var/cache
    chmod -R 777 $MAGENTO_ROOT/var/report

    echo "Fixing user and group to ${M2SETUP_UID}:${M2SETUP_GID}"
    chown -R ${M2SETUP_UID}:${M2SETUP_GID} ${MAGENTO_ROOT}
    chmod -R g+rws ${MAGENTO_ROOT}

    echo "Installation complete"

else

    echo "Magento 2 already installed, if you want to force a full reinstallation remove all [magento_src] folder content"

fi

#!/bin/bash

# PHP informations, always usefull
echo "PHP version:"
php -v
echo

echo "PHP modules:"
php -m
echo

# Custom #1: install composer
/script/magento_installer/install_composer.sh
# Custom #2: install magento
/script/magento_installer/magento-installer.sh

# Cron service have to be manually started
/etc/init.d/cron start
crontab /etc/cron.d/*
crontab -l
echo

# Custom #3: Deployingo Magento static content
echo "Deployingo Magento static content"
/var/www/bin/magento setup:static-content:deploy -f
echo

# Custom #4: Cleaning cache
echo "Cleaning cache"
/var/www/bin/magento cache:clean
echo

# Main service
echo
echo "Starting php-fpm"
echo
exec php-fpm

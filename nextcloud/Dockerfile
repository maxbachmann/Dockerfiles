FROM nextcloud:24-apache

LABEL version="24-apache"
LABEL description="Build nextcloud image with smb support"

RUN apt update && apt install -y smbclient libsmbclient-dev && rm -rf /var/lib/apt/lists/* && pecl install smbclient && docker-php-ext-enable smbclient
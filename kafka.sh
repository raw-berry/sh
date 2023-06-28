#!/bin/bash
# bt安装php kafka扩展脚本
# 使用方法 chmod +x kafka.sh && ./kafka.sh [version]
# version是PHP版本:支持72/73/74,version默认73
version=$1
if [[ $version -ne 72 && $version -ne 73 && $version -ne 74 ]]; then
    version=73
fi

phpconfig="/www/server/php/${version}/bin/php-config"
phpini="/www/server/php/${version}/etc/php.ini"

if [ -e $phpconfig ]; then 
    echo ""
else
    echo "php version error,please input php version"
    exit 1
fi

check=`/www/server/php/${version}/bin/php -m | grep rdkafka`
if 	echo "$check" | grep -q "rdkafka"; then
    echo "already installed"
    exit 0
fi

yum -y install git

#check dir librdkafka
if [ -d "librdkafka" ]; then
	rm -rf "librdkafka"
fi
#install librdkafka
git clone https://github.com/edenhill/librdkafka.git
if [ $? -eq 0 ]; then 
	cd librdkafka
	./configure
	make && make install
	cd ..
else
	echo "unable to access https://github.com/"
	exit 1
fi

#check dir librdkafka
if [ -d "php-rdkafka" ]; then
	rm -rf "php-rdkafka"
fi
#install rdkafka
git clone https://github.com/arnaud-lb/php-rdkafka.git
if [ $? -eq 0 ]; then 
	cd php-rdkafka
	/usr/bin/phpize
	./configure --with-php-config=$phpconfig
	make && make install
else
	echo "unable to access https://github.com/"
	exit 1
fi

if grep -q "extension=rdkafka.so" ${phpini}; then 
	echo ""
else
	echo "extension=rdkafka.so" >> $phpini
fi

systemctl restart php-fpm

check=`/www/server/php/${version}/bin/php -m | grep rdkafka`
if 	echo "$check" | grep -q "rdkafka"; then
    echo "install success"
else
    echo "install fail"
fi


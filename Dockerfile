FROM ubuntu:14.04

RUN apt-get update

# Hack for initctl not being available in Ubuntu
#RUN dpkg-divert --local --rename --add /sbin/initctl
#RUN ln -sf /bin/true /sbin/initctl

#apache2のインストール
RUN apt-get install -y apache2

#mySQLのインストール
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
#RUN apt-get install -y mysql-server
ADD my.cnf /OpenPNE_config/
RUN cp /OpenPNE_config/my.cnf /etc/mysql/

#PHP5のインストール
RUN apt-get install -y php5 php5-mysql php5-mcrypt php5-gd php5-xmlrpc curl

#OpenPNE用のデータベースの作成
ADD *.sql /OpenPNE_config/
RUN /etc/init.d/mysql start \
 && mysql -u root < /OpenPNE_config/init_openpne_db.sql

#OpenPNEのインストール
ENV OPENPNE_VERSION 3.8.14
RUN curl -SL https://github.com/openpne/OpenPNE3/archive/OpenPNE-${OPENPNE_VERSION}.tar.gz  | tar -xzC /opt/
RUN mv /opt/OpenPNE3-* /opt/OpenPNE3
WORKDIR /opt/OpenPNE3
RUN cp config/ProjectConfiguration.class.php.sample config/ProjectConfiguration.class.php
RUN cp config/OpenPNE.yml.sample config/OpenPNE.yml

RUN /etc/init.d/mysql start \
 && ./symfony openpne:fast-install --dbms=mysql --dbuser=openpne3dbuser --dbpassword=pnepassword --dbhost=localhost --dbname=openpne3db

RUN ./symfony project:clear-controllers

#Apacheの設定変更
RUN a2enmod rewrite
RUN sed -i 's/#RewriteBase/RewriteBase/g' web/.htaccess

ADD apache2.conf /OpenPNE_config/
ADD 000-default.conf /OpenPNE_config/
RUN cp /OpenPNE_config/apache2.conf /etc/apache2/
RUN cp /OpenPNE_config/000-default.conf /etc/apache2/sites-available/

EXPOSE 80

ADD start.sh /OpenPNE_config/
CMD bash -C /OpenPNE_config/start.sh ; bash

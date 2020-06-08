#!/bin/bash
# Created by Ramesh Sivaraman, Percona LLC

yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release enable-only pxc-80
percona-release enable tools release
yum update -y
yum install -y percona-xtradb-cluster-client sysbench proxysql

setenforce 0

systemctl start proxysql

mysql --connect-expired-password -uroot -h192.168.100.10 --password="TestPass" -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'admin'; GRANT ALL ON *.* TO 'admin'@'%';"

sed -i "s/CLUSTER_HOSTNAME='localhost'/CLUSTER_HOSTNAME='192.168.100.10'/" /etc/proxysql-admin.cnf
sleep 10
proxysql-admin -e

mysql --user=root -h192.168.100.10 --password="TestPass" -e "GRANT ALL ON *.* TO proxysql_user@'192.%';"

cat <<EOT >> /root/.my.cnf
[client]
user=admin
password=admin
port=6032
protocol=TCP
EOT

cp /root/.my.cnf /home/vagrant/


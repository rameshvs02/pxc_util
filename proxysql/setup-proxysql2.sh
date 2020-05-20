#!/bin/bash
# Created by Ramesh Sivaraman, Percona LLC

NODE=$1
SERVER_ID=$(expr $NODE + 100)
IP_ADDR=`echo $(($NODE * 10))`

yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release enable-only pxc-80
percona-release enable tools release
yum update -y
yum install -y percona-xtradb-cluster-client proxysql2

setenforce 0

systemctl start proxysql

mysql --connect-expired-password -uroot -h192.168.100.10 --password="TestPass" -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'admin'; GRANT ALL ON *.* TO 'admin'@'%';"

sed -i "s/CLUSTER_HOSTNAME='localhost'/CLUSTER_HOSTNAME='192.168.100.10'/" /etc/proxysql-admin.cnf
sleep 10
proxysql-admin -e

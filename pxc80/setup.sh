#!/bin/bash
# Created by Ramesh Sivaraman, Percona LLC

NODE=$1
SERVER_ID=$(expr $NODE + 100)
IP_ADDR=`echo $(($NODE * 10))`

yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release enable-only pxc-80
percona-release enable tools release
yum update -y
yum install -y percona-xtradb-cluster-server

cat <<EOT >> my.cnf
[mysqld]
datadir=/var/lib/mysql
wsrep_provider=/usr/lib64/galera4/libgalera_smm.so
log-error=/var/lib/mysql/mysql.err
pid-file=/var/lib/mysql/mysql.pid
log-error-verbosity=3
wsrep-debug=1
wsrep_cluster_address=gcomm://192.168.100.10,192.168.100.20,192.168.100.30
binlog_format=ROW
server_id=$SERVER_ID
log_bin=mysql-bin
log_slave_updates
gtid_mode=ON
enforce_gtid_consistency
slave_parallel_workers=8

innodb_autoinc_lock_mode=2

wsrep_node_address=192.168.100.$IP_ADDR

wsrep_sst_method=xtrabackup-v2

# Cluster name
wsrep_cluster_name=my_centos_cluster

# Authentication for SST method
pxc_encrypt_cluster_traffic=OFF
wsrep_cluster_name=pxc-cluster
wsrep_node_name=pxc-cluster-node-$NODE
wsrep_slave_threads=8
EOT

cp my.cnf /etc/my.cnf
setenforce 0

if [[ $NODE -eq 1 ]]; then
  systemctl start mysql@bootstrap.service
  init_pass=$(grep "temporary password" /var/lib/mysql/mysql.err | awk '{print $NF}')
  mysql --connect-expired-password -uroot --password="$init_pass" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'TestPass';CREATE USER 'root'@'%' IDENTIFIED BY 'TestPass'; GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;"
else
  systemctl start mysql  
fi

cat <<EOT >> /root/.my.cnf
[client]
user=root
password=TestPass
EOT


#!/bin/bash
# Created by Ramesh Sivaraman, Percona LLC
# This will help us to test PXC node in vagrant box

# make sure we have passed basedir parameter for this benchmark run
if [ -z $2 ]; then
  echo "No valid parameter passed.  Need relative workdir (1st option) and relative basedir (2nd option) settings. Retry."
  echo "Usage example:"
  echo "$./start_pxc_vagrant_encrypt.sh $PWD $PWD/Percona-XtraDB-Cluster-5.7.28-rel31-31.41.1.Linux.x86_64.ssl101"
  exit 1
fi

WORKDIR=$1
BASEDIR=$2
NODE=$3
MYEXTRA=$4
SERVER_ID=$(expr $NODE + 100)
IP_ADDR=`echo $(($NODE * 10))`
cd $WORKDIR
${BASEDIR}/bin/mysqladmin -uroot --socket=${WORKDIR}/data/mysql.sock shutdown
rm -rf *.cnf
rm -rf data

cat <<EOT >> my.cnf
[mysqld]
wsrep-debug=1
server-id=$SERVER_ID
basedir=${BASEDIR}
datadir=${WORKDIR}/data
socket=${WORKDIR}/data/mysql.sock
log-error=${WORKDIR}/data/mysqld.log
expire_logs_days=7
log_error_verbosity=3
symbolic-links=0
wsrep_provider=${BASEDIR}/lib/libgalera_smm.so
wsrep_cluster_address=gcomm://192.168.100.10,192.168.100.20,192.168.100.30
binlog_format=ROW
wsrep_slave_threads=8
wsrep_log_conflicts
innodb_autoinc_lock_mode=2
wsrep_node_address=192.168.100.$IP_ADDR
wsrep_cluster_name=pxc-cluster
wsrep_node_name=pxc-cluster-node-$NODE
pxc_strict_mode=ENFORCING
wsrep_sst_method=xtrabackup-v2
wsrep_sst_auth=root:
pxc_encrypt_cluster_traffic=ON
early-plugin-load=keyring_file=keyring_file.so
keyring_file_data=keyring
ssl-ca = ${WORKDIR}/cert/ca.pem
ssl-cert = ${WORKDIR}/cert/server-cert.pem
ssl-key = ${WORKDIR}/cert/server-key.pem
[sst]
encrypt = 4
ssl-ca = ${WORKDIR}/cert/ca.pem
ssl-cert = ${WORKDIR}/cert/server-cert.pem
ssl-key = ${WORKDIR}/cert/server-key.pem
EOT

startup_check(){
  SOCKET=$1
  for X in `seq 0 200`; do
    sleep 1
    if ${BASEDIR}/bin/mysqladmin -uroot -S${SOCKET} ping > /dev/null 2>&1; then
      break
    fi
  done
}

${BASEDIR}/bin/mysqld --no-defaults --initialize-insecure --datadir=${WORKDIR}/data

mkdir ${WORKDIR}/cert
cp ${WORKDIR}/data/*pem ${WORKDIR}/cert

${BASEDIR}/bin/mysqld --defaults-file=${WORKDIR}/my.cnf $MYEXTRA  &

startup_check ${WORKDIR}/data/mysql.sock

echo "${BASEDIR}/bin/mysql -uroot --socket=${WORKDIR}/data/mysql.sock" > cl
echo "${BASEDIR}/bin/mysqld --defaults-file=${WORKDIR}/my.cnf $MYEXTRA  &" > start
echo "${BASEDIR}/bin/mysqladmin -uroot --socket=${WORKDIR}/data/mysql.sock shutdown" > stop
echo "sysbench /usr/share/sysbench/oltp_insert.lua --mysql-db=sbtest --mysql-user=sysbench --mysql-password=test --mysql-socket=${WORKDIR}/data/mysql.sock --db-driver=mysql   --threads=10 --tables=10 --table-size=1000 prepare" > sysbench_prepare
echo "sysbench /usr/share/sysbench/oltp_insert.lua --mysql-db=sbtest --mysql-user=sysbench --mysql-password=test --mysql-socket=${WORKDIR}/data/mysql.sock --db-driver=mysql   --threads=10 --tables=10 --table-size=1000 --time=300 run" > sysbench_run
chmod 755 cl start stop

${BASEDIR}/bin/mysql  -A -uroot --socket=${WORKDIR}/data/mysql.sock  -e "create user sysbench@'%' identified with  mysql_native_password by 'test';"
${BASEDIR}/bin/mysql  -A -uroot --socket=${WORKDIR}/data/mysql.sock  -e "grant all on *.* to sysbench@'%';"
${BASEDIR}/bin/mysql  -A -uroot --socket=${WORKDIR}/data/mysql.sock  -e "drop database if exists sbtest;create database sbtest"

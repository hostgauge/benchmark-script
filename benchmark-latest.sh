#!/bin/bash
##########################################
##########################################
##                                      ##
## Host Benchmark Script                ##
## By: Brandon Heard                    ##
## v1.0                                 ##
##                                      ##
## http://www.hostgauge.net             ##
## brandon@hostgauge.net                ##
##                                      ##
## 1) login as root or super user       ##
## 2) cd ~                              ##
## 3) create benchmark.sh | copy & save ##
## 4) chmod +X benchmark.sh             ##
## 5) ./benchmark.sh                    ##
##                                      ##
##########################################
##########################################

## - Server Updates | Package Installaion | Initial Setup - ##
echo "The following tests will be conducted: MySQL | Bandwidth | CPU | RAM | HDD I/O. These tests will take approximately fifteen minutes to conduct.  Please wait a moment while we update your system and install the necessary pacakges."
{
yum -y update ca-certificates
yum clean all
yum -y install epel-release
yum -y update
yum -y install mariadb mariadb-server sysbench python wget
systemctl start mariadb
mkdir /root/benchmark
cd ~
} &> /dev/null


## - MySQL Test Database Creation - ##
echo "[1/16] Creating MySQL Test Database - If you have previously setup MySQL/MariaDB, you must perform this manually.  Ensure user/pass match the next section in the script."
echo
{
mysql -u root -e "CREATE DATABASE sysbench;"
mysql -u root -e "CREATE USER 'sysbench'@'localhost' IDENTIFIED BY 'password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON sysbench.* TO 'sysbench'@'localhost' IDENTIFIED  BY 'password';"
} &> /dev/null
echo "[2/16] MySQL Test Database Created"
echo


## - MySQL Test - ##
echo "[3/16] Preparing MySQL Test"
echo
sysbench /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --oltp-table-size=10000000 --mysql-db=sysbench --mysql-user=sysbench --db-driver=mysql --mysql-password=password prepare &> /dev/null
echo "[4/16] Conducting MySQL Test"
echo
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
echo "-----------------------------MySQL Test---------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
sysbench /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --oltp-table-size=10000000 --mysql-db=sysbench --mysql-user=sysbench --db-driver=mysql --time=60 --max-requests=0 --threads=16 --mysql-password=password --oltp-reconnect-mode=random run >> /root/benchmark/benchmark.log
echo "[5/16] Cleaning Up MySQL Test"
echo
sysbench /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --mysql-db=sysbench --mysql-user=sysbench --mysql-password=password --db-driver=mysql cleanup &> /dev/null
echo "[6/16] MySQL Test Complete"
echo


## - Bandwidth Speed Test - ##
echo "[7/16] Conducting Bandwidth Speed Test"
echo
{
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli 
} &> /dev/null
echo "" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------Bandwidth Speed Test----------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
python speedtest-cli --bytes >> /root/benchmark/benchmark.log
rm -f speedtest-cli  &> /dev/null
echo "[8/16] Bandwidth Speed Test Complete and Cleaned"
echo


## - CPU Test - ##
echo "[9/16] Conducting CPU Test"
echo
echo "" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------CPU Test----------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
sysbench cpu --cpu-max-prime=100000 --threads=1 run >> /root/benchmark/benchmark.log
echo "[10/16] CPU Test Complete"
echo


## - RAM Test - ##
echo "[11/16] Conducting RAM Test"
echo
echo "" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
echo "----------------------------RAM Read Test-------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
sysbench memory --memory-block-size=1M --memory-oper=read --memory-total-size=100G run >> /root/benchmark/benchmark.log
echo "" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
echo "---------------------------RAM Write Test-------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
sysbench memory --memory-block-size=1M --memory-oper=write --memory-total-size=100G run >> /root/benchmark/benchmark.log
echo "[12/16] RAM Test Complete"
echo


## - HDD I/O Test - ##
echo "[13/16] Conducting HDD I/O Test - This will take eight minutes"
echo
sysbench fileio --file-total-size=10G --file-num=128 prepare  &> /dev/null
echo "" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
echo "----------------------------HDD Read Test-------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
sysbench fileio --file-total-size=10G --file-num=128 --file-test-mode=rndrd --time=240 --max-requests=0 --file-block-size=4K --threads=16 run  >> /root/benchmark/benchmark.log
echo "" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
echo "---------------------------HDD Write Test-------------------------------" >> /root/benchmark/benchmark.log
echo "------------------------------------------------------------------------" >> /root/benchmark/benchmark.log
sysbench fileio --file-total-size=10G --file-num=128 --file-test-mode=rndwr --time=240 --max-requests=0 --file-block-size=4K --threads=16 run  >> /root/benchmark/benchmark.log
sysbench fileio --file-total-size=10G --file-num=128 cleanup &> /dev/null
echo "[14/16] HDD I/O Test Complete and Cleaned"
echo


## - MySQL Test Database Removal - ##
echo "[15/16] Removing MySQL Test Database - If you have previously setup MySQL/MariaDB, you must perform this manually."
echo
{
mysql -u root -e "DROP DATABASE sysbench;"
mysql -u root -e "DROP USER 'sysbench'@'localhost';"
} &> /dev/null
echo "[16/16] MySQL Test Database Removed"

echo "All Tests Complete - access log file at /root/benchmark/benchmark.log"

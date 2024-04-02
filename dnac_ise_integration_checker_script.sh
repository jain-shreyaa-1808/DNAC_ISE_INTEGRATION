#!/bin/bash

echo "

********************************************************************************************************************************************

This script performs only read actions to collect the data required for troubleshooting issues.No remedial or write actions are performed.

As much as possible, TAC/BU are advised to run this script immediately after the issue is replicated so that the latest info is captured.

IMPORTANT: Prior to running this script, have an RCA generated so that existing data is captured before attempting to reproduce the issue.

********************************************************************************************************************************************

"


###### Variables ######
datapath="/data/tmp/dnac_ise_integration_data"
logpath="$datapath/logdumps"

echo $datapath
###### Create folder to collect data ######
mkdir -p "$datapath"
mkdir -p "$logpath"
echo "done"

###### Read DNAC and ISE IPs and creds from user #######

# read -p "Enter Cisco DNA Center IP: " dnac_ip
# echo "DNAC IP is: $dnac_ip" </dev/tty

# read -p "Enter Cisco DNA Center GUI Username: " dnac_user
# echo "Cisco DNA Center GUI Username is: $dnac_user"

# read -s -p "Enter Cisco DNA Center GUI Password: " dnac_password
# echo -e "\nCisco DNA Center GUI Password is: $dnac_password"
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 ISE IP"
  exit 1
fi

ise_ip=$1

# read -p "Enter ISE IP: " ise_ip
# echo "ISE IP is: $ise_ip"

# read -p "Enter Cisco ISE Username: " ise_user
# echo "Cisco ISE Username is: $ise_user"

# read -s -p "Enter Cisco ISE Password: " ise_password
# echo -e "\nCisco ISE Password is: $ise_password"


###### Collect Service log dumps into files ######

echo "Collecting pxgrid logs"
magctl service logs -r pxgrid >> "$logpath/pxgrid_logs.log"
sleep 1

echo "Collecting ise-bridge logs"
magctl service logs -r ise-bridge >> "$logpath/isebridge_logs.log"
sleep 1

echo "Collecting network design logs"
magctl service logs -r network-design-service  >> "$logpath/nwdesign_logs.log"
sleep 1

echo "Collecting aca controller logs"
magctl service logs -r aca-controller >> "$logpath/aca_logs.log"
sleep 1

echo "Colecting Service Outputs"
echo "========================================= Service Outputs ========================================================== " > "$datapath/dnac_ise_data.log"

echo "magctl appstack status | grep -v -E '([0-9]+)/\1.*Running'" >> "$datapath/dnac_ise_data.log"
magctl appstack status | grep -v -E '([0-9]+)/\1.*Running' >> "$datapath/dnac_ise_data.log"
sleep 1


echo "magctl appstack status | egrep 'ise-bridge|pxgrid|k-d|file-ser|pki|cred'" >> "$datapath/dnac_ise_data.log"
magctl appstack status | egrep 'ise-bridge|pxgrid|k-d|file-ser|pki|cred' >> "$datapath/dnac_ise_data.log"
sleep 1

echo "Colecting Interface Details"
echo "========================================= Interface Details ========================================================== " > "$datapath/dnac_ise_data.log"

echo "\n\nip addr | awk '/^[0-9]+/ { currentinterface=$2 } $1 == "inet" { split( $2, foo, "/" ); print currentinterface ,foo[1] }'" >> "$datapath/dnac_ise_data.log"
ip addr | awk '/^[0-9]+/ { currentinterface=$2 } $1 == "inet" { split( $2, foo, "/" ); print currentinterface ,foo[1] }' >> "$datapath/dnac_ise_data.log"
sleep 1

echo "Colecting ISE Admin Cert"
echo "========================================= ISE Admin Certificate Collection ========================================================== " > "$datapath/ise_certificate.log"

echo "openssl s_client -connect $ise_ip:443 < /dev/null 2>&1 |  sed -n '/-----BEGIN/,/-----END/p' | openssl x509 -text -noout" >> "$datapath/ise_certificate.log"
openssl s_client -connect $ise_ip:443 < /dev/null 2>&1 |  sed -n '/-----BEGIN/,/-----END/p' | openssl x509 -text -noout >> "$datapath/ise_certificate.log"
sleep 1

echo "Colecting NC Outputs"
echo "========================================= NC Outputs ========================================================== " >> "$datapath/dnac_ise_data.log"

echo "nc -zv $ise_ip 22" >> "$datapath/dnac_ise_data.log"
nc -zv -w 2 $ise_ip 22 &>> "$datapath/dnac_ise_data.log"

echo "nc -zv -w 2 $ise_ip 443" >> "$datapath/dnac_ise_data.log"
nc -zv $ise_ip 443 &>> "$datapath/dnac_ise_data.log"

echo "nc -zv -w 2 $ise_ip 443" >> "$datapath/dnac_ise_data.log"
nc -zv $ise_ip 443 &>> "$datapath/dnac_ise_data.log"

echo "nc -zv -w 2 $ise_ip 5222" >> "$datapath/dnac_ise_data.log"
nc -zv $ise_ip 5222 &>> "$datapath/dnac_ise_data.log"

echo "nc -zv -w 2 $ise_ip 8910" >> "$datapath/dnac_ise_data.log"
nc -zv $ise_ip 8910 &>> "$datapath/dnac_ise_data.log"

echo "nc -zv -w 2 $ise_ip 9060" >> "$datapath/dnac_ise_data.log"
nc -zv $ise_ip 9060 &>> "$datapath/dnac_ise_data.log"

#echo "========================================= CURL Outputs ========================================================== " >> "$datapath/dnac_ise_data.log"

#echo "curl http://$dnac_ip/ca/pem to be stored in dnac_cert.pem" >> "$datapath/dnac_ise_data.log"

#curl http://$dnac_ip/ca/pem > "$datapath/dna_cert.pem"

#echo "curl -k https://$dnac_ip/api/v1/aaa/ise/certificate" >> "$datapath/dnac_ise_data.log"

#curl -k https://$dnac_ip/api/v1/aaa/ise/certificate >> "$datapath/dnac_ise_data.log"

#echo "curl -s -k -u $dnac_user:$dnac_password https://$ise_ip/admin/API/PKI/TrustCertificates" >> "$datapath/dnac_ise_data.log"

#curl -s -k -u $dnac_user:$dnac_password https://$ise_ip/admin/API/PKI/TrustCertificates >> "$datapath/dnac_ise_data.log"

echo "Colecting DB Outputs"
echo "========================================= DNAC DB Outputs ========================================================== " >> "$datapath/db_data.log"

echo "pset pager off" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "\pset pager off" > "$datapath/db_data.log"

echo "select * from aaaserversetting;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from aaaserversetting;" >> "$datapath/db_data.log"

echo "select * from identitysource;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from identitysource;" >> "$datapath/db_data.log"

echo "select * from isetrustcertificate;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from isetrustcertificate;" >> "$datapath/db_data.log"

echo "select * from iseversiontocapability;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from iseversiontocapability;" >> "$datapath/db_data.log"

echo "select * from externaliseipaddress;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from externaliseipaddress;" >> "$datapath/db_data.log"

echo "select * from iseintegrationstatus;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from iseintegrationstatus;" >> "$datapath/db_data.log"

echo "select * from globalcredential;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from globalcredential;" >> "$datapath/db_data.log"

echo "select * from commonsetting where key ilike '%pan%';" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from commonsetting where key ilike '%pan%';" >> "$datapath/db_data.log"

echo "select * from commonsetting where type like '%aaa%';" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from commonsetting where type like '%aaa%';" >> "$datapath/db_data.log"


#### ARE THE TABLES BELOW NEEDED?

echo "select * from Serialnumberipaddressmapping;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from Serialnumberipaddressmapping;" > "$datapath/db_data.log"

echo "select * from managedelementinterface;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from managedelementinterface;" >> "$datapath/db_data.log"

echo "select * from deviceinfo;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from deviceinfo;" >> "$datapath/db_data.log"

echo "select * from networkdevice;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from networkdevice;" >> "$datapath/db_data.log"

echo "select * from radiusservergroupentry;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from radiusservergroupentry;" >> "$datapath/db_data.log"

echo "select * from radiusserversettings;" >> "$datapath/db_data.log"
docker exec -it `docker ps | grep postgres_postgres | grep fusion | grep -oP '^\S+'` psql -U appuser -d campus -P pager -c "select * from radiusserversettings;" >> "$datapath/db_data.log"


echo "========================================= Bundling data ========================================================== "

cd /data/tmp/dnac_ise_integration_data && tar cvzf /data/tmp/dnac_ise_$(date +%Y%m%d-%H%M%S).tar.gz .

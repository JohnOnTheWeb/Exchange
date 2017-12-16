# Custom Script for Linux

#!/bin/bash

install_packages7() {
        yum -y install realmd
        yum -y install sssd
        yum -y install krb5-workstation krb5-libs
        yum -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools ntpdate ntp
}


join_domain7() {
        domaincheck=$(realm list | grep active-directory)
        if [[ $domaincheck == *"active-directory"* ]]; then
                echo "Machine is already joined to Domain"
                exit
        fi

        realm discover $ADNAME
        echo $ADPASSWORD | kinit $ADUSERNAME
        echo $ADPASSWORD | realm join -U $ADUSERNAME $ADNAME --computer-ou="$ADOU"



        echo "[sssd]
domains = $ADNAME
config_file_version = 2
services = nss, pam, ssh, autofs

[domain/$ADNAME]
ad_domain = $ADNAME
krb5_realm = $ADREALM
realmd_tags = manages-system joined-with-samba
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%d/%u
access_provider = ad" > /etc/sssd/sssd.conf 

        chmod 600 /etc/sssd/sssd.conf
        service sssd stop
        service sssd start
        chkconfig sssd on



        MachineName="$(hostname)"
        if [[ $MachineName == *"$ADNAME"* ]]; then
                echo "FQDN is already set"
        else
        hostnamectl set-hostname $MachineName.$ADNAME
        sleep 5
        service sssd stop
        service sssd start
        fi
}

ADNAME=$1
ADREALM="${ADNAME^^}"
ADUSERNAME=$2
ADPASSWORD=$3
ADOU=$4

echo "Domain:$ADNAME"
echo "Realm:$ADREALM"
echo "Username:$ADUSERNAME"
echo "OU:$ADOU"


version=$(cat /etc/redhat-release)
if [[ $version == *"7."* ]]; then
    install_packages7
    join_domain7
else
    echo "Incorrect Redhat version for Domain Join"
fi

# Custom Script for Linux

#!/bin/bash

install_packages7() {
	yum clean all
	yum makecache fast
	yum -y install realmd
	echo 'y' | yum update
	yum -y install sssd
	yum -y install krb5-workstation krb5-libs
	yum -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools ntpdate ntp
}

set_hosts() {
echo "Set hosts -------------------------------------------------"
MachineName="$(hostname)"
ShortName=$(hostname -s)

echo "127.0.0.1		$MachineName	$ShortName
::1		$MachineName	$ShortName" > /etc/hosts
}

set_krb5() {
echo "set krb5 --------------------------------------------------"
echo "
includedir /etc/krb5.conf.d/

[logging]
	 default = FILE:/var/log/krb5libs.log
	 kdc = FILE:/var/log/krb5kdc.log
	 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
	 dns_lookup_realm = true
	 dns_lookup_kdc = true
	 ticket_lifetime = 24h
	 renew_lifetime = 7d
	 forwardable = true
	 rdns = false
	 default_realm = $ADREALM
	 default_ccache_name = KEYRING:persistent:%{uid}" > /etc/krb5.conf
}

set_smb() {
echo "set smb ---------------------------------------------------"
echo "[global]
	workgroup = $NETBIOS
	security = ads
	realm = $ADREALM
	passdb backend = tdbsam
	client signing = yes
	client use spnego = yes
	kerberos method = secrets and keytab
	log file = /var/log/samba/%m.log
	password server = $DC1.$ADREALM
	security = ads

	printing = cups
	printcap name = cups
	load printers = yes
	cups options = raw

[homes]
	comment = Home Directories
	valid users = %S, %D%w%S
	browseable = No
	read only = No
	inherit acls = Yes

[printers]
	comment = All Printers
	path = /var/tmp
	printable = Yes
	create mask = 0600
	browseable = No

[print$]
	comment = Printer Drivers
	path = /var/lib/samba/drivers
	write list = root
	create mask = 0664
	directory mask = 0775" > /etc/samba/smb.conf
}

set_sssd() {
echo "set sssd --------------------------------------------------"
echo "[sssd]
	domains = $ADNAME
	config_file_version = 2
	services = nss, pam, ssh, autofs

[domain/$ADNAME]
	id_provider = ad
	auth_provider = ad
	chpass_provider = ad
	access_provider = ad
	cache_credentials = true
	ad_domain = $ADNAME
	krb5_realm = $ADREALM
	realmd_tags = manages-system joined-with-samba

	krb5_store_password_if_offline = true
	default_shell = /bin/bash
	ldap_id_mapping = true
	use_fully_qualified_names = false
	fallback_homedir = /home/%u" > /etc/sssd/sssd.conf 
}

set_hostname() {		

	MachineName="$(hostname)"
	if [[ $MachineName == *"$ADNAME"* ]]; then
			echo "FQDN is already set"
	else
		hostnamectl set-hostname $MachineName.$ADNAME
	fi
}

join_domain7() {		
	echo "join ad ---------------------------------------------------"
	realm discover $ADNAME
	echo $ADPASSWORD | kinit $ADUSERNAME
	echo $ADPASSWORD | realm join -U $ADUSERNAME $ADNAME --computer-ou="$ADOU"
	chown root:root /etc/sssd/sssd.conf
	chmod 600 /etc/sssd/sssd.conf
	systemctl enable sssd.service
	systemctl restart sssd.service
	systemctl daemon-reload
}

join_ad_dns() {
	echo "join addns ------------------------------------------------"
	echo $ADPASSWORD | net -P ads keytab create -w $NETBIOS -U $ADUSERNAME
	echo $ADPASSWORD | net ads join -w $NETBIOS -U $ADUSERNAME
	authconfig --enablemkhomedir --update
	chown root:root /etc/sssd/sssd.conf
	chmod 600 /etc/sssd/sssd.conf
	systemctl enable sssd.service
	systemctl restart sssd.service
	systemctl daemon-reload
}

set_yum_proxy() {
	
	# update value sslverify=1 to sslverify=0
	if cat /etc/yum.repos.d/rh-cloud.repo | grep 'sslverify=1'
        then
            echo 'need to disable sslverify'
            sed -i "s,sslverify=1,sslverify=0" /etc/yum.repos.d/rh-cloud.repo
        else
            echo 'sslverify already disabled'
    fi

	# set enable proxy
	if cat /etc/yum.conf | grep 'enableProxy=1'
	then
			echo 'enable proxy is set'
			cat /etc/yum.conf | grep 'enableProxy'
	else
			echo "enableProxy=1" >> /etc/yum.conf
	fi

	# Set the Proxy if not set, update if not correct
	if cat /etc/yum.conf | grep "httpProxy=http://$1:3128"
	then
			echo 'enable httpProxy is set'
			cat /etc/yum.conf | grep 'httpProxy'
	else
			if cat /etc/yum.conf | grep 'httpProxy'
			then
				URL="httpProxy=http://$1:3128"
				echo $URL
				sed -i "s,httpProxy.*,$URL," /etc/yum.conf
				
				cat /etc/yum.conf | grep 'httpProxy'
			else
				echo "httpProxy=http://$1:3128" >> /etc/yum.conf
				cat /etc/yum.conf | grep 'httpProxy'	
			fi
	fi
}


install_configure_squid() {
	echo "install configure squid ------------------------------------------------"
	echo 'y' | yum install squid
	firewall-cmd --zone=public --add-port=3128/tcp --permanent
	firewall-cmd  --reload

	# Setup the Whitelist
	# The yum repos are also microsoft.com

	echo ".microsoft.com
.opinsights.azure.com
.azure-automation.net
.azurewatsonanalysis-prod.core.windows.net
.windowsupdate.com
.wustat.windows.com
www.freddiemac.com
www.fanniemae.com
www.ginniemae.gov
ship.intex.com" > /etc/squid/sites.whitelist.txt	

	# set squid to listen on IPV4
	if cat /etc/squid/squid.conf | grep 'http_port 3128'
	then
		echo "setting squid to listen on ipv4 address http_port 0.0.0.0:3128"
		sed -i "s,http_port.*,http_port 0.0.0.0:3128," /etc/squid/squid.conf
	fi

	if cat /etc/squid/squid.conf | grep -E "^acl whitelist dstdomain"
	then
		echo "whitelist is already setup"
	else 
		sed -i '/# INSERT YOUR OWN RULE.*$/a acl whitelist dstdomain "/etc/squid/sites.whitelist.txt"\nhttp_access deny !whitelist' /etc/squid/squid.conf
	fi


	if cat /etc/squid/squid.conf | grep -E "^acl localnet src 10.144.143.0/24"
	then
		echo "local subnet is set correctly"
	else 
		sed -i '/# should be allowed/a acl localnet src 10.144.143.0/24' /etc/squid/squid.conf
	fi

	if cat /etc/squid/squid.conf | grep -E "^acl localnet src"
	then
		echo "comment out the default acl localnet, except for the single Subnet"
		echo 'y' | cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
		awk '{if(/^acl localnet src 10.144.143.0.*$/) print $0; else if (/^acl localnet src.*$/) print "#" $0; else print $0}' /etc/squid/squid.conf.bak > /etc/squid/squid.conf
	fi

	# Remove SSL_Ports
	if cat /etc/squid/squid.conf | grep -E "^acl SSL_ports port.*$|^http_access deny CONNECT \!SSL_ports.*$"
	then
		echo "comment out the default acl SSL_ports port"
		echo 'y' | cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
		awk '{if (/^acl SSL_ports port.*$|^http_access deny CONNECT \!SSL_ports.*$/) print "#" $0; else print $0 }' /etc/squid/squid.conf.bak > /etc/squid/squid.conf
	fi

	# Remove Safe_ports
	if cat /etc/squid/squid.conf | grep -E "^acl Safe_ports port.*$|^http_access deny \!Safe_ports.*$"
	then
		echo "comment out the default acl Safe_ports port"
		echo 'y' | cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
		awk '{if (/^acl Safe_ports port.*$|^http_access deny \!Safe_ports.*$/) print "#" $0; else print $0 }' /etc/squid/squid.conf.bak > /etc/squid/squid.conf
	fi

	systemctl enable squid
	systemctl start squid
	#sleep 20
	#Systemctl status squid
	squid -k reconfigure
}

ADNAME=$1
ADREALM="${ADNAME^^}"
NETBIOS=$(echo $ADREALM | cut -d. -f1)
ADUSERNAME=$2
ADPASSWORD=$3
ADOU=$4
DC1=$5
Proxy=$6

echo "Domain:$ADNAME"
echo "Realm:$ADREALM"
echo "Username:$ADUSERNAME"
echo "OU:$ADOU"
echo "DCName:$DC1"
echo "Proxy:$Proxy"

get_sssd() {
	cat /etc/sssd/sssd.conf
}
get_krb5() {
	cat /etc/krb5.conf
}
get_smb() {
	cat /etc/samba/smb.conf
}
get_domain7(){
	echo "--------------------------------------"
	realm discover $ADNAME
	echo "--------------------------------------"
	net ads info

}
get_hosts() {
	cat /etc/hosts
}

version=$(cat /etc/redhat-release)
if [[ $version == *"7."* ]]; then

	set_yum_proxy $Proxy
    install_packages7

	set_hosts
	get_hosts
	
	set_krb5
	get_krb5

	set_sssd
	get_sssd

	set_smb
	get_smb

	set_hostname
	join_domain7

	set_hosts
	get_hosts
	
	join_ad_dns

	install_configure_squid	
else
    echo "Incorrect Redhat version for Domain Join"
fi


#!/bin/bash

#svn
yum -y install subversion
yum -y install mod_dav_svn

#java (required for Jenkins)
yum -y install java

#Jenkins
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum -y install jenkins

#begin firewall rules
#jenkins
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-service=http --permanent

#svn
firewall-cmd --zone=public --add-port=3690/tcp --permanent

firewall-cmd --reload

#end firewall rules

#begin azcopy
yum -y install rh-dotnetcore11
scl enable rh-dotnetcore11 bash

wget -O azcopy.tar.gz https://aka.ms/downloadazcopyprlinux
tar -xf azcopy.tar.gz
./install.sh

#end azcopy


# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/classic/attach-disk for attaching disk to linux vm

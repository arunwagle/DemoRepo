# Index
- [x] Create a multinode cluster 
- [x] IBM Cloud Private (ICP) 

# Create a multinode cluster 

## Step 1: Install VirtualBox 
 - Find the OS which you are running. E.g cat /etc/*release
 ```
CentOS Linux release 7.2.1511 (Core) 
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"

CentOS Linux release 7.2.1511 (Core) 
CentOS Linux release 7.2.1511 (Core) 
 
 ```
 - Download and install VirtualBox for your OS
  - Login as root and run 
  ```
    Run VirtualBox & to see if VirtualBox is installed. If not then run the below
    
    Remove old virtual box
    yum remove VirtualBox-*
    
    cd /etc/yum.repos.d
    wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
    yum --enablerepo=epel install dkms
    yum install VirtualBox-5.2
    
    Install VirtualBox extensions
    wget http://download.virtualbox.org/virtualbox/5.2.0/Oracle_VM_VirtualBox_Extension_Pack-5.2.0.vbox-extpack
```
- Download and install vagrant from https://www.vagrantup.com/downloads.html
 - Run the below commands
   ```
   vagrant plugin install vagrant-hostmanager
   vagrant plugin install puppet
   vagrant plugin install vagrant-puppet-install
   
   ```
# Create a multinode cluster 

## Prerequisites
- Master node setup
  ```
  sudo sysctl vm.max_map_count
  ## Set if less than 262144
  sudo sysctl -w vm.max_map_count=262144
  ```
- Install Python
- Install docker
 - uninstall prev version using 
   ```
   sudo yum remove docker \
                  docker-common \
                  docker-selinux \
                  docker-engine
   ```
 - install process
   ```
  Step1:
  sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
  
  Step2:
  sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

  sudo yum install docker-ce
  
  
   
   ```


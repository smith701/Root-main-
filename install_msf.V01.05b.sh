#!/bin/bash
# -*- sh-basic-offset: 2 -*-

#   Copyright (c) 2017 by VECSYS. All rights reserved.

#   No part of this software may be used or transmitted in any form or
#   by any means without the explicit permission of the author.  In the
#   case that permission is granted to use and/or to modify this
#   software, it is mandatory that this copyright notice appear in all
#   copies. Non-compliance with these terms immediately invalidates the
#   granted permission.

# Name: install_msf.sh
# Description: Media Speech Installation
# Author: S. Bennacef, M. Bredmestre
# Creation: 2017-01-26

# History:

#  version 1.00 2017-01-26 S. Bennacef - Initial version
#  version 1.01 2017-05-04 M. Bredmestre
#  version 1.02 2017-05-12 M. Bredmestre
#  version 1.03 2017-07-25 M. Bredmestre
#  version 1.04 en cours



set -e



#Global variables
_os=
_dist=
_apache=
_work_directory=
_pwd_temp_install=
_msf_root=
_arg=
_ver=
_hostname=

#Version
_ver='"1.3"'

#Program name
_pn=${0##*/}

#Program arguments
_arg=$@

#Script log
jour=$(date +%Y.%m.%d)
heure=$(date +%Hh%Mm%Ss)
logfile=$_pn-$jour-$heure
exec > >(tee /tmp/${logfile}.log)
exec 2>&1




#Hostname
_hostname=${HOSTNAME%%.*}



#Global constant
_line1=$(printf "%0.s." $(seq 1 $(echo $(($(stty size | cut -d' ' -f2)-22)))))
_line2=$(printf "%0.s-" $(seq 1 $(echo $(($(stty size | cut -d' ' -f2)-22)))))
_line3=$(printf "%0.s_" $(seq 1 $(echo $(($(stty size | cut -d' ' -f2)-22)))))
_line4=$(printf "%0.s=" $(seq 1 $(echo $(($(stty size | cut -d' ' -f2)-22)))))
_line5=$(printf "%0.s#" $(seq 1 $(echo $(($(stty size | cut -d' ' -f2)-22)))))
_line6=$(printf "%0.s*" $(seq 1 $(echo $(($(stty size | cut -d' ' -f2)-22)))))


#Variables to put in the configuration file
pkgs_front=
pkgs_back=





# *************************************************************************** #
#                        General purposes functions
# *************************************************************************** #

# =========================================================================== #
# Log (screen)
# =========================================================================== #
Log ()
{
  local msg color
  
  case $1 in
      Infos) color=34; shift;;
      Warning) color=33; shift;;
      Question) color=32; shift;;
      Alerte) color=31; shift;;
      *) color=0;;
  esac
 
  msg="[$(date +'%Y-%m-%d %H:%M:%S')] $*"

  echo -e "\033[$color"m"""$msg""\033[0m" >&2
}

# =========================================================================== #
# AddAbsPath                                                                  #
#	Add absolute path to relative path                                    #
#	1er argument: path relatif                                            #
# =========================================================================== #
AddAbsPath ()
{
  local path=$1

  if [[ ! $path ]] || [[ ${path:0:1} == '/' ]] || [[ ! $PWD ]]; then
    echo $path
  else
    echo $PWD/$path
  fi

  return 0
}

# =========================================================================== #
# Install Package                                                             #
# =========================================================================== #
InstallPackage () 
{
  local cmd installer


  case $_os in
	CentOS) 			installer=yum;;
	RedHatEnterpriseServer)		installer=yum;;
	Ubuntu)				installer=aptitude;;
  esac

  cmd="sudo $installer install $@"
  Log Infos $_line4
  Log Infos "=>  $cmd"
  Log Infos $_line1

  #CONFIRM_INSTALL est configurable dans le fichier de conf
  if [ X$CONFIRM_INSTALL == X"yes" ]; then
	Log Question "Press [Enter] to continue or [Ctrl C] to stop"
	read
  fi
  eval $cmd
  Log Infos $_line4
}



# =========================================================================== #
# CheckArg    (Vérifie les arguments passés au script)                        #
# =========================================================================== #
CheckArg ()
{
  local nb_arg

  #=================================================
  if [[ " $_arg " == *" -help "* ]] || [[ " $_arg " == *" help "* ]]; then
	Help
	exit
  fi
  #=================================================
  nb_arg=$#
  if [ "$nb_arg" -ne 3 ]; then
	Log Alerte "Invalid arguments"
	Help
	exit 1
  fi
  #=================================================
  cfg_file=$(AddAbsPath $2)
  [[ ! -f $cfg_file ]] &&
  { Log Alerte "can't find the configuration file '$cfg_file'"
    exit 1
  }
  Log Infos "load the configuration file '$cfg_file'"
  . $cfg_file

  #=================================================
#  listarg=`getopt -a -o '' -l cfg:,exec: -- "$@"` || exit 1
#
#
#  for arg in $@; do
#    case $arg in
#      --cfg) cfg_file=$(AddAbsPath $2)  #absolutize the configuration file path
#  	[[ ! -f $cfg_file ]] &&
#  	{ Log Alerte "can't find the configuration file '$cfg_file'"
#  	  exit 1
#  	}
#	Log Infos "load the configuration file '$cfg_file'"
#	. $cfg_file
#  	shift 2;;
#  	
#      --exec) 	exec=$2
#  		eval "$exec"
#  		shift 2
#  		;;
#  
#      --) break ;;
#    esac
#
#  done

}


# =========================================================================== #
# CheckPackage                                                                #                
# 	Vérifie la présence d'un paquet; Si absent l'install                  #
# 	1er argument : le nom du paquet à vérifier                            #
# =========================================================================== #
CheckPackage ()
{
  local package
  package=$1	
  if [ "$_os" == "CentOS" ] || [ "$_os" == "RedHatEnterpriseServer" ];then
	set +e
		yum list installed $package 2>&1 >/dev/null
		res=$?	
	set -e	
	if [ $res == 0 ]; then 
		Log Infos "-> $package is installed (ok)"
	else
		Log Warning "-> $package is not installed (nok)"
		if [ X$CONFIRM_INSTALL == X"yes" ]; then
	        	Log Warning "Execute 'yum install $package' ?"
			Log Question "Press [Enter] to continue or [Ctrl C] to stop"
			read 
		fi
		InstallPackage -y $package

	fi
  fi
}
# =========================================================================== #
# Check File&Wget                                                             #
# 	Vérifie la présence d'un fichier; si absent le récupère (wget)        #
# 	1er argument  : le chemin du fichier à vérifier                       #
# 	2ème argument : l'url où le télécharger (avec wget)                   #
# =========================================================================== #
CheckFileWget ()
{
  local file url

  file=$1
  url=$2  	

  Log Infos "Check if $file exist"
  if [ ! -f $file ]; then 
	Log Warning "File $file not exist."
	if [ X$CONFIRM_WGET == X"yes" ]; then
		Log Question "(W)Get $url to $file ?"
		Log Question "Press [Enter] to continue or [Ctrl C] to stop"
		read
	fi
	CheckPackage wget
	sudo wget -N $url -O $file
  else
	Log Infos "File $file exist."
  fi
}

# =========================================================================== #
# SetOS                                                                       # 
# 	Définition de l'OS s'il n'a pas été fixé (forcé) / ficher de conf     #
# 	Aucun argument                                                        #
#	Reste à faire : Sortir les variable _apache et autre                  #
# =========================================================================== #
SetOS ()
{
  local res

  if [ -z "${_os}" ]; then
	Log Warning "OS is unset => Set OS"
	set +e
		which lsb_release > /dev/null  2>&1
		res=$?
	set -e  
	if [ $res != 0 ];then 
		Log Warning "=>redhat-lsb-core is required to set OS"
		if [ X$CONFIRM_INSTALL == X"yes" ]; then
	        	Log Warning "Execute 'yum install redhat-lsb-core' ?"
			Log Question "Press [Enter] to continue or [Ctrl C] to stop"
			read 
		fi

		Log Infos $_line4
		Log Infos "=> sudo yum install -y redhat-lsb-core"
  		Log Infos $_line1
		sudo yum install -y redhat-lsb-core
		Log Infos $_line4
    	fi
	lsb_release -a
   	_os=$(lsb_release -i | awk '{print $3}')
  fi

  #Checking
  if [ $_os == 'CentOS' ] || [ $_os == 'RedHatEnterpriseServer' ]; then
	_dist='centos'
  elif [ $_os == 'Ubuntu' ]; then
	_dist='ubuntu'
  else
	Log "The os distribution '$_os' is not supported"
	exit 1
  fi
  Log "The OS distribution is $_os"
}


# =========================================================================== #
# Set Installer                                                               #
# =========================================================================== #


# =========================================================================== #
# Set Web Server                                                              #
# =========================================================================== #
SetWebServer ()
{
  Log "Set Web Server"
  case $_os in
	CentOS) 			_apache=httpd;;
	RedHatEnterpriseServer)		_apache=httpd;;
	Ubuntu)				_apache=apache2;;
  esac
}

# =========================================================================== #
# Install Web Server                                                          #
# =========================================================================== #
InstallWebServer ()
{
   local HTTPD_MSF_FILE HTTPD_CONFD_FILE

   Log Infos "Install apache ($_apache)"
   InstallPackage -y $_apache
}
# =========================================================================== #
# Install ftp Server                                                          #
# =========================================================================== #
InstallFtpServer ()
{
   Log Infos "Install Ftp Serveur "

   InstallPackage -y pure-ftpd
 

}

# =========================================================================== #
# Install ClusterSSh                                                          #
# =========================================================================== #
InstallClusterSSh ()
{
  Log Infos 'Install ClusterSSH'
  InstallPackage -y make
  CheckFileWget $_download_directory/clusterssh-3.28.tar.gz $MSF_URL/clusterssh-3.28.tar.gz
  #tar xvfz $_msf_root/Download/clusterssh-3.28.tar.gz
  cd $_download_directory
  sudo tar xvfz clusterssh-3.28.tar.gz
  
  InstallPackage -y perl-X11-Protocol
  InstallPackage -y perl-Tk
  InstallPackage -y perl-Pod-Checker
  cd $_download_directory/clusterssh-3.28/
  sudo $_download_directory/clusterssh-3.28/configure
  sudo make install -C $_download_directory/clusterssh-3.28
}


# =========================================================================== #
# Install WPut (dépot des trancriptions chez les clients)                     #
# =========================================================================== #
InstallWPut ()
{
  Log Infos $_line4
  Log Infos 'Install wput'
  Log Infos $_line1
  case $_os in
	CentOS|RedHatEnterpriseServer)	
		set +e
			yum list installed wput 2>&1 >/dev/null
			res=$?	
		set -e	
		if [ ! $res == 0 ]; then 
			#yum list installed wput 2>&1 >/dev/null
			#---> wput  (origine rpmforge->MSF)
			#wget -N $MSF_URL/wput-pre0.6-1.i586.rpm
			#yum install -y ./wput-pre0.6-1.i586.rpm
			CheckFileWget $_download_directory/wput-0.6.1-1.el7.rf.x86_64.rpm $MSF_URL/wput-0.6.1-1.el7.rf.x86_64.rpm
			InstallPackage -y $_download_directory/wput-0.6.1-1.el7.rf.x86_64.rpm
		fi
		;;
	
	Ubuntu)				echo "TODO"; exit1 ;;
  esac
  Log Infos $_line4
}

# =========================================================================== #
# Install RSsh (interdit le ssh mais autorise scp, sftp,rsync)		      #
# =========================================================================== #
InstallRSSh ()
{
  Log Infos $_line4
  Log Infos 'Install rssh'
  Log Infos $_line1
  #---> rssh  (prérequis : wget)   (origine rpmforge->MSF)


  case $_os in
	CentOS|RedHatEnterpriseServer) 		
		if ( ! yum list installed rssh 2>&1 >/dev/null ); then
			CheckFileWget $_download_directory/rssh-2.3.3-2.el7.rf.x86_64.rpm $MSF_URL/rssh-2.3.3-2.el7.rf.x86_64.rpm
			InstallPackage -y $_download_directory/rssh-2.3.3-2.el7.rf.x86_64.rpm
			#InstallPackage -y $MSF_URL/rssh-2.3.3-2.el7.rf.x86_64.rpm
		fi
		sudo sed -i 's/^#allowscp/allowscp/g' /etc/rssh.conf
		sudo sed -i 's/^#allowsftp/allowsftp/g' /etc/rssh.conf
		sudo sed -i 's/^#allowrsync/allowrsync/g' /etc/rssh.conf
	
		;;
	Ubuntu)				echo "TODO";Exit 1;;

  esac
  Log Infos $_line4
}


# =========================================================================== #
# Install FFMpeg                                                              #
# =========================================================================== #
InstallFFMPEG ()
{
  local	atrpms_repository_file
  Log Infos $_line4
  Log Infos 'Install ffmeg'
  Log Infos $_line1

  case $_os in
	CentOS|RedHatEnterpriseServer) 		
		#1ère méthode d'installation
		#atrpms_repository_file=/etc/yum.repos.d/atrpms.repo	
		#echo "[atrpms]" > $atrpms_repository_file
		#echo "name=MSF ATrpms stable el7 x64" >> $atrpms_repository_file
		#echo "baseurl=http://mediaspeech.com/atrpms/stable" >> $atrpms_repository_file
		#echo "gpgcheck=0" >> $atrpms_repository_file
		#echo "enabled=1" >> $atrpms_repository_file
 		#InstallPackage -y ffmpeg	

		#2ème méthode d'installation
		InstallNuxRepository
 		InstallPackage -y ffmpeg	
		;;
	Ubuntu)				echo "TODO";Exit 1;;
  esac
  Log Infos $_line4
}

# =========================================================================== #
# Lame installation                                                           #
# =========================================================================== #
InstallLame ()
{
  local	atrpms_repository_file
  Log Infos $_line4
  Log Infos 'Install lame'
  Log Infos $_line1
  case $_os in
	CentOS|RedHatEnterpriseServer) 		
		#1ère méthode d'installation
		#atrpms_repository_file=/etc/yum.repos.d/atrpms.repo	
		#echo "[atrpms]" > $atrpms_repository_file
		#echo "name=MSF ATrpms stable el7 x64" >> $atrpms_repository_file
		#echo "baseurl=http://mediaspeech.com/atrpms/stable" >> $atrpms_repository_file
		#echo "gpgcheck=0" >> $atrpms_repository_file
		#echo "enabled=1" >> $atrpms_repository_file
 		#InstallPackage -y lame

		#2ème méthode d'installation
		#L'installation du dépot nux-desktop nécessaire à l'intsallation de lame est dans l'install du back
		InstallNuxRepository
 		InstallPackage -y lame
		;;
	Ubuntu)				echo "TODO";Exit 1;;
  esac
  Log Infos $_line4
}

# =========================================================================== #
# Perl installation                                                            #
# =========================================================================== #
InstallPerl ()
{
  
  Log Infos $_line4
  Log Infos 'Perl Installation'
  Log Infos $_line1
  InstallPackage -y perl
  #InstallPackage -y perl-Time-HiRes
  #InstallPackage -y perl-Crypt-SSLeay
  #InstallPackage -y perl-MIME-Lite
  #InstallPackage -y perl-Email-Valid
  #InstallPackage -y perl-XML-LibXML
  #InstallPackage -y perl-Algorithm-Diff

  Log Infos $_line4
}


# =========================================================================== #
# PHP installation                                                            #
# =========================================================================== #
InstallPHP ()
{
  
  Log Infos $_line4
  Log Infos 'Install PHP'
  Log Infos $_line1

  case $_os in
	CentOS|RedHatEnterpriseServer)	

		if [ ! X$force_php_prefix == "X" ]; then
			curl 'https://setup.ius.io/' -o setup-ius.sh
			set +e
				sudo bash setup-ius.sh
			set -e
		fi
		set +e
			sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/ius-archive.repo
		set -e

		InstallPackage -y php$force_php_prefix
		InstallPackage -y php$force_php_prefix-pdo
		InstallPackage -y php$force_php_prefix-cli
		InstallPackage -y php$force_php_prefix-soap
		InstallPackage -y php$force_php_prefix-pear
		InstallPackage -y php$force_php_prefix-process
		InstallPackage -y php$force_php_prefix-xml
		InstallPackage -y php$force_php_prefix-imap
		InstallPackage -y php$force_php_prefix-mbstring
		InstallPackage -y php$force_php_prefix-devel
		InstallPackage -y php$force_php_prefix-common
		set +e
			InstallPackage -y php$force_php_prefix-pecl-ssh2
			InstallPackage -y php$force_php_prefix-mysql
			InstallPackage -y php$force_php_prefix-mysqlnd
			InstallPackage -y mod_php$force_php_prefix
			InstallPackage -y php$force_php_prefix-json

		set -e
		InstallPackage -y php$force_php_prefix-gd   
		InstallPackage -y gd




		;;
	Ubuntu)	
		#....
		echo "-"		
		;;
   esac
  Log Infos $_line4
}


# =========================================================================== #
# PHP Configuration                                                           #
# =========================================================================== #
ConfPHP ()
{

  
  Log Infos $_line4
  Log Infos 'PHP Configuration'
  Log Infos $_line1

  case $_os in
	CentOS|RedHatEnterpriseServer) 		
		php_ini_file=/etc/php.ini 
		;;
	Ubuntu) 
		php_ini_file=/etc/php5/apache2/php.ini
		;;
  esac

  if [ -e $php_ini_file ] ;then
	set +e
		grep 'ixed' $php_ini_file
	  	res=$?
	set -e


	if [ $res == 1 ] ;then
		#we add ixed decoder is not already in php.ini file
 		php_version=`php --version | grep '^PHP'  | awk -F '[ ]' '{print $2;}' | awk -F '[.]' '{print $1"."$2;}'`
		#modifs pour les upload de fichiers, par defaut c'est 8M :/
		sudo sed -i 's/upload_max_filesize/;upload_max_filesize/g' $php_ini_file
		sudo sed -i 's/post_max_size/;post_max_size/g' $php_ini_file
		sudo sed -i "\$aupload_max_filesize = 5000M" $php_ini_file
		sudo sed -i "\$aextension=/home/MSF/bin/sourceguardian/ixed/Linux_x86-64/ixed.$php_version.lin" $php_ini_file
		sudo sed -i "\$aextension=stomp.so" $php_ini_file


		#pour ubuntu en plus il faut modifier le fichier pour les clients php !
		if [ "$_os" == "Ubuntu" ] ;then
			echo "extension=/home/MSF/bin/sourceguardian/ixed/Linux_x86-64/ixed.$php_version.lin" >> /etc/php5/cli/php.ini
			echo "extension=stomp.so" >>  /etc/php5/cli/php.ini
		fi
	fi
  else 
	Log Error "php.ini doesn't exist (ConfPHP / Source Guardian)"
	exit 1


  fi

  Log Infos $_line4

}



# =========================================================================== #
# Stomp installation                                                          #
# module PHP                                                                  #
# =========================================================================== #
InstallStomp ()
{

  Log Infos $_line4
  Log Infos 'Install Stomp'
  Log Infos $_line1
  
  set +e
	pecl info stomp 
  	res=$?
  set -e

  if [ $res == 1 ] ;then 
	echo 'no' | sudo pecl install stomp
  else
  	Log Infos 'Stomp is already installed'
  fi

  Log Infos $_line4

}

# =========================================================================== #
# Source Guardian installation                                                #
# =========================================================================== #
InstallSourceGuardian ()
{

  local dir_install

  #dir_install=/home/MSF/bin/source_guardian81/ixed/Linux_x86-64/
  dir_install=/home/MSF/bin/sourceguardian/ixed/Linux_x86-64/

  Log Infos $_line1
  Log Infos "Licence / Source Guardian"
  Log Infos $_line1
  sudo mkdir -p $dir_install
  #cd $dir_install
  CheckFileWget $_download_directory/loaders.linux-x86_64.zip http://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.zip
  sudo unzip -u $_download_directory/loaders.linux-x86_64.zip -d $dir_install
  
  Log Infos $_line4

}

# =========================================================================== #
# Configuration SELINUX                                                       #
# =========================================================================== #
ConfSeLinux ()
{
  local file_conf
  file_conf=/etc/selinux/config

  if [ "$_os" == "CentOS" ] || [ "$_os" == "RedHatEnterpriseServer" ] ;then
    sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' $file_conf
  fi
  set +e
	sudo setenforce 0
  set -e

}

# =========================================================================== #
# Install Mediaspeech (app / tgz)                                             #
# =========================================================================== #
InstallMSF ()
{
  cd $_work_directory

  Log Infos $_line4
  Log Infos "MSF_$MSF_VERSION(.tgz) installation"
  Log Infos $_line1
  sudo mkdir -p  $_msf_root/tmp
  sudo chmod 777 $_msf_root/tmp
  sudo mkdir -p  $_msf_root/log
  sudo chmod 777 $_msf_root/log
  Log Infos "MSF_$MSF_VERSION.tgz is required"
  CheckFileWget $_download_directory/MSF_$MSF_VERSION.tgz $MSF_URL/MSF_$MSF_VERSION.tgz
  sudo tar xfz $_download_directory/MSF_$MSF_VERSION.tgz -C  /home/MSF/

  Log Infos $_line4
}

# =========================================================================== #
# Installation de Lynx                                                        #
# =========================================================================== #
InstallLynx ()
{
  #L'installation de Lynx est optionnel et configurable via le fichier de conf
  #Commun au FE et BE
  Log Infos $_line4
  Log Infos "Lynx installation"
  Log Infos $_line1

  InstallPackage -y lynx

  Log Infos $_line4
}

# =========================================================================== #
# Installation du client FTP                                                  #
# =========================================================================== #
InstallFTPClient ()
{
  Log Infos $_line4
  Log Infos "FTP client installation"
  Log Infos $_line1
  InstallPackage -y ftp
  Log Infos $_line4
}

# =========================================================================== #
# Configuration des dépots common au front et au back                             #
# =========================================================================== #
ConfRepository_Common ()
{

   Log Infos $_line4
   Log Infos "Configuration repository common"
   Log Infos $_line1
   case $_os in
	CentOS)
		InstallPackage -y epel-release
		;;
	RedHatEnterpriseServer)	
		set +e
			rpm -qa | grep epel-release
		  	res=$?
		set -e

		if [ $res == 1 ]; then
			sudo rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
			#InstallPackage -y https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm
			InstallPackage -y $MSF_URL/epel-release-7-9.noarch.rpm
		fi
		;;

	Ubuntu)	
		#....
		echo "-"		
		;;
   esac
   Log Infos $_line4
}

# =========================================================================== #
# Installation du dépot nux                                                   #
# =========================================================================== #
InstallNuxRepository ()
{

   Log Infos $_line4
   Log Infos "Configuration repository back"
   Log Infos $_line1
   case $_os in
	CentOS|RedHatEnterpriseServer)
		#ici
		res=$(rpm -qa nux-dextop-release)
		if [ X$res = "X" ];	then 
			sudo yum -y install http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
		fi
		;;
	Ubuntu)	
		#....
		echo "-"		
		;;
   esac
   Log Infos $_line4
}


# =========================================================================== #
# Net Tools installation                                                      #
# =========================================================================== #
InstallNetTools ()
{

   Log Infos $_line4
   Log Infos "Net Tools Installation"
   Log Infos $_line1
   case $_os in
	CentOS|RedHatEnterpriseServer)	
		InstallPackage  -y net-tools
		;;
	Ubuntu)	
		#....
		echo "-"		
		;;
   esac
   Log Infos $_line4
}
# =========================================================================== #
# Nis Client installation                                                     #
# =========================================================================== #
InstallNisClient ()
{
   local domain_name_nis name_server_nis
   Log Infos $_line4
   Log Infos "Nis Client Installation"
   Log Infos $_line1
   
		
   case $_os in
	CentOS|RedHatEnterpriseServer)	
		InstallPackage  -y ypbind
		;;

	
	Ubuntu)	
		#....
		echo "-"		
		;;
   esac
   Log Infos $_line4
}

# =========================================================================== #
# Nis Server installation                                                     #
# =========================================================================== #
InstallNisServer ()
{

   Log Infos $_line4
   Log Infos "Nis Server Installation"
   Log Infos $_line1
   case $_os in
	CentOS|RedHatEnterpriseServer)	
		InstallPackage  -y ypserv
		;;
	Ubuntu)	
		#....
		echo "-"		
		;;
   esac
   Log Infos $_line4
}


# =========================================================================== #
# Check settings in configuration file                                        #
# =========================================================================== #
CheckSettings ()
{

if [ X$MSF_VERSION = "X" ] ;	then Log Alerte "MSF_VERSION is not set"; exit 1; fi
if [ X$SLURM_VERSION = "X" ];	then Log Alerte "SLURM_VERSION is not set"; exit 1; fi

if [ X$MSF_URL = "X" ];	then Log Alerte "MSF_URL is not set"; exit 1; fi
if [ X$MSF_PATH = "X" ];	then Log Alerte "MSF_PATH is not set"; exit 1; fi
if [ X$DOWNLOAD_DIRECTORY = "X" ];	then Log Alerte "DOWNLOAD_DIRECTORY is not set"; exit 1; fi


if [ X$PWD_TEMP_INSTALL = "X" ];	then Log Alerte "PWD_TEMP_INSTALL is not set"; exit 1; fi

if [ X$CONFIRM_INSTALL != X"yes" ] && [ X$CONFIRM_INSTALL != X"no" ];	then Log Alerte "CONFIRM_INSTALL is not set (yes or no)"; exit 1; fi
if [ X$CONFIRM_WGET != X"yes" ] && [ X$CONFIRM_WGET != X"no" ];	then Log Alerte "CONFIRM_WGET is not set (yes or no)"; exit 1; fi

if [ X$ftpclient != X"yes" ] && [ X$ftpclient != X"no" ];	then Log Alerte "ftpclient is not set (yes or no)"; exit 1; fi
if [ X$ftpserver != X"yes" ] && [ X$ftpserver != X"no" ];	then Log Alerte "ftpserver is not set (yes or no)"; exit 1; fi
if [ X$ftp_trans_upload != X"yes" ] && [ X$ftp_trans_upload != X"no" ];	then Log Alerte "ftp_trans_upload is not set (yes or no)"; exit 1; fi

if [ X$nisclient != X"yes" ] && [ X$nisclient != X"no" ];	then Log Alerte "nisclient is not set (yes or no)"; exit 1; fi
if [ X$nisserver != X"yes" ] && [ X$nisserver != X"no" ];	then Log Alerte "nisserver is not set (yes or no)"; exit 1; fi

if [ X$cluster_ssh != X"yes" ] && [ X$cluster_ssh != X"no" ];	then Log Alerte "cluster_ssh is not set (yes or no)"; exit 1; fi
if [ X$youtubedl != X"yes" ] && [ X$youtubedl != X"no" ];	then Log Alerte "youtubedl is not set (yes or no)"; exit 1; fi
if [ X$ffmpeg != X"yes" ] && [ X$ffmpeg != X"no" ];	then Log Alerte "ffmpeg is not set (yes or no)"; exit 1; fi
if [ X$lame != X"yes" ] && [ X$lame != X"no" ];	then Log Alerte "lame is not set (yes or no)"; exit 1; fi
if [ X$numpy != X"yes" ] && [ X$numpy != X"no" ];	then Log Alerte "numpy is not set (yes or no)"; exit 1; fi
if [ X$lynx != X"yes" ] && [ X$lynx != X"no" ];	then Log Alerte "lynx is not set (yes or no)"; exit 1; fi
if [ X$rssh != X"yes" ] && [ X$rssh != X"no" ];	then Log Alerte "rssh is not set (yes or no)"; exit 1; fi
if [ X$sudo != X"yes" ] && [ X$sudo != X"no" ];	then Log Alerte "sudo is not set (yes or no)"; exit 1; fi
if [ X$nfs_utils != X"yes" ] && [ X$nfs_utils != X"no" ]; then Log Alerte "nfs_utils is not set (yes or no)"; exit 1; fi
if [ X$modperl != X"yes" ] && [ X$modperl != X"no" ];	then Log Alerte "modperl is not set (yes or no)"; exit 1; fi
if [ X$iptables_services != X"yes" ] && [ X$iptables_services != X"no" ];	then Log Alerte "iptables_services is not set (yes or no)"; exit 1; fi
if [ X$yasm != X"yes" ] && [ X$yasm != X"no" ];	then Log Alerte "yasm is not set (yes or no)"; exit 1; fi
if [ X$perl_ExtUtils_MakeMaker != X"yes" ] && [ X$perl_ExtUtils_MakeMaker != X"no" ];	then Log Alerte "perl_ExtUtils_MakeMaker is not set (yes or no)"; exit 1; fi
}



# *************************************************************************** #
#                          System installation
# *************************************************************************** #

# =========================================================================== #
# InstallCommon                                                               #
#	Install les paquets communs au front-end et au back-end               #
# =========================================================================== #
InstallCommon ()
{
   Log 'Common installation'
   
   cd $_work_directory

   ConfRepository_Common

   InstallPackage -y unzip
   InstallPackage -y bzip2
   InstallPackage -y rsync
   InstallPackage -y wget
   InstallPackage -y ntp


   InstallPackage -y sshpass

   InstallPerl

   InstallNetTools

   InstallMSF


   #--> Client / Base de données / CentOS/RedHat 6 
   #InstallPackage -y mysql
   #(obsolète / remplacé par mariadb)

   #--> Client / Base de données / CentOS/RedHat 7
   InstallPackage -y mariadb

   #--> SourceGuardian
   InstallSourceGuardian
 
   #--> PHP
   InstallPHP

   #--> Stomp
   #gcc nécessaire à l'installation de Stomp
   InstallPackage -y gcc
   InstallStomp

   ConfPHP

   ConfSeLinux

   #Optionnel / paramétrable dans le fichier de conf :
   if [ X$lynx == X"yes" ]; 			then InstallLynx; fi
   if [ X$ftpclient == X"yes" ]; 		then InstallFTPClient; fi
   if [ X$nisclient == X"yes" ]; 		then InstallNisClient; fi


   #Pour Docker	
   if [ X$sudo == X"yes" ]; 			then InstallPackage -y sudo; fi
   if [ X$nfs_utils == X"yes" ]; 		then InstallPackage -y nfs-utils; fi


   if [ X$rssh == X"yes" ];	 		then InstallRSSh; fi	


   InstallPackage -y libxml2-devel

   ConfLocalFirewall
   ConfCommon



}
# =========================================================================== #
# ConfCommon                                                                  #
# =========================================================================== #
ConfCommon ()
{
   #-------------------------------------------------------------------------#
   #Création du groupe msf (s'il n'existe pas déjà)
   #-------------------------------------------------------------------------#
   if [ ! $(getent group msf) ]; then sudo groupadd msf -g 3000 ;fi
   #-------------------------------------------------------------------------# 
 
   #-------------------------------------------------------------------------#
   #Répertoire /users
   #-------------------------------------------------------------------------#
   sudo mkdir -p  /users
   sudo chown :msf /users
   sudo chmod 771 /users

   #chmod g+s /users
   #chmod a+t /users
   #chmod g+w /users

   #-------------------------------------------------------------------------#
   #Création de l'utilisateur msf (s'il n'existe pas déjà)
   #-------------------------------------------------------------------------#
   if [ ! $(getent passwd msf) ]; then 	sudo useradd msf -g msf -u 3000 -d /users/1; fi

   sudo usermod -a -G users msf
   sudo chown :msf /users/1
   sudo chmod 770 /users/1
   sudo chmod g+s /users/1
   #setgid (s) / répertoire => les fichiers créés dans ce répertoire
   # appartiennent au même groupe que le répertoire.
   #-------------------------------------------------------------------------#
   mkdir -p  /home/MSF/log/ 
   sudo chmod 777 /home/MSF/log/ 

   mkdir -p  /home/MSF/tmp/ 
   sudo chmod 777 /home/MSF/tmp/
   #-------------------------------------------------------------------------#
   #recopie le settings s'il n'existe pas encore
   if [ ! -e /home/MSF/www/Toolbox/settings.php ]; then
  	sudo cp /home/MSF/www/Toolbox/settings_defaults.php /home/MSF/www/Toolbox/settings.php
   fi
   #-------------------------------------------------------------------------#
   ConfCron
}

# =========================================================================== #
# Conf Local Firewall                                                         #
# =========================================================================== #
ConfLocalFirewall ()
{
 Log Infos 'Local Firewall configuration'
 #TODO: A faire
 case $_os in
	CentOS|RedHatEnterpriseServer)	
		#sudo systemctl stop firewalld
		#sudo systemctl disable firewalld
		if [ X$iptables_services == X"yes" ];	then InstallPackage -y iptables-services; 	fi
		;;
	Ubuntu)	echo "-";;
   esac

}


# =========================================================================== #
# Front-End installation                                                      #
# =========================================================================== #
InstallFront ()
{
   Log Infos 'Frontend installation'
   cd $_work_directory

   #-------------------------------------------------------------------------
   #Installation des paquets obligatoires pour le Front-End
   InstallPackage -y mariadb-server
   InstallPackage -y mariadb-devel

   SetWebServer
   InstallWebServer

   #-------------------------------------------------------------------------
   #Configuration Front-End
   ConfDB
   ConfWebServer
   ConfFront



   #-------------------------------------------------------------------------
   #Optionnel / paramétrable dans le fichier de conf :
   if [ X$cluster_ssh == X"yes" ];	then InstallClusterSSh;		fi
   if [ X$ftpserver == X"yes" ];	then InstallFtpServer; ConfFTPServer;	fi
   if [ X$youtubedl == X"yes" ];	then InstallPackage -y youtube-dl; 	fi
   if [ X$modperl == X"yes" ];		then InstallPackage -y mod_perl; 	fi
   if [ X$nisserver == X"yes" ]; 	then InstallNisServer; fi


}
# =========================================================================== #
# Front-End Configuration                                                     #
# =========================================================================== #
ConfFront ()
{
   Log Infos 'Front-end Configuration'

   #mkdir -p  /home/MSF/log/ 
   #chmod 777 /home/MSF/log/ 

   sudo mkdir -p  /home/MSF/www/smarty/templates_c
   sudo chmod 777 /home/MSF/www/smarty/templates_c

   sudo mkdir -p  /home/MSF/www/html/tmp
   sudo chmod 777 /home/MSF/www/html/tmp
   sudo ln -sf /home/MSF/www/scripts /home/MSF/

   sudo mkdir -p  /home/MSF/www/html/scripts/files
   sudo chmod 777 /home/MSF/www/html/scripts/files



}

# =========================================================================== #
# Back-End installation                                                       #
# =========================================================================== #
InstallBack ()
{
   Log Infos 'Back-end installation'
   #-------------------------------------------------------------------------
   #Installation des paquets obligatoires pour le Back-End
   InstallWPut
   InstallPackage -y sox
   #-------------------------------------------------------------------------
   #Configuration Back-End
   ConfBack

   #-------------------------------------------------------------------------
   #Installation des paquets optionnels pour le Back-End
   if [ X$numpy == X"yes" ];		then InstallPackage -y numpy;	fi
   if [ X$ffmpeg == X"yes" ];		then InstallFFMPEG;		fi
   if [ X$lame == X"yes" ];		then InstallLame;		fi
   #-------------------------------------------------------------------------
   


}
# =========================================================================== #
# Front-Back Configuration                                                     #
# =========================================================================== #
ConfBack ()
{
   Log Infos 'Back-end Configuration'

   sudo mkdir -p /Audio
   #chmod 771 /Audio
   sudo chgrp msf /Audio
   sudo chmod 2773 /Audio
   sudo mkdir -p /Models
   sudo chmod 771 /Models
   sudo chgrp msf /Models

   sudo mkdir -p /usr/local/vecsys/trans

}


# =========================================================================== #
# FTP Server Configuration                                                    #
# =========================================================================== #
ConfFTPServer ()
{
   local dir_confftpd
   dir_confftpd="/etc/pure-ftpd/"
   daemon_ftp_upload="daemon_ftp_upload.php"

   Log Infos 'FTP Server Configuration'
   if [ ! -d $dir_confftpd ]; then
	Log Warning "-> FTPs server is not installed => Nothing will be done"
   else

	if [ X$ftp_trans_upload == X"yes" ];then

		Log Infos "allow ftp upload completion script"
		Log Infos "starting upload completion script"
		sudo /usr/sbin/pure-uploadscript -B -r /home/MSF/www/scripts/system/pure-ftpd/$daemon_ftp_upload

		Log Infos "Adding  upload completion script to : /etc/rc.local"
		#echo "/usr/sbin/pure-uploadscript -B -r /home/MSF/www/scripts/system/pure-ftpd/$daemon_ftp_upload" >> /etc/rc.local
		sudo sh -c "echo /usr/sbin/pure-uploadscript -B -r /home/MSF/www/scripts/system/pure-ftpd/$daemon_ftp_upload >> /etc/rc.local"

		sudo chmod u+x /etc/rc.local

		sudo sed -i 's/#CallUploadScript/CallUploadScript/g' /etc/pure-ftpd/pure-ftpd.conf


	fi

	Log Infos 'FTP Server Stop'
	sudo systemctl stop pure-ftpd

	Log Infos 'FTP Server Start'
	sudo systemctl start pure-ftpd

	sudo systemctl enable pure-ftpd	


   fi
}

# =========================================================================== #
# Configuration Cron                                                          #
# =========================================================================== #
ConfCron ()
{
  Log Infos $_line4
  Log Info 'Cron configuration'
  Log Infos $_line1
  if [ ! -f /etc/cron.hourly/daemon_cron_cleaning ]; then
	sudo ln -s /home/MSF/www/scripts/system/daemon_cron_cleaning.php /etc/cron.hourly/daemon_cron_cleaning
  fi
  Log Infos $_line4
}

# =========================================================================== #
# Install Slurm                                                               #
#	Install ce qui est nécessaire à Slurm                                 #
#	Reste à faire : sortir (dans une autre fonction ?)la conf Slurm ?     #
# =========================================================================== #
InstallSlurm ()
{
  local url_download_slurm


  Log Infos $_line4
  Log Infos 'Slurm installation'
  Log Infos $_line1

  #InstallPackage -y make
  #InstallPackage -y gcc

  InstallPackage -y wget

  sudo mkdir -p $_msf_root/slurm
  sudo mkdir -p $_msf_root/Download

  
  CheckFileWget $_msf_root/slurm/slurm.conf $MSF_URL/slurm/slurm.conf
  CheckFileWget $_msf_root/slurm/slurmdbd.conf $MSF_URL/slurm/slurmdbd.conf
  CheckFileWget $_msf_root/slurm/slurm_accounting.cfg $MSF_URL/slurm/slurm_accounting.cfg
  CheckFileWget $_msf_root/slurm/deploie_slurm.sh $MSF_URL/slurm/deploie_slurm.sh
  CheckFileWget $_msf_root/slurm/commands.txt $MSF_URL/slurm/commands.txt
  CheckFileWget $_msf_root/slurm/test.sh $MSF_URL/slurm/test.sh


  #wget -N $MSF_URL/slurm/slurm.conf
  #wget -N $MSF_URL/slurm/slurmdbd.conf
  #wget -N $MSF_URL/slurm/slurm_accounting.cfg
  #wget -N $MSF_URL/slurm/deploie_slurm.sh

  ##wget -N $MSF_URL/slurm/init.d_slurm
  ##wget -N $MSF_URL/slurm/init.d_slurmdbd
  ##wget -N $MSF_URL/slurm/slurmdbd.service
  ##wget -N $MSF_URL/slurm/slurm.service

  #wget -N $MSF_URL/slurm/commands.txt
  #wget -N $MSF_URL/slurm/test.sh


  sudo chmod a+x $_msf_root/slurm/*.sh


  #création du groupe et utilisateur slurm (s'ils n'existent pas)
  if [ ! $(getent group slurm) ]; then groupadd slurm -g 300 ;fi
  if [ ! $(getent passwd slurm) ]; then useradd slurm -g slurm -u 300 ;fi
  #usermod -a -G msf slurm



  #Installation des paquets suivants l'OS
  case $_os in
	CentOS|RedHatEnterpriseServer)
		InstallPackage -y epel-release
		#InstallPackage -y openssl-devel
		InstallPackage -y munge
		#InstallPackage -y munge-devel
		InstallPackage -y munge-libs

		#InstallPackage -y rpm-build

		#InstallPackage -y readline-devel
		#InstallPackage -y pam-devel

		#InstallPackage -y gcc-c++
		#InstallPackage -y cpp

		if [ X$yasm == X"yes" ];			then InstallPackage -y yasm			;	fi
		if [ X$perl_ExtUtils_MakeMaker == X"yes" ];	then InstallPackage -y perl-ExtUtils-MakeMaker	;	fi

		#yum install -y perl-Switch  / pour slurm ?


		sudo mkdir -p $_download_directory/slurm/
		
		url_download_slurm='http://mediaspeech.com/VecsysInstallTools/slurm/rpm'

		CheckFileWget $_download_directory/slurm/slurm-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-contribs-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-contribs-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-devel-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-devel-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-munge-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-munge-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-openlava-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-openlava-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-pam_slurm-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-pam_slurm-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-perlapi-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-perlapi-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-plugins-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-plugins-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-slurmdbd-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-slurmdbd-$SLURM_VERSION.el7.centos.x86_64.rpm
		CheckFileWget $_download_directory/slurm/slurm-sql-$SLURM_VERSION.el7.centos.x86_64.rpm $url_download_slurm/slurm-sql-$SLURM_VERSION.el7.centos.x86_64.rpm

		#find $_msf_root/slurm/rpm/$SLURM_VERSION/ -name "slurm*$SLURM_VERSION*rpm" | xargs yum install -y

		#InstallPackage -y $_download_directory/slurm/slurm*$SLURM_VERSION*.rpm
		set +e
			InstallPackage -y $_download_directory/slurm/slurm-plugins-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-pam_slurm-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-contribs-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-perlapi-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-devel-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-munge-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-sql-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-slurmdbd-$SLURM_VERSION.el7.centos.x86_64.rpm
			InstallPackage -y $_download_directory/slurm/slurm-openlava-$SLURM_VERSION.el7.centos.x86_64.rpm
		set -e
		;;
	Ubuntu)
		#TODO

		InstallPackage -y slurm-llnl
		InstallPackage -y slurm-llnl-slurmdbd
		InstallPackage -y slurm-llnl-basic-plugins
		;;

  esac

   #mkdir -p /opt/slurm/spool/state
   sudo mkdir -p /var/log/slurm/
   sudo mkdir -p /home/MSF/slurm/spool/state
   sudo chown -R slurm:slurm $_msf_root/slurm
   #chown -R slurm:slurm /opt/slurm
   sudo chmod 777 $_msf_root/slurm
   sudo chmod 777 $_msf_root/slurm/spool
   sudo chmod 775 $_msf_root/slurm/spool/state
   #mkdir -p /var/run/slurm
   #chown -R slurm:slurm /var/run/slurm

  if [ "$_os" == "CentOS" ] || [ "$_os" == "RedHatEnterpriseServer" ] ;then
	#setfacl -m slurm:rwx /opt/slurm/spool/state
	sudo setfacl -m slurm:rwx /var/log/slurm/
	#setfacl -m slurm:rwx /var/run
	#A voir si ch
	#Si erreur : setfacl: /var/run: Operation not supported
	#Editer  /etc/fstab et ajouter “defaults,acl” pour le montage de / et remonter « mount / -o remount »
  fi

  #sur Ubuntu l'install de Slurm impose le chemin pour le fichier pid, on change donc notre conf
  if [ "$_os" == "Ubuntu" ]  ;then
	sed -i 's/\/var\/run\//\/var\/run\/slurm-llnl\//g'  /etc/slurm-llnl/slurm.conf
	sed -i 's/\/var\/run\//\/var\/run\/slurm-llnl\//g'  /etc/slurm-llnl/slurmdbd.conf
  fi

  Log Infos $_line3
  Log Infos "create munge.key"
  Log Infos $_line3
  sudo dd if=/dev/urandom bs=1 count=1024 of=/etc/munge/munge.key
  sudo chmod g-w /var/run
  sudo chmod g-w /run/munge
  sudo chown munge:munge /etc/munge/munge.key
  sudo chmod 700 /etc/munge/munge.key
  #echo "Copy the munge.key in /etc/munge/ before starting munge !!!!"
  if [ "$_os" == "CentOS" ] || [ "$_os" == "RedHatEnterpriseServer" ] ;then
	sudo systemctl enable munge
	sudo systemctl start munge
  fi
  if [ "$_os" == "Ubuntu" ] ;then
	/etc/init.d/munge start
	chmod g-w /var/log
  fi

  echo "Check if Munge is started, to start type : systemctl start munge"
  echo "edit          : systemctl edit --system --full munge"
  echo "change        : ExecStart=/usr/sbin/munged --syslog"
  echo "file location : /lib/systemd/system/munge.service"
  echo "ATTENTION in the same file pid MUST be /var/run/slurmXX.pid"
  Log Infos $_line3
  Log Infos "logrotate configuration for slurm"

  sudo sh -c "echo '/var/log/slurm/slurmctld.log {' > /etc/logrotate.d/slurm"
  sudo sh -c "echo 'weekly' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo 'notifempty' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo 'compress' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo 'missingok' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo '}' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo >> /etc/logrotate.d/slurm"
  sudo sh -c "echo '/var/log/slurm/slurmdbd.log {' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo 'weekly' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo 'compress' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo 'notifempty' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo 'missingok' >> /etc/logrotate.d/slurm"
  sudo sh -c "echo '}' >> /etc/logrotate.d/slurm"

  Log Infos "Rsyslog restart"
  sudo systemctl restart rsyslog

  if [ "$_os" == "Ubuntu" ] ;then
	cp /home/MSF/slurm/*.conf /etc/slurm-llnl/
	sacctmgr load -i $_msf_root/slurm/slurm_accounting.cfg
	/etc/init.d/slurm-llnl start
	/etc/init.d/slurm-llnl-slurmdbd start
  fi

  if [ "$_os" == "CentOS" ] || [ "$_os" == "RedHatEnterpriseServer" ] ;then
	Log Infos "Copy the config files to /etc/slurm"
	sudo cp $_msf_root/slurm/*.conf /etc/slurm/

	if [[ " $_arg " == *" install-front "* ]] || [[ " $_arg " == *" all "* ]]; then 
		Log Infos "Start slurmdbd"
		sudo systemctl enable slurmdbd
		sudo systemctl start slurmdbd

		sudo systemctl status slurmdbd
   
		Log Infos "load default config"
		set +e
			sudo sacctmgr load -i $_msf_root/slurm/slurm_accounting.cfg
			res=$?
		set -e
		while [ ! $res == 0 ]; do
			Log Alerte "sacctmgr load -i $_msf_root/slurm/slurm_accounting.cfg failed"
			Log Question "Press [Enter] to retry and continue or [Ctrl C] to stop"
			read
			set +e
				sudo sacctmgr load -i $_msf_root/slurm/slurm_accounting.cfg
				res=$?
			set -e
		done
	
		Log Infos "Start slurmctld"
		sudo systemctl enable slurmctld
		sudo systemctl start slurmctld
	fi


	if [[ " $_arg " == *" install-back "* ]] || [[ " $_arg " == *" all "* ]]; then 
		Log Infos "Start slurmd"
		sudo systemctl enable slurmd
		sudo systemctl start slurmd
	fi

        
  fi



  #we have to build SLURM before the installation
  #Log Warning "Build slurm in normal mode, if the execution of slurm gives segfault, try  rpmbuild -tb -D 'with_cflags CFLAGS=\"-O0 -g3\"' slurm-$SLURM_VERSION.tar.bz2"

  #cree les liens pour le démarrage auto
  #normalement il ne faut pas le faire , mais cela arrive que slurm ne démarre pas tout seul
  #ln -s /etc/systemd/system/slurm.service /etc/systemd/system/default.target.wants
  #ln -s /etc/systemd/system/slurmdbd.service /etc/systemd/system/default.target.wants


  #Spool directory
  #Why
  #mkdir -p /opt/slurm/spool/state 
  #mkdir -p /home/MSF/slurm/spool/state

  #Log

  #mkdir -p /var/log/slurm/
  sudo mkdir -p /var/run/slurm
  sudo chown -R slurm:slurm /var/run/slurm

  sudo chown -R slurm:slurm $_msf_root/slurm
  #chown -R slurm:slurm /opt/slurm  #why ?

  sudo chmod 777 $_msf_root/slurm
  sudo chmod 777 $_msf_root/slurm/spool
  sudo chmod 775 $_msf_root/slurm/spool/state

  Log Infos $_line4

}


# =========================================================================== #
# Slurm configuration                                                         #
#	Configuration de slurm                                                #
# =========================================================================== #
ConfSlurm ()
{
  Log Infos $_line4
  Log Infos 'Slurm configuration'
  Log Infos $_line1
  if [ ! $(getent group slurm) ]; then
	Log Infos 'Create slurm group with gid 300'
	sudo groupadd slurm -g 300
  else 
	Log Infos 'Set gid group 300 to slurm'
	sudo groupmod -g 300 slurm
  fi


  if [ ! $(getent passwd slurm) ]; then
	Log Infos 'Create slurm user with uid 300 and gid 300'
	sudo useradd slurm -g slurm -u 300
  fi

  Log Infos $_line4
}



# =========================================================================== #
# Conf Data Base                                                              #
#	Configuration de la base de données                                   #
# =========================================================================== #
ConfDB ()
{
  Log Infos "DataBase configuration..."
  sudo systemctl enable mariadb
  sudo systemctl start mariadb
  sudo systemctl status mariadb
  #on supprime la limitation d'accès juste à localhost
  #sed -i 's/bind-address/\#bind-address/g' /etc/mysql/mysql.conf.d/mysqld.cnf
  #sed -i 's/bind-address/\#bind-address/g' /etc/mysql/mariadb.conf.d/mysqld.cnf

  set +e
	mysql --version
	res=$?
  set -e  
  if [ ! X$res == X0 ]; then
	Log Warning "    DataBase is not installed."
	Log Warning "    Exit DataBase configuration."
	return 0
  fi

  set +e
	sql_version=$(echo ' SELECT VERSION();' | mysql | tail -n 1)
  set -e
  if [ X$sql_version == X ]; then
	Log Warning "     DataBase is already configured."
	Log Warning "     Exit DataBase configuration."
	return 0
  fi

  Log Infos "     Check if MSF Database exist"
  if [[ ! $(echo "SHOW DATABASES LIKE 'msf';" | mysql | grep "msf") ]]; then 
	Log Infos "Create MSF Database"
	mysql < /home/MSF/www/scripts/system/mysql/MSF_nouvelle_structure.sql
  fi


  Log Infos "Set the default DataBase password with temporary password for install"
  Log Infos "MySQL Version : $sql_version"
  case $sql_version in
	5.5*) 
	   	echo "INSERT INTO mysql.user set host='%' ,user='root', password=PASSWORD('$_pwd_temp_install');" | mysql
		echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by '$_pwd_temp_install' with grant option;" | mysql
		echo "UPDATE mysql.user SET Password = PASSWORD('$_pwd_temp_install') WHERE User = 'root';" | mysql
		echo "flush privileges;" | mysql
		Log Infos "user root@% added and password changed for MySql version $sql_version"
		;;
	5.7*) 
		echo "CREATE USER 'root'@'%' IDENTIFIED BY '$_pwd_temp_install';" | mysql
		echo "GRANT ALL PRIVILEGES ON *.* TO  'root'@'%' WITH GRANT OPTION;" | mysql
		echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD($_pwd_temp_install);" | mysql
		#echo "flush privileges;" | mysql -p$_pwd_temp_install
		echo "flush privileges;" | mysql
		Log Infos "user root@% added and password changed for MySql version $sql_version"
		;;
	"")
		Log Infos "user root@% added and password is already set"
		;;

	*)
		Log Alerte "SQL Version unknown"
		echo "CREATE USER 'root'@'%' IDENTIFIED BY '$_pwd_temp_install';" | mysql
		echo "GRANT ALL PRIVILEGES ON *.* TO  'root'@'%' WITH GRANT OPTION;" | mysql
		echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD($_pwd_temp_install);" | mysql
		#echo "flush privileges;" | mysql -p$pwd1DB
		echo "flush privileges;" | mysql
		Log Infos "user root@% added and password changed for MySql version $sql_version"
		;;
  esac

   #si ERREUR 
   #GROUP BY clause; this is incompatible with sql_mode=only_full_group_by'
   # taper sous mysql
   #    SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
}
# =========================================================================== #
# Conf Apache                                                                 #
# =========================================================================== #
ConfWebServer ()
{
  local CENTOS_VERSION

  Log Infos 'ConfWebServer'
   case $_os in
	CentOS|RedHatEnterpriseServer)	
		sudo usermod -a -G msf apache
		HTTPD_MSF_FILE=/etc/httpd/conf.d/msf.conf
		;;
	Ubuntu)	
		usermod -a -G msf www-data
		HTTPD_MSF_FILE=/etc/apache2/conf-available/msf.conf

		;;
    esac

   if [ ! -e $HTTPD_MSF_FILE ] ;then
	sudo sh -c "echo Alias /webservice /home/MSF/www/webservice > $HTTPD_MSF_FILE"
	sudo sh -c "echo '<Directory /home/MSF/www/webservice/>' >> $HTTPD_MSF_FILE"
	sudo sh -c "echo order deny,allow >> $HTTPD_MSF_FILE"
	sudo sh -c "echo deny from all >> $HTTPD_MSF_FILE"
	sudo sh -c "echo allow from all >> $HTTPD_MSF_FILE"
	sudo sh -c "echo Require all granted >> $HTTPD_MSF_FILE"
	sudo sh -c "echo '</Directory>' >> $HTTPD_MSF_FILE"
	sudo sh -c "echo Alias /rest /home/MSF/www/rest >> $HTTPD_MSF_FILE"
	sudo sh -c "echo '<Directory /home/MSF/www/rest/>' >> $HTTPD_MSF_FILE"
	sudo sh -c "echo order deny,allow >> $HTTPD_MSF_FILE"
	sudo sh -c "echo deny from all >> $HTTPD_MSF_FILE"
	sudo sh -c "echo allow from all >> $HTTPD_MSF_FILE"
	sudo sh -c "echo Require all granted >> $HTTPD_MSF_FILE"
	sudo sh -c "echo '</Directory>' >> $HTTPD_MSF_FILE"

  fi


   case $_os in
	CentOS|RedHatEnterpriseServer)	
		#sudo usermod -a -G msf apache
		HTTPD_CONFD_FILE=/etc/httpd/conf/httpd.conf
		if [ ! -e $HTTPD_CONFD_FILE.msf.bak ] ;then
			if [ -e $HTTPD_CONFD_FILE ] ;then
				sudo cp $HTTPD_CONFD_FILE $HTTPD_CONFD_FILE.msf.bak  
				sudo sed -i 's/DocumentRoot/#DocumentRoot/g' $HTTPD_CONFD_FILE
				sudo sh -c "echo >> $HTTPD_CONFD_FILE"
				sudo sh -c "echo NameVirtualHost *:80 >> $HTTPD_CONFD_FILE"
			fi
			sudo sh -c "echo >> $HTTPD_CONFD_FILE"
			#sudo sh -c "echo NameVirtualHost *:80 >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo '<VirtualHost *:80>' >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo ServerName MSF >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo DocumentRoot /home/MSF/www/html >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo '<Directory /home/MSF/www/html>' >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo AllowOverride All >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo Order allow,deny >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo Allow from all >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo Require all granted >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo '</Directory>' >> $HTTPD_CONFD_FILE"
			sudo sh -c "echo '</VirtualHost>' >> $HTTPD_CONFD_FILE"

		fi
		;;
	Ubuntu)	
		ln -s $HTTPD_MSF_FILE /etc/apache2/conf-enabled/
                #supprime le site par défaut
		rm -f /etc/apache2/conf-enabled/000-default.conf


		HTTPD_CONFD_FILE=/etc/apache2/sites-available/msf.conf


		cp $HTTPD_CONFD_FILE $HTTPD_CONFD_FILE.msf.bak
		if [ -e $HTTPD_CONFD_FILE ] ;then
			rm -f /etc/apache2/sites-enabled/000-default.conf
			ln -s $HTTPD_CONFD_FILE /etc/apache2/sites-enabled/
		fi
		;;
    esac
 

  #----------------  WSDL / Fichier de description des web service
  if [ ! -L /usr/bin/wsdl ] ;then
	sudo chmod a+x /home/MSF/www/html/wsdl-writer/bin/wsdl 
	sudo ln -s /home/MSF/www/html/wsdl-writer/bin/wsdl /usr/bin/wsdl
  fi
  
  
  sudo chown -R apache:apache /home/MSF/www/*
  #TODO : 
  #chmod a+x /home/MSF/www/scripts/*
  #=> Erreur chmod: impossible d'opérer sur un lien symbolique ballant « /home/MSF/www/scripts/scripts »





  if [ ! -L /home/MSF/www/scripts ] ;then
	echo "-"
	#TODO:
	#ln -s /home/MSF/scripts/ /home/MSF/www/scripts
  fi

  case $_os in
	CentOS|RedHatEnterpriseServer)
 		CENTOS_VERSION=$(lsb_release -sr | cut -c -1)
		case $CENTOS_VERSION in	
			7)
				sudo systemctl enable httpd 
				sudo systemctl restart httpd 
				;;
			6)
	
				chkconfig httpd  on
				service httpd  restart
				;;
		esac
		;;
  esac
	




}
# =========================================================================== #
# Conf Sudoers                                                                #
# =========================================================================== #
ConfSudoers ()
{

  local sudoers_file apache_username
  Log Infos 'ConfSudoers'


  #sudoers_file='/etc/sudoers'
  #set +e
  #	grep 'msfdev' $sudoers_file > /dev/null
  #	res=$?
  #set -e
  #if [ $res == 0 ]; then 
  #  Log Infos 'no change done to $sudoers_file' 
  #  return
  #fi
  #cp $sudoers_file $sudoers_file.bak
  #chmod +w $sudoers_file

  case $_os in
	CentOS|RedHatEnterpriseServer)
		apache_username=apache
		;;
	Ubuntu)
		apache_username=www-data
		#TODO: traiter le cas où c'est répété
		echo 'Defaults visiblepw'  >> $sudoers_file
		;;
  esac



#cat > /etc/sudoers.d/msf << EOF
 
#  Cmnd_Alias SLURM = /usr/bin/squeue, /usr/bin/sbatch, /usr/bin/sacctmgr, /usr/bin/scancel
#  $apache_username ALL= NOPASSWD: SLURM
#  $apache_username ALL= NOPASSWD: /bin/chmod
#  $apache_username ALL= NOPASSWD: /bin/mkdir
#  $apache_username ALL= NOPASSWD: /bin/chown
#  $apache_username ALL= NOPASSWD: /bin/grep
#  $apache_username ALL= NOPASSWD: /usr/sbin/useradd
#  $apache_username ALL= NOPASSWD: /usr/sbin/userdel
#  $apache_username ALL= NOPASSWD: /usr/sbin/usermod
#  $apache_username ALL= NOPASSWD: /usr/bin/make
#  $apache_username ALL= NOPASSWD: /usr/sbin/chpasswd
#  $apache_username ALL= NOPASSWD: /usr/bin/passwd
#  $apache_username ALL= NOPASSWD: /bin/su


  #ALL ALL= NOPASSWD: /usr/bin/rsync
  #ALL ALL= NOPASSWD: /usr/bin/ssh
  #ALL ALL= NOPASSWD: /usr/bin/df
#  $apache_username ALL= NOPASSWD: /usr/bin/rm
#  $apache_username ALL= NOPASSWD: /usr/bin/nohup
#  $apache_username ALL= NOPASSWD: /usr/bin/kill
#EOF

  sudo sh -c "echo 'Cmnd_Alias SLURM = /usr/bin/squeue, /usr/bin/sbatch, /usr/bin/sacctmgr, /usr/bin/scancel' > /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: SLURM' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /bin/chmod' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /bin/mkdir' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /bin/chown' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /bin/grep' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/sbin/useradd' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/sbin/userdel' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/sbin/usermod' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/bin/make' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/sbin/chpasswd' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/bin/passwd' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /bin/su' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/bin/rm' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/bin/nohup' >> /etc/sudoers.d/msf"
  sudo sh -c "echo '$apache_username ALL= NOPASSWD: /usr/bin/kill' >> /etc/sudoers.d/msf"





  #sed -i 's/Defaults  *requiretty/\#Defaults requiretty/g' $sudoers_file
  #chmod -w $sudoers_file
}


# =========================================================================== #
# ToDoPostInstall                                                             #
# =========================================================================== #
ToDoPostInstall ()
{
  Log Warning $_line5
  Log Warning "To do : "

  if [[ " $_arg " == *" install-front "* ]] || [[ " $_arg " == *" install-back "* ]] || [[ " $_arg " == *" all "* ]]; then 
	  Log Warning "     Licence MSF : -> /home/MSF/LICENCES/msf.lic"
	  Log Warning "     Licence VTK : -> /etc/vtk.lic"
  fi
  if [[ " $_arg " == *" install-Front "* ]] || [[ " $_arg " == *" all "* ]]; then 
	  Log Warning "     Initialisation du compte msf"
	  Log Warning "     	Changer le mot de passe de l'utilisateur dans l'application."
	  Log Warning "     	Processing Information (Slurm)"

  fi

  if [[ " $_arg " == *" install-back "* ]] || [[ " $_arg " == *" all "* ]]; then 
	  Log Warning "     Moteur de transcription	-> tar xvzf dist-obf_vtk_bin_v?.?.tgz 		-C /usr/local/vecsys/trans"
	  Log Warning "     Diarization			-> tar xvzf dist-obf_vtk_spkrdia_?_v?.?.tgz 	-C /usr/local/vecsys/trans"
	  Log Warning "     Modèle(s) standard(s)	-> tar xvzf dist-obf_vtk_trans_???-??_v?.?.tgz 	-C /usr/local/vecsys/trans"
	  Log Warning "     Modèle(s) spécifique(s) 	-> tar xvzf dist-obf_vtk_trans_???????????.tgz 	-C /usr/local/vecsys/trans"
  fi
  Log Warning $_line5

}

# =========================================================================== #
# Help                                                                        #
#	Affiche l'aide (et sort du script)                                    #
#	Aucun argument                                                        #
# =========================================================================== #
Help ()
{
printf "
$_pn v$_ver [options] arguments - Media Speech Installer

Arguments:
  $_arg

Options:
  -cfg <file>      configuration file
  -help            display this help

This script performs the MediaSpeech installation:
  all            front-end and back-end installation
  install-front  front-end installation
  install-back   back-end installation

Examples
  ./install_msf.sh -cfg install_msf_ALL.conf all
  ./install_msf.sh -cfg install_msf_ALL.conf install-front
  ./install_msf.sh -cfg install_msf_ALL.conf install-back

  ./install_msf.sh -cfg install_msf_X.conf all
  ./install_msf.sh -cfg install_msf_X.conf install-front
  ./install_msf.sh -cfg install_msf_X.conf install-back
\n\n"



  exit 0
}

Help_old ()
{
printf "
$_pn v$_ver [options] arguments - Media Speech Installer

Arguments:
  $all

Options:
  -cfg <file>      configuration file
  -exec <command>  execute/eval a shell (sh) command
  -help            display this help

This script performs the MediaSpeech installation:
  all           front-end and back-end installation
  install-front  front-end installation
  install-back   back-end installation
  install-slurm  slurm installation
  permissions    set the permissions
  conf-front     front-end configuration
  conf-back      back-end configuration
  conf-sudoers      sudo configuration
  conf-web-server    	apache configuration
  conf-mysql     	mysql/mariadb configuration
  conf-ftpd      	ftp server configuration
  conf-slurm		slurm configuration
  conf-services		services configuration
  conf-local-firewall	local firewall configuration 
  conf-cron      cron configuration\n\n"


  exit 0
}



# *************************************************************************** #
#                          MAIN SECTION                                       #
# *************************************************************************** #
Main ()
{
   local listarg _arg
   
   _arg=$@

   clear
   Log Infos "command line: $0 $@"


   #-----------#
   # CheckArg #
   #-----------#
   CheckArg $@


   #----------------#
   # Initialization #
   #----------------#

   cat $cfg_file | sed '/^$/d'
   Log Question "Press [Enter] to continue or [Ctrl C] to stop"
   read
   #. $cfg_file

   #-----------#
   # CheckSettings #
   #-----------#
   CheckSettings

   _pwd_temp_install=$PWD_TEMP_INSTALL
   _msf_root=$MSF_PATH

   _work_directory=/tmp
   mkdir -p $_work_directory
   cd $_work_directory


   _download_directory=$DOWNLOAD_DIRECTORY
   sudo mkdir -p $_download_directory


   #--------#
   # Set OS #
   #--------#
   SetOS

 
   #Check for the configuration file
   #[ $cfg ] || { Log "need the configuration file -cfg <file>"; exit 1; }
   #Set global variables
   #BuildParams

   Log Infos 'Start...'
   Log Infos "Distribution=$_dist"

   #TODO: uncomment
   #[[ $USER == 'root' ]] ||
   #{ Log "must have root privileges to install"; exit 1; }


   #----------------------------------------------------------------------------#
   #Execution des modules d'installation et de leur conf dans l'ordre : 
   #	1 - Installation des paquets commun au Front-End et au Back-End
   #	2 - Installation des paquets nécessaires au Front-End + conf
   #	3 - Conf server FTP
   #	4 - Installation des paquets nécessaires au Back-End + conf
   #	5 - Installation des paquets nécessaires à Slurm + conf
   #----------------------------------------------------------------------------#

   #---------------#
   # all           #
   #---------------#

   if [[ " $_arg " == *" all "* ]]; then
	InstallCommon

	InstallFront
	ConfSlurm
   	InstallSlurm

	InstallBack
   	ConfSudoers
   fi
   #---------------#
   # front-end     #
   #---------------#
   if [[ " $_arg " == *" install-front "* ]]; then
	InstallCommon

	InstallFront
	ConfSlurm
   	InstallSlurm

   	ConfSudoers
   fi

   #---------------#
   # back-end     #
   #---------------#
   if [[ " $_arg " == *" install-back "* ]]; then
	InstallCommon

	InstallBack
	ConfSlurm
   	InstallSlurm 

   	ConfSudoers
   fi


   
   if [[ " $_arg " == *" conf-front "* ]] || [[ " $_arg " == *" conf-back "* ]] ; then ConfCommon $cfg_file; fi
   if [[ " $_arg " == *" conf-front "* ]] ; then ConfFront $cfg_file; fi
   if [[ " $_arg " == *" conf-back "* ]] ; then ConfBack; fi
   if [[ " $_arg " == *" conf-slurm "* ]] ; then ConfSlurm; ConfDB; fi
   if [[ " $_arg " == *" install-slurm "* ]] ; then InstallSlurm; fi
   if [[ " $_arg " == *" conf-sudoers "* ]] ; then ConfSudoers; fi
   #----------------------------------------------------------------------------#
   if [[ " $_arg " == *" conf-web-server "* ]] ; then ConfWebServer; fi
   if [[ " $_arg " == *" conf-ftp-server "* ]] ; then ConfFtpServer; fi
   if [[ " $_arg " == *" conf-local-firewall "* ]] ; then ConfLocalFirewall; fi
   if [[ " $_arg " == *" conf-cron "* ]] ; then ConfCron; fi


   Log Infos 'End'
  
   ToDoPostInstall
}

Main "$@"

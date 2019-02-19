yum update
reboot
mv /home/mediaspeech/install_m* /root/
ll
cd
ll
chown root:root *
ll
mv /home/mediaspeech/MediaEditor.php /root/
chown root:root *
ll
vi install_msf_ALL.conf
./install_msf.V01.05b.sh
./install_msf.V01.05b.sh -cfg install_msf_ALL.conf all
mv /home/mediaspeech/msf_compliglobal.lic .
chown root:root msf_compliglobal.lic 
cp msf_compliglobal.lic /etc/msf;lic
cp msf_compliglobal.lic /etc/msf.lic
ll /etc/
ll /etc/msf
rm /etc/msf
ip a
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --reload
tail /var/log/httpd/error_log 
mv /etc/msf.lic /home/MSF/LICENCES/msf.lic
ll /users/1/
ll /users/1/
chgrp -R msf /users/1/
df -h
df -h
df -h
df -h
df -h
df -h
df -h
df -h
df -h
df -h
df -h
df -h
df -h
df -h
ll /home/
mv /home/mediaspeech/*.tgz /home/vtk/
cd /home/vtk/
ll
chown root:root *
ll
mv /home/mediaspeech/release.lst .
chown root:root *
ll
tar xvf dist-obf_vtk_bin_v6.0.tgz
tar xvf patch-obf_vtk_bin_v6.0.1.tgz
tar xvf patch-obf_vtk_bin_v6.0.2.tgz
tar xvf patch-obf_vtk_bin_v6.0.3.tgz
tar xvf patch-obf_vtk_bin_v6.0.4.tgz
ll
tar xvf dist-obf_vtk_spkrdia_cts_v3.2.tgz
ll
tar xvf dist-obf_vtk_trans_eng-cts_v5.3.tgz
rm -f dist-obf_vtk_trans_eng-cts_v5.3.tgz
ll
tar xvf patch-obf_vtk_trans_eng-cts_v5.3.1.tgz
rm -f patch-obf_vtk_trans_eng-cts_v5.3.1.tgz
ll
tar xvf dist-obf_vtk_trans_fre-cts_v5.6.tgz
rm dist-obf_vtk_trans_fre-cts_v5.6.tgz
ll
mkdir models
mkdir models/trader
mv dist-obf_vtk_trans_* models/trader/
cd models/trader/
ll
tar xvf dist-obf_vtk_trans_eng-cts_trader_v5.3.2.tgz
tar xvf dist-obf_vtk_trans_fre-cts_trader_v5.5.1.tgz
ll
rm -f dist-obf_vtk_trans_eng-cts_trader_v5.3.2.tgz dist-obf_vtk_trans_fre-cts_trader_v5.5.1.tgz
ll
cd ../../
ll /home/vtk/trans/bin/vtk_trans
ll /home/vtk/trans/
ll /home/vtk/
vi /home/MSF/www/Toolbox/settings
vi /home/MSF/www/Toolbox/settings.php 
systemctl httpd restart
systemctl restart httpd
mv /home/mediaspeech/vtk.lic /home/vtk/conf/
cp /home/vtk/conf/vtk.lic /root/
cd
ll
mv msf_compliglobal.lic msf.lic
ll
cp MediaEditor.php /home/MSF/www/html/MediaEditor.php 
df -h
cd /home/vtk/
rm -Rf dist-obf_vtk_bin_v6.0.tgz patch-obf_vtk_bin_v6.0.1.tgz patch-obf_vtk_bin_v6.0.2.tgz patch-obf_vtk_bin_v6.0.3.tgz patch-obf_vtk_bin_v6.0.4.tgz dist-obf_vtk_spkrdia_cts_v3.2.tgz
ll
tar xvf dist-obf_vtk_lid_cts_v3.1.tgz
rm dist-obf_vtk_lid_cts_v3.1.tgz
tar xvf patch-obf_vtk_lid_cts_v3.1.1.tgz
tar xvf patch-obf_vtk_lid_cts_v3.1.2.tgz
rm -f patch-obf_vtk_lid_cts_v3.1.1.tgz patch-obf_vtk_lid_cts_v3.1.2.tgz
ll
vi /home/MSF/www/Toolbox/settings.php 
df -h
yum install htop psmiscs
yum install htop psmisc
htop
poweroff 
cd
vi install_model.sh 
ll /Models/
mv /home/vtk/models/trader /Models/
ll
./install_model.sh 1 trader
pstree
squeue 
systemctl stop slurmdbd
systemctl stop slurctld
systemctl stop slurd
systemctl enable slurmdbd
systemctl start slurmdbd
systemctl enable slurmctld
systemctl start slurmctld
systemctl enable slurmd
systemctl start slurmd
pstree
squeue 
cat /home/MSF/www/webservice/create_wsdl.sh 
/home/MSF/www/webservice/create_wsdl.sh http://10.229.100.199
which php
ln -s /bin/php /usr/local/bin/php
/home/MSF/www/webservice/create_wsdl.sh http://10.229.100.199
sed -i 's/split/explode/g' /home/MSF/www/html/wsdl-writer/classes/DocBlockParser.php
/home/MSF/www/webservice/create_wsdl.sh http://10.229.100.199
tail -f /var/log/httpd/error_log 
ls
cd
ls
cd /media/
ls
df )h
df -h
³123456767898900°°°AZRTYEOOPP"QSFGHJKLMMM%%
ls
cd
ls
cd /opt/
l
ls
exit
netstat -tlpn
history
history | less
cd /home/MSF/www/
ls
cd html/
ls
cat login.php  | less
vi login.php 
ls
df -h
mysql -u root -p
ls

ls
systemctl status mariadb
grep -Ril "user" .
grep -Ril "user" . | less
ls
clear
ls
exit
clear
netstat -ntpl
ls
cd rest/
ls
cd ..
cd smarty/
ls
cd ..
cd rest/
ls
exit
l
sls
ls
exit
ls
cd ..
cd users/
ls
cd Models/template/
ls
cd ..
ls
cd ..
cd ..
cd Download/
ls
cd slurm/
ls
cd ..
tar -xvf MSF_05.13.tgz 
ls
cd bin/
ls
cd ..
cd www/
ls
cd ..
cd mysql/
ls
cd ..
cd ..
ls
cd www/
ls
cd ..
cd Download/
ls
pwd
cp -p loaders.linux-x86_64.zip /home/MSF/Download/mysql/
cd mysql/
ls
unzip loaders.linux-x86_64.zip 
ls
cd /opt/
ls
cd .
cd
cd /opt/rem
cd /opt/
l
ls
cd
cd /usr/lib64/php/
cd modules/
ls
cd 
cd /home/MSF/
ls
cd www/
ls
cd scripts/
ls
cd ..
ls
exit
cd
cd /etc/opt/
ls
ls
cd /home/MSF/etc/
ls
cd /home/MSF/
ls
cd etc/
l
ls
exit
ls
cd  ..
ls
cd html/
l
ls
cd ..
cd ..
;s
ls
cd www/
ls
cd ..
cd ..
s;
ls
cd media/
ls
cd ..
cd opt/
ls
cd
cd /etc/
ls
cat php.ini 
vi php.ini 
clear
exit
cd test/
ls
ls
ls -la
cd ..
cd slurm_acct_db/
ls
cd ..
cd msf/
ls
cd /etc/
ls
cp -p php.ini /home/mediaspeech/
cd /home/mediaspeech/
ls
git init .
git commit -m "first commit"
git add .
git remote add origin https://github.com/smith701/docker.git
git push -u origin master
git push -u origin master
exit
ls
cd mod_php/
ls
cd opcache/
ls
cd ..
cd session/
ls
cd ..
cd wsdlcache/
ls
cd ..
cd ..
ls
exit
cd
vi install_msf_ALL.conf 
clear
ls
vi MediaEditor.php 
clear
ls
vi install_msf_ALL.conf 
clear
ls
exit
ls
cd /home/MSF/
ls
cd mysql/
ls
cd
exit
rpm -qc php-common
rpm -qc php
php -v
exit

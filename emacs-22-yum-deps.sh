# From 
# http://www.centos.org/modules/newbb/viewtopic.php?topic_id=26353&forum=38

sudo -i

yum -y groupinstall "Development Tools"
yum -y install gtk+-devel gtk2-devel
yum -y install libXpm-devel
yum -y install libpng-devel
yum -y install giflib-devel
yum -y install libtiff-devel libjpeg-devel
yum -y install ncurses-devel
yum -y install gpm-devel dbus-devel dbus-glib-devel dbus-python
yum -y install GConf2-devel pkgconfig
yum -y install libXft-devel


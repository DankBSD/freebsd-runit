echo " => Applying /etc/rc.toml"
mkdir -p /var/service
mount -t tmpfs tmpfs /var/service
/usr/local/sbin/configurate /etc/rc.toml

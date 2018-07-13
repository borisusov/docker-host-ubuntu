#!/bin/bash

set -x

# Check root pertmissions
[ $(id -u) != 0 ] && echo "Im not root" && exit 1

## TODO:needs tobe checked about proxy errors
## Next Line is needed only if apt-cache server is configured
#echo 'Acquire::http::Proxy "http://172.17.0.1:3142";' > /etc/apt/apt.conf.d/00aptproxy

#apt-get update
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
apt-get update
apt-cache policy docker-engine

apt-get install -y docker-engine
systemctl status docker

docker run  hello-world 

### OPEN NETWORK SOCKET FOR DOCKER daemon. Use carefully!
# Change to yes next variable to enable
dockerd_net_socket_enable=yes
if [ $dockerd_net_socket_enable == yes ]; then
  sed -i 's~^\(ExecStart=/usr/bin/dockerd .*\)$~\1 --dns 8.8.8.8 --dns 8.8.4.4 -H tcp://0.0.0.0 -H unix:///var/run/docker.sock~' \
          /lib/systemd/system/docker.service
  systemctl daemon-reload
  systemctl restart docker
fi

USR_LST=$(cat /etc/passwd | grep /bin/bash | grep -E '^[a-z_-]+:x:[1-9][0-9]{3}+'| cut -d: -f1)

for usr in ${USR_LST} 
  do usermod -a -G docker  $usr;
done


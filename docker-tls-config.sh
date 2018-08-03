#!/bin/bash
set -x


#TLS version

HOST=$(hostname)
PASS='foobar'



##generate pair of keys for achieve acsess to CA
openssl genrsa -aes256 -out ca-key.pem -passout pass:$PASS 4096

#ask for cert
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -passout pass:$PASS -out ca.pem

#gen key for signature serv cert
openssl genrsa -out server-key.pem 4096

#ask for cert
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
##### start your work from here !!


#file configuration for bind site(with signed cert) with host
echo subjectAltName = DNS:$HOST,IP:10.10.10.20,IP:127.0.0.1 >> extfile.cnf

#set autentification parameter
echo extendedKeyUsage = serverAuth >> extfile.cnf


#generym servernyj sertifikat 
#  ( + pydpysyem CA kluchem)
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# key for cliant c
openssl genrsa -out key.pem 4096


##cert client 
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile.cnf


#delete asc for client and serv
rm -v client.csr server.csr

#secure - nobody can write and modify cert and key
chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem


#dir for keys and certs 
mkdir /etc/docker/certs


#check and 
sed -i 's~^\(ExecStart=/usr/bin/dockerd .*\)$~\1 --dns 8.8.8.8 --dns 8.8.4.4 -H tcp://0.0.0.0 -H unix:///var/run/docker.sock --tlsverify --tlscacert=/etc/docker/certs/ca.pem --tlscert=/etc/docker/certs/server-cert.pem --tlskey=/etc/docker/certs/server-key.pem ~' /lib/systemd/system/docker.service


#after update we must reload docker  
systemctl daemon-reload
systemctl restart docker




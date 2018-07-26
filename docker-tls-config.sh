#!/bin/bash
set -x


#TLS version

HOST=$(hostname)
PASS='foobar'

openssl genrsa -aes256 -out ca-key.pem -passout pass:$PASS 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -passout pass:$PASS -out ca.pem
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
##### start your work from here !!
echo subjectAltName = DNS:$HOST,IP:10.10.10.20,IP:127.0.0.1 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile.cnf
rm -v client.csr server.csr
chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem

mkdir /etc/docker/certs

sed -i 's~^\(ExecStart=/usr/bin/dockerd .*\)$~\1 --dns 8.8.8.8 --dns 8.8.4.4 -H tcp://0.0.0.0 -H unix:///var/run/docker.sock --tlsverify --tlscacert=/etc/docker/certs/ca.pem --tlscert=/etc/docker/certs/server-cert.pem --tlskey=/etc/docker/certs/server-key.pem ~' /lib/systemd/system/docker.service
  
systemctl daemon-reload
systemctl restart docker




#!/bin/bash
mkdir -p /home/centos/certs
cd /home/centos/certs
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1024 -out ca.crt -subj "/CN=dockerroot"
openssl genrsa -out client-key.key 2048 
openssl req -new -key client-key.key -subj /CN=`hostname -i` -out client.csr
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client-cert.crt

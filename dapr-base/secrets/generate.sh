#!/bin/sh
set -eou pipefail

apk add --no-cache openssl ca-certificates

# skip the following line to reuse an existing root key, required for rotating expiring certificates
openssl ecparam -genkey -name prime256v1 | openssl ec -out root.key
openssl req -new -nodes -sha256 -key root.key -out root.csr -config root.conf -extensions v3_req
openssl x509 -req -sha256 -days 3650 -in root.csr -signkey root.key -outform PEM -out root.pem -extfile root.conf -extensions v3_req

# skip the following line to reuse an existing issuer key, required for rotating expiring certificates
openssl ecparam -genkey -name prime256v1 | openssl ec -out issuer.key
openssl req -new -sha256 -key issuer.key -out issuer.csr -config issuer.conf -extensions v3_req
openssl x509 -req -in issuer.csr -CA root.pem -CAkey root.key -CAcreateserial -outform PEM -out issuer.pem -days 3650 -sha256 -extfile issuer.conf -extensions v3_req

cat <<EOF > /tmp/output/dapr-trust-bundle.yml
apiVersion: v1
kind: Secret
metadata:
  name: dapr-trust-bundle
  labels:
    app: dapr-sentry
data:
  issuer.crt: $(base64 -i issuer.pem -w 0)
  issuer.key: $(base64 -i issuer.key -w 0)
  ca.crt: $(base64 -i root.pem -w 0)
EOF

rm /tmp/certs/*.key
rm /tmp/certs/*.pem
rm /tmp/certs/*.csr
rm /tmp/certs/*.srl
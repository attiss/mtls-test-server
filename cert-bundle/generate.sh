#!/bin/bash -ex

# original source: https://stackoverflow.com/a/40530391

for CERT in `echo root-ca intermediate`; do
	mkdir -p ${CERT}/certs ${CERT}/crl ${CERT}/newcerts ${CERT}/private

	echo 1000 > ${CERT}/serial
	touch ${CERT}/index.txt ${CERT}/index.txt.attr

	cat > ${CERT}/openssl.conf <<-EOF
	[ ca ]
	default_ca = CA_default
	[ CA_default ]
	dir            = '${CERT}'                # Where everything is kept
	certs          = \$dir/certs               # Where the issued certs are kept
	crl_dir        = \$dir/crl                 # Where the issued crl are kept
	database       = \$dir/index.txt           # Database index file
	new_certs_dir  = \$dir/newcerts            # Default place for new certs
	certificate    = \$dir/cacert.pem          # The CA certificate
	serial         = \$dir/serial              # The current serial number
	crl            = \$dir/crl.pem             # The current CRL
	private_key    = \$dir/private/ca.key.pem  # The private key
	RANDFILE       = \$dir/.rnd                # Random number file
	nameopt        = default_ca
	certopt        = default_ca
	policy         = policy_match
	default_days   = 365
	default_md     = sha256

	[ policy_match ]
	countryName            = optional
	stateOrProvinceName    = optional
	organizationName       = optional
	organizationalUnitName = optional
	commonName             = supplied
	emailAddress           = optional

	[req]
	req_extensions = v3_req
	distinguished_name = req_distinguished_name

	[req_distinguished_name]

	[v3_req]
	basicConstraints = CA:TRUE
	EOF
done

openssl genrsa -out root-ca/private/ca.key 4096
openssl req -config root-ca/openssl.conf -new -x509 -days 3650 -key root-ca/private/ca.key -sha256 -extensions v3_req -out root-ca/certs/ca.crt -subj '/CN=example'

openssl genrsa -out intermediate/private/intermediate.key 4096
openssl req -config intermediate/openssl.conf -sha256 -new -key intermediate/private/intermediate.key -out intermediate/certs/intermediate.csr -subj '/CN=intermediate.example'
openssl ca -batch -config root-ca/openssl.conf -keyfile root-ca/private/ca.key -cert root-ca/certs/ca.crt -extensions v3_req -notext -md sha256 -in intermediate/certs/intermediate.csr -out intermediate/certs/intermediate.crt

for HOST in `echo server client`; do
	mkdir ${HOST}
	openssl req -new -keyout ${HOST}/${HOST}.key -out ${HOST}/${HOST}.request -days 365 -nodes -subj "/CN=${HOST}.intermediate.example" -newkey rsa:4096
	openssl ca -notext -batch -config root-ca/openssl.conf -keyfile intermediate/private/intermediate.key -cert intermediate/certs/intermediate.crt -out ${HOST}/${HOST}.crt -infiles ${HOST}/${HOST}.request
	cat intermediate/certs/intermediate.crt root-ca/certs/ca.crt > ${HOST}/ca-bundle.crt
	cat ${HOST}/${HOST}.crt intermediate/certs/intermediate.crt root-ca/certs/ca.crt > ${HOST}/${HOST}-bundle.crt
done

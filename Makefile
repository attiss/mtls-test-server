CONTAINER_TAG?=attiss/mtls-test-server:latest

.POSIX:
.PHONY: build
build:
	go build -a -o mtls-test-server .

.ONESHELL:
.POSIX:
.PHONY: generate-certs
generate-certs:
	if [ ! -d test-certs ]; then
		mkdir test-certs && cd test-certs
		openssl genrsa 4096 > ca-key.pem
		openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem -subj "/C=EX/ST=Example/L=Example/O=Example/OU=CA/CN=ca.example./emailAddress=ca@example."
		openssl req -newkey rsa:4096 -nodes -days 365000 -keyout server-key.pem -out server-req.pem -subj "/C=EX/ST=Example/L=Example/O=Example/OU=server/CN=server.example./emailAddress=server@example."
		openssl x509 -req -days 365000 -set_serial 01 -in server-req.pem -out server-cert.pem -CA ca-cert.pem -CAkey ca-key.pem
		openssl req -newkey rsa:2048 -nodes -days 365000 -keyout client-key.pem -out client-req.pem -subj "/C=EX/ST=Example/L=Example/O=Example/OU=client/CN=client.example./emailAddress=client@example."
		openssl x509 -req -days 365000 -set_serial 01 -in client-req.pem -out client-cert.pem -CA ca-cert.pem -CAkey ca-key.pem
	fi

.POSIX:
.PHONY: run
run: generate-certs
	go run .

.POSIX:
.PHONY: container
container:
	docker build -t ${CONTAINER_TAG} .

.POSIX:
.PHONY: clean
clean:
	rm -rf test-certs
	rm -rf mtls-test-server

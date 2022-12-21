# mtls-test-server

This is a simple HTTPS server to be used for testing mTLS.

## Run

Use the `run` make target to start the HTTPS server.
(Note: this will invoke the `generate-certs` make target that will generate new CA & server & client certificates if you did not generate them already.)

## Build

Use the `build` make target to build the `mtls-test-server` binary.
(Note: you will need to have go already installed.)

## Container

Use the `container` make target to build the container image.
(Note: you will need to have Docker CLI already installed.)

Set the `CONTAINER_TAG` environment variable to override the default image tag.

### attiss/mtls-test-server

If you are planning to use the `attiss/mtls-test-server` image from Docker Hub, you will need the mount the following files:
- `ca-cert.pem` to `/opt/test-certs/ca-cert.pem`
- `server-key.pem` to `/opt/test-certs/server-key.pem`
- `server-cert.pem` to `/opt/test-certs/server-cert.pem`

Then you can use your generated client certificates to access the server.

### Kubernetes deployment

[`deployment.yaml`](./deployment.yaml) contains a simple example on how you could deploy the _mtls-test-server_ on your Kubernetes cluster.

If you are planning to use the example deployment, you will need to:

1. create a namespace:

```
kubectl create namespace mtls-test-server
```

2. create a Secret named `certs` in your namespace and add your server certs:

```
kubectl create secret generic -n mtls-test-server certs --from-file ca-cert.pem=test-certs/ca-cert.pem --from-file server-key.pem=test-certs/server-key.pem --from-file server-cert.pem=test-certs/server-cert.pem
```

3. create the example deployment:

```
kubectl create --save-config -n mtls-test-server -f https://raw.githubusercontent.com/attiss/mtls-test-server/main/deployment.yaml
```

## Test

Start the HTTPS server (for example by using the `run` make target).

Use the client credentials to access the HTTPS server:

```
$ curl -v -k --cert test-certs/client-cert.pem --key test-certs/client-key.pem --cacert test-certs/ca-cert.pem https://localhost:8443/
*   Trying 127.0.0.1:8443...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: test-certs/ca-cert.pem
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, CERT verify (15):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: C=EX; ST=Example; L=Example; O=Example; OU=server; CN=server.example.; emailAddress=server@example.
*  start date: Dec 21 16:05:49 2022 GMT
*  expire date: Apr 23 16:05:49 3022 GMT
*  issuer: C=EX; ST=Example; L=Example; O=Example; OU=CA; CN=ca.example.; emailAddress=ca@example.
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x564f93c162f0)
> GET / HTTP/2
> Host: localhost:8443
> user-agent: curl/7.68.0
> accept: */*
>
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* Connection state changed (MAX_CONCURRENT_STREAMS == 250)!
< HTTP/2 200
< content-type: text/plain; charset=utf-8
< content-length: 14
< date: Wed, 21 Dec 2022 16:05:54 GMT
<
Hello, world!
* Connection #0 to host localhost left intact
```

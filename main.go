package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.uber.org/zap"
)

const (
	caCertFile    = "test-certs/ca-cert.pem"
	certFile      = "test-certs/server-cert.pem"
	keyFile       = "test-certs/server-key.pem"
	listenAddress = ":8443"
)

func main() {
	logger, _ := zap.NewProduction()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "Hello, world!\n")
		logger.Info("successfully handled request", zap.String("remoteAddr", r.RemoteAddr))
	})

	caCert, err := ioutil.ReadFile(caCertFile)
	if err != nil {
		logger.Error("failed to read ca cert", zap.Error(err))
		panic(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	server := &http.Server{
		Addr: listenAddress,
		TLSConfig: &tls.Config{
			ClientCAs:  caCertPool,
			ClientAuth: tls.RequireAndVerifyClientCert,
		},
	}

	go func() {
		if err := server.ListenAndServeTLS(certFile, keyFile); err != nil && err != http.ErrServerClosed {
			logger.Error("server failure", zap.Error(err))
			panic(err)
		}
		logger.Info("server shutdown")
	}()

	<-sigChan
	ctx, ctxCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer ctxCancel()
	if err := server.Shutdown(ctx); err != nil {
		logger.Error("failed to shut down server")
		panic(err)
	}
}

# syntax=docker/dockerfile:1
FROM golang:latest
WORKDIR /opt
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -o mtls-test-server .

FROM alpine:latest
WORKDIR /opt
RUN apk --no-cache add ca-certificates
COPY --from=0 /opt/mtls-test-server ./
EXPOSE 8443
CMD ["./mtls-test-server"]

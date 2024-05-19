FROM --platform=arm64 golang:1.20.13-alpine AS builder

WORKDIR /app

COPY server.go /app/

RUN go build server.go

FROM scratch AS runner

COPY --from=builder /app/server /

ENTRYPOINT [ "./server" ]
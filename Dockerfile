FROM node:22.11.0 AS frontend_builder
WORKDIR /app
ADD frontend .
RUN yarn install && \
    yarn exec vite build

FROM golang:1.22.9 AS golang_builder
WORKDIR /app
ADD cmd cmd
ADD internal internal
COPY --from=frontend_builder /app/dist internal/embed/static
ADD pkg pkg
ADD go.mod go.mod
ADD go.sum go.sum
RUN CGO_ENABLED=0 go build -o gamekube cmd/gamekube/main.go

FROM gcr.io/distroless/static-debian12:nonroot AS final
WORKDIR /app
COPY --from=golang_builder /app/gamekube access
ENTRYPOINT ["access"]

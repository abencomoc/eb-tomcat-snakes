# Docker Instructions — eb-tomcat-snakes

## Overview

Java EE Tomcat web application that manages a movie database. Built with a multi-stage Docker build: Maven compiles the source and packages `ROOT.war` in the builder stage; Apache Tomcat 9 serves it in the runtime stage. Runs as user `10000` (appuser).

## Prerequisites

- Docker installed and running
- (Optional) A PostgreSQL database for full functionality

## Build

From the root of the extracted source directory:

```bash
docker build -t eb-tomcat-snakes .
```

## Run

### Without a database (application starts, DB-dependent pages show "Connection Failed")

```bash
docker run -p 8080:8080 eb-tomcat-snakes
```

### With a PostgreSQL database

```bash
docker run -p 8080:8080 \
  -e RDS_HOSTNAME=<db-host> \
  -e RDS_PORT=5432 \
  -e RDS_DB_NAME=<db-name> \
  -e RDS_USERNAME=<db-user> \
  -e RDS_PASSWORD=<db-password> \
  eb-tomcat-snakes
```

Open [http://localhost:8080](http://localhost:8080) in a browser.

## Environment Variables

| Variable       | Description                        | Required |
|----------------|------------------------------------|----------|
| `RDS_HOSTNAME` | PostgreSQL database hostname       | Yes (for DB) |
| `RDS_PORT`     | PostgreSQL database port           | No (default: 5432) |
| `RDS_DB_NAME`  | PostgreSQL database name           | Yes (for DB) |
| `RDS_USERNAME` | PostgreSQL database username       | Yes (for DB) |
| `RDS_PASSWORD` | PostgreSQL database password       | Yes (for DB) |

## Secret Handling

For production deployments, manage secrets using:
- **ECS**: [Secrets Manager integration](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html)
- **EKS**: [Secrets Manager or KMS encryption](https://docs.aws.amazon.com/eks/latest/userguide/security-k8s.html)

Do **not** pass secrets as plain environment variables in production.

## Health Check

- **Endpoint:** `GET /search`
- **Expected response:** HTTP `200–299`

## Ports

| Port | Protocol | Description              |
|------|----------|--------------------------|
| 8080 | HTTP     | Tomcat HTTP listener     |

## User

The container runs as user `10000` (appuser, GID 10000). All Tomcat files are owned by this user.

## Notes

- The application gracefully handles a missing database — it logs a warning and returns a "Connection Failed" placeholder entry on the Browse/Search pages.
- The database seed file (`database-seed.json`) is bundled in the WAR and used to initialize the `Movies` table on first connection.
- Log4j2 is configured to write to `SYSTEM_OUT` (stdout) for container log aggregation compatibility.

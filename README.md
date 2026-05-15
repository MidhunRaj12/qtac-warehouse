# QTAC Admissions Data Warehouse

Postgres warehouse pipeline built against QTAC source data extracts. Covers raw ingestion, SCD2 change tracking on the applicant dimension, and a mart layer summarising accepted offers per applicant.

## Stack

- Postgres 16 (Docker)
- Plain SQL transforms orchestrated by bash scripts

## Setup

```bash
docker compose up -d
```

Postgres will be available at `localhost:5432`. Credentials: 
user `qtac`,
password `qtac`, 
database `qtac`.

## Running the pipeline

...

## Source data

Raw CSV extracts live under `data/`. They are committed as-is — coercion and cleanup happen in the warehouse transform layer.
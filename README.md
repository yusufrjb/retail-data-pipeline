# Retail Sales Data Pipeline

An end-to-end data pipeline project for transforming retail transactional data into an analytics-ready warehouse using PostgreSQL, dbt, Apache Airflow, and Docker.

## Overview

This project demonstrates a simple but production-oriented data engineering workflow:

**OLTP PostgreSQL → dbt Staging → dbt Transformation → Data Warehouse → Incremental Loading → Airflow Orchestration**

The project uses a retail sales scenario containing customers, products, orders, and order items. Transactional data is transformed into a warehouse-ready fact table for analytical use.

## Architecture

```text
                  ┌─────────────────┐
                  │   PostgreSQL    │
                  │      OLTP       │
                  │                 │
                  │ customers       │
                  │ products        │
                  │ orders          │
                  │ order_items     │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │   dbt Staging   │
                  │                 │
                  │ stg_orders      │
                  │ stg_order_items │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │   dbt Marts     │
                  │                 │
                  │   fct_sales     │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Data Warehouse  │
                  │    schema:      │
                  │    warehouse    │
                  └────────┬────────┘
                           ▲
                           │
                  ┌────────┴────────┐
                  │    Airflow      │
                  │  Orchestration  │
                  │                 │
                  │ dbt run         │
                  │ dbt test        │
                  └─────────────────┘
```

## Tech Stack

| Technology     | Purpose                                    |
| -------------- | ------------------------------------------ |
| PostgreSQL     | OLTP database and data warehouse           |
| dbt            | Data transformation, modeling, testing     |
| Apache Airflow | Pipeline orchestration                     |
| Docker         | Reproducible development environment       |
| SQL            | Data transformation and analytical queries |
| Python         | Pipeline/orchestration configuration       |

## Data Model

### OLTP

The transactional database contains:

* `customers`
* `products`
* `orders`
* `order_items`

The schema uses primary keys and foreign keys to maintain relationships between entities.

### Warehouse

The main analytical model is:

`warehouse.fct_sales`

It combines completed orders with their order items and calculates:

```text
total_sales = quantity × unit_price
```

Example columns:

| Column          | Description                       |
| --------------- | --------------------------------- |
| `order_item_id` | Unique order item identifier      |
| `order_id`      | Order identifier                  |
| `customer_id`   | Customer identifier               |
| `product_id`    | Product identifier                |
| `sales_date`    | Date of sale                      |
| `quantity`      | Quantity purchased                |
| `unit_price`    | Product price at transaction time |
| `total_sales`   | Calculated sales value            |

## dbt Transformation

The dbt project separates transformations into staging and mart layers.

### Staging

`stg_orders`

Filters the source orders to completed transactions.

`stg_order_items`

Calculates the sales amount for each order item.

```sql
quantity * unit_price AS total_sales
```

### Mart

`fct_sales`

Joins the staging models into an analytics-ready fact table.

The model is materialized as an **incremental model** using `order_item_id` as the unique key.

This allows newly arrived records to be processed without rebuilding the entire fact table.

## Incremental Loading

The pipeline supports incremental processing through dbt's `is_incremental()` logic.

On the initial run, the fact table is created from the available source data.

On subsequent runs, new order items are processed based on the current maximum `order_item_id`.

Example workflow:

```text
Initial load
    ↓
8 records in warehouse.fct_sales
    ↓
New transaction arrives
    ↓
dbt run
    ↓
Only the new record is processed
    ↓
9 records in warehouse.fct_sales
```

For this demonstration, `order_item_id` is used as the incremental watermark. In a production environment, a timestamp such as `updated_at` may be more appropriate when late-arriving or updated records need to be handled.

## Airflow Orchestration

Apache Airflow is used to orchestrate the dbt workflow.

The DAG executes:

```text
dbt run
   ↓
dbt test
```

The dependency ensures that data transformation completes before data quality tests are executed.

## Data Quality

dbt tests are used to validate the transformed data.

The project demonstrates how transformation and data validation can be integrated into the same pipeline rather than relying entirely on manual SQL checks.

## Running the Project

### Prerequisites

* Docker
* Docker Compose
* Git

### Start the services

```bash
docker compose up -d
```

Check running containers:

```bash
docker compose ps
```

### Run dbt

```bash
docker compose exec dbt dbt debug
```

Run the transformations:

```bash
docker compose exec dbt dbt run
```

Run data quality tests:

```bash
docker compose exec dbt dbt test
```

### Run the Airflow pipeline

The Airflow DAG is:

```text
retail_dbt_pipeline
```

It executes:

```text
dbt run → dbt test
```

## Example Result

After an incremental transaction is added to the OLTP database, running the dbt pipeline updates the warehouse:

```text
warehouse.fct_sales

order_item_id | order_id | customer_id | product_id | total_sales
--------------|----------|-------------|------------|------------
12            | 9        | 1           | 1          | 25000.00
11            | 8        | 3           | 2          | 44000.00
```

This demonstrates the incremental loading workflow from transactional data into the warehouse.

## Key Concepts Demonstrated

* Relational database design
* Primary and foreign keys
* OLTP vs OLAP
* Data warehouse modeling
* Fact tables
* SQL transformations
* ETL / ELT concepts
* dbt staging and mart models
* Incremental data loading
* Data quality testing
* Apache Airflow orchestration
* Dockerized data engineering environment

## Future Improvements

Potential extensions include:

* Source data ingestion from REST APIs
* Incremental loading using `updated_at`
* Dimension tables for customers and products
* Slowly Changing Dimensions (SCD)
* BigQuery deployment
* dbt documentation and lineage
* CI/CD with GitHub Actions
* Monitoring and pipeline alerting

## Author

**Muhammad Yusuf Rajabiyah**

Applied Data Science / Data Engineering Projects

GitHub: [github.com/yusufrjb](https://github.com/yusufrjb)

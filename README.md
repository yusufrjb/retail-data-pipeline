# Retail Sales Data Pipeline

An end-to-end data engineering project that transforms retail transactional data into an analytics-ready fact table using PostgreSQL, dbt, Apache Airflow, and Docker.

## Project Overview

This project demonstrates a practical data engineering workflow:

**PostgreSQL OLTP → dbt Staging → dbt Mart → Warehouse → Incremental Processing → Airflow Orchestration**

The project uses a retail sales scenario containing customers, products, orders, and order items. Transactional data is transformed into a warehouse-ready fact table for analytical use.

**Project status:** Completed portfolio project

## Architecture

```text
                  ┌─────────────────────┐
                  │      PostgreSQL     │
                  │        OLTP         │
                  │                     │
                  │ customers           │
                  │ products            │
                  │ orders              │
                  │ order_items         │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │     dbt Staging     │
                  │                     │
                  │ stg_orders          │
                  │ stg_order_items     │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │      dbt Mart       │
                  │                     │
                  │     fct_sales       │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ PostgreSQL Warehouse│
                  │                     │
                  │ schema: warehouse   │
                  │ table: fct_sales    │
                  └─────────────────────┘

                  ┌─────────────────────┐
                  │      Airflow        │
                  │   Orchestration     │
                  │                     │
                  │     dbt run         │
                  │        ↓            │
                  │     dbt test        │
                  └─────────────────────┘
```

> The OLTP database and warehouse use the same PostgreSQL instance in this demonstration project. The `warehouse` schema separates the analytical model from the transactional tables.

## Tech Stack

| Technology     | Purpose                                    |
| -------------- | ------------------------------------------ |
| PostgreSQL     | Transactional database and warehouse       |
| dbt            | Data transformation, modeling, and testing |
| Apache Airflow | Pipeline orchestration                     |
| Docker         | Reproducible development environment       |
| SQL            | Data transformation and analytical queries |
| Python         | Airflow DAG configuration                  |

## Data Model

### OLTP

The transactional database contains:

* `customers`
* `products`
* `orders`
* `order_items`

Primary keys and foreign keys are used to maintain relationships between entities.

### Warehouse

The main analytical model is:

```text
warehouse.fct_sales
```

The fact table combines completed orders with their order items and calculates:

```text
total_sales = quantity × unit_price
```

Example columns:

| Column          | Description                        |
| --------------- | ---------------------------------- |
| `order_item_id` | Unique order item identifier       |
| `order_id`      | Order identifier                   |
| `customer_id`   | Customer identifier                |
| `product_id`    | Product identifier                 |
| `sales_date`    | Date of sale                       |
| `quantity`      | Quantity purchased                 |
| `unit_price`    | Price recorded at transaction time |
| `total_sales`   | Calculated sales value             |

## dbt Transformation

The dbt project separates transformations into staging and mart layers.

### Staging

**`stg_orders`**

Filters source orders to completed transactions.

**`stg_order_items`**

Calculates sales value for each order item:

```sql
quantity * unit_price AS total_sales
```

### Mart

**`fct_sales`**

Joins the staging models into an analytics-ready fact table.

The model uses dbt's **incremental materialization** with `order_item_id` as the `unique_key`.

For incremental runs, records with an `order_item_id` greater than the current maximum in the target table are processed.

## Incremental Loading

The pipeline uses dbt's `is_incremental()` logic to avoid rebuilding the entire fact table on every run.

### Workflow

```text
Initial load
    ↓
Existing OLTP transactions
    ↓
warehouse.fct_sales
    ↓
New transaction arrives
    ↓
dbt run
    ↓
New order item is processed
    ↓
Warehouse is updated
```

In the demonstration, a new transaction with `order_item_id = 12` was added to the warehouse through an incremental dbt run.

### Incremental Strategy

The current implementation uses:

```text
order_item_id
```

as the incremental watermark.

This approach is suitable for the controlled demonstration dataset. In a production ingestion system, an `updated_at` timestamp or another reliable change-tracking mechanism would generally be preferable for handling late-arriving or updated records.

## Airflow Orchestration

Apache Airflow orchestrates the dbt workflow through the DAG:

```text
retail_dbt_pipeline
```

The DAG executes:

```text
dbt run
   ↓
dbt test
```

The dependency ensures that transformation completes before data quality tests are executed.

## Data Quality

dbt tests are integrated into the pipeline so that data validation runs after transformation.

This demonstrates a basic **transform → validate** workflow where data quality checks are part of the orchestration process rather than being performed only through manual SQL queries.

## Running the Project

### Prerequisites

* Docker
* Docker Compose
* Git

### Start the Services

```bash
docker compose up -d
```

Check the running containers:

```bash
docker compose ps
```

### Run dbt

Check the dbt connection:

```bash
docker compose exec dbt dbt debug
```

Run transformations:

```bash
docker compose exec dbt dbt run
```

Run data quality tests:

```bash
docker compose exec dbt dbt test
```

### Run the Airflow Pipeline

The Airflow DAG is:

```text
retail_dbt_pipeline
```

It executes:

```text
dbt run → dbt test
```

The Airflow web interface can be used to monitor DAG runs and task status.

## Example Result

After a new transaction is added to the OLTP database, the incremental dbt model updates the warehouse.

Example:

```text
warehouse.fct_sales

order_item_id | order_id | customer_id | product_id | total_sales
--------------|----------|-------------|------------|------------
12            | 9        | 1           | 1          | 25000.00
11            | 8        | 3           | 2          | 44000.00
```

This demonstrates the flow of a newly arrived transactional record into the analytical warehouse.

## Key Concepts Demonstrated

* Relational database design
* Primary and foreign keys
* OLTP and OLAP concepts
* Data warehouse modeling
* Fact tables
* SQL transformations
* ETL / ELT concepts
* dbt staging and mart models
* Incremental data processing
* Data quality testing
* Apache Airflow orchestration
* Dockerized data engineering environment

## Future Improvements

Potential extensions include:

* REST API source ingestion
* Incremental loading using `updated_at`
* Customer and product dimension tables
* Slowly Changing Dimensions (SCD)
* BigQuery deployment
* dbt documentation and lineage
* CI/CD with GitHub Actions
* Pipeline monitoring and alerting

## Author

**Muhammad Yusuf Rajabiyah**

Data Engineering & Applied Data Science Projects

GitHub: `yusufrjb`

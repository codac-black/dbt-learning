## DBT SETUP

- run ```bash dbtf init ``` to initialize the dbt project 

- run  ```bash dbtf compile ``` to compile the project 

-  run ```bash dbtf run``` this will take the sql file in the models dir and execute it against the data platform you choose when running ```bash dbtf init ```

- when using postgres locally ```bash dbtf run ``` will not work as of the time of writting as the connector is not avaliable you should insted run ```dbt run --profile postgres_profile --target dev``` incase you have more than one profile on your **profiles.yml file**.

- There was an issue when running dbtf with my databricks materialization as a view databricks would not accept to dbt materialization of views with the same name as the table in databricks so i reveretd to using 
```yml
models:
  jaffle_shop:
    +materialized: table
```
- The other issue was running dbt fusion bin with postgres venv all the runs used dbt fusion which was uncombatible with postgres so i uninstalled the bin and resorted to use ```dbt-core, dbt-databricks, dbt-postgres```. packages which solved the issue.

## Changing How your models are matrialized in dbt

To change how your models are materialized in dbt, you can configure the `+materialized` property either globally, by folder, or individually per model. 

### 1. Global materialization (for all models):

In your `dbt_project.yml`, set a default materialization for a directory or for all models in your project. For example:
```yml
models:
  jaffle_shop:
    +materialized: table
```
This ensures all models under `models/jaffle_shop/` will be materialized as tables, unless otherwise specified.

---

### 2. Folder-level materialization:

You can override materialization for specific folders in your model directory:
```yml
models:
  jaffle_shop:
    +materialized: table
    subfolder_name:
      +materialized: view
```
Models inside `models/jaffle_shop/subfolder_name/` will be materialized as views, overriding the parent folder setting.

---

### 3. Per-model materialization (inside model `.sql` file):

You can specify materialization for an individual model using the `config` macro at the top of your model file (before any SQL):
```sql
{{ config(materialized='incremental') }}

SELECT ...
```
Supported materialization options:
  - `table`
  - `view`
  - `incremental`
  - `ephemeral`

This will override any settings in `dbt_project.yml` for that specific model.

---

**Note:** dbt will resolve materialization in the order: model file config > folder config > parent/global config.

For more details, see: https://docs.getdbt.com/docs/build/materializations


### Overview: Dimensions (Dims) and Facts in dbt

When designing data models in dbt (or any analytics project), it's common to organize tables into "dimensions" (dims) and "facts".

#### Dimensions (Dims)
- **Definition:** Contain descriptive, categorical, or textual information about *entities* (people, places, things).
- **Examples:** 
    - `dim_customers`: customer_id, name, address, signup_date, etc.
    - `dim_products`: product_id, product_name, category, price, etc.
- **Purpose:** Used to provide context to fact tables, and are typically joined to fact tables on key columns.
- **Materialization:** Usually as `table` or `view`.

#### Facts
- **Definition:** Contain *event-based* or *transactional* data, typically numerical and time-stamped, representing something that occurred.
- **Examples:**
    - `fact_orders`: order_id, customer_id, product_id, order_date, amount, etc.
    - `fact_payments`: payment_id, order_id, payment_amount, payment_date, etc.
- **Purpose:** Central tables for analytics; measurements that can be aggregated (sum, count, average, etc.).
- **Materialization:** Often set as `incremental` or `table` for large data volumes.

#### Example Structure in dbt
```
models/
  dim/
    dim_customers.sql
    dim_products.sql
  fact/
    fact_orders.sql
    fact_payments.sql
```

- This structure improves clarity, maintainability, and helps ensure reliable analytics across your project.

#### Further Reading
- dbt best practices: [https://docs.getdbt.com/guides/best-practices/organize-your-project](https://docs.getdbt.com/guides/best-practices/organize-your-project)
- Kimball’s Dimensional Modeling: [https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/)

### dbt Best Practices: Naming Conventions

Establishing clear and consistent naming conventions is essential in dbt (and data projects in general) for maintainability, readability, and team collaboration. Here are recommended best practices:

#### General Principles
- **Be Descriptive and Consistent:** Choose names that accurately describe the data and follow the same patterns throughout your project.
- **Use Lowercase and Underscores:** Stick to `snake_case` (all lowercase, separate words with underscores), which is most compatible with SQL databases and dbt defaults.
- **Keep Names Concise but Informative:** Avoid unnecessary abbreviations, but don't make names overly long.

#### Table and Model Naming
- **Prefix with Layer or Role:** Use prefixes like `stg_`, `dim_`, or `fact_` to clearly identify the layer or role.
    - `stg_`: Staging models that closely mirror source data
    - `dim_`: Dimension tables
    - `fact_`: Fact tables
- **Include Source or Domain:** For staging models or when multiple sources exist, add the source or domain after the prefix.  
  Example:  
  - `stg_jaffle_shop__customers`
  - `stg_salesforce__accounts`
- **Double Underscore as Separator:** Use double underscores (`__`) to separate source from entity/table, which is the dbt community convention.

#### Column Naming
- **Use Clear, Domain-Specific Names:** Columns should be self-explanatory (e.g., `customer_id`, `order_date`, `total_amount`).
- **Primary Key Naming:** Name primary keys as `<entity>_id`, matching the table/entity name (e.g., `customer_id` in `dim_customers`).
- **Timestamps:** Use `_date` for dates, `_timestamp` for full timestamps (e.g., `order_date`, `created_at`).
- **Boolean Columns:** Prefix with `is_`, `has_`, or `was_` to indicate boolean values (e.g., `is_active`, `has_email`, `was_deleted`).

#### File Naming
- **Filename Matches Model/Table Name:** dbt uses filenames (without the `.sql` extension) as the model names, so keep them consistent with table/model naming.
    - e.g., `dim_customers.sql` -> model: `dim_customers`

#### Avoid Reserved Words and Special Characters
- **No Reserved Words:** Avoid SQL reserved keywords (e.g., `select`, `table`, `order`).
- **No Spaces or Special Characters:** Use only letters, numbers, and underscores.

#### Example Model Names
- `stg_salesforce__opportunities`
- `dim_products`
- `fact_orders`
- `int_orders_with_payments` (for intermediate models)

#### Further Reference
- dbt documentation: [https://docs.getdbt.com/guides/best-practices/how-we-structure/](https://docs.getdbt.com/guides/best-practices/how-we-structure/)
- [https://docs.getdbt.com/docs/build/naming-conventions](https://docs.getdbt.com/docs/build/naming-conventions)

### dbt `models/` Folder Structure: What Belongs Where?

A well-organized `models/` directory makes your dbt project easier to understand, maintain, and scale. Here’s an overview of common subfolders and what they typically contain:

#### 1. `models/staging/`
- **Purpose:** Contains *staging models* that closely replicate your raw source data (e.g., from a data warehouse, application database, or third-party API).
- **What to Store:** One model per raw source table (e.g., `stg_jaffle_shop__customers.sql`).
- **Characteristics:**
  - Minimal transformations—just renaming, type casting, and basic cleaning.
  - Naming pattern: `stg_<source>__<table>.sql`.

#### 2. `models/intermediate/` (or `models/intermediate/`)
- **Purpose:** Houses *intermediate models* used as building blocks for fact or dimension models, especially for reusable logic or complex transformation steps.
- **What to Store:** 
  - “INT” models that join, aggregate, or otherwise combine data from staging or other intermediate models (e.g., `int_orders_with_payments.sql`).
- **Characteristics:**
  - May not be directly exposed to end users—support analysis marts.

#### 3. `models/marts/` (or `models/core/`)
- **Purpose:** Contains your business-ready data models, typically organized further into facts and dimensions.
- **What to Store:**
  - `dim_` models: Dimension tables (e.g., `dim_customers.sql`).
  - `fact_` models: Fact tables (e.g., `fact_orders.sql`).
  - These are the main models exposed to analytics or reporting tools.

#### 4. `models/snapshots/` (optional—sometimes a separate top-level folder)
- **Purpose:** Stores dbt *snapshot* files, which let you track slowly changing dimensions (SCDs) over time.
- **What to Store:** 
  - Snapshot definitions (e.g., `customers_snapshot.sql`).

#### 5. `models/analysis/` or `models/analyses/` (optional)
- **Purpose:** Contains complex analysis queries, often used for ad hoc reporting, investigations, or prototypes.
- **What to Store:** 
  - Exploratory queries or Python notebooks saved as `.sql` files.

#### 6. `models/<custom-subfolders>/`
- **Purpose:** You can create additional subfolders for domains, business units, or projects (e.g., `models/finance/`, `models/marketing/`).
- **What to Store:** 
  - Related models for that business domain, often following the same folder conventions (`staging/`, `marts/`, etc.).

---

**Summary Table**

| Folder                       | Purpose/Contents                                                  |
|------------------------------|-------------------------------------------------------------------|
| `models/staging/`            | Raw, lightly cleaned source data (staging models)                 |
| `models/intermediate/`       | Intermediate/derived logic models                                 |
| `models/marts/`              | Fact and dimension models for BI/analytics                        |
| `models/snapshots/`          | Snapshot definitions (SCD tracking)                               |
| `models/analysis/`           | Analysis or exploratory queries                                   |
| `models/<domain>/`           | Domain-specific models (may contain own `staging/`, `marts/`, etc)|

For more details, see the [dbt Best Practices: How We Structure Our dbt Projects](https://docs.getdbt.com/guides/best-practices/how-we-structure/).




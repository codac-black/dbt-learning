    select
        "ID" as customer_id,
        "FIRST_NAME" as first_name,
        "LAST_NAME" as last_name
    from {{ source('jaffle_shop', 'customers') }}
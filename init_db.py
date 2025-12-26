import duckdb

con = duckdb.connect("churn.duckdb")

con.execute("""
    CREATE TABLE IF NOT EXISTS customers AS
    SELECT *
    FROM read_csv_auto('data/customer_churn_business_dataset.csv')
""")

print("DuckDB initialized successfully")

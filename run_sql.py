from pathlib import Path
import duckdb

DB_PATH = "churn.duckdb"
SQL_DIR = Path("sql")

def looks_like_query(sql: str) -> bool:
    # crude but effective: treat files that end with SELECT/WITH as query scripts
    s = sql.strip().lower()
    return s.startswith("select") or s.startswith("with")

def run_file(con: duckdb.DuckDBPyConnection, sql_path: Path):
    sql_text = sql_path.read_text(encoding="utf-8").strip()
    if not sql_text:
        print(f"\n--- Skipping empty file: {sql_path.name} ---")
        return

    print(f"\n--- Running: {sql_path.name} ---")

    try:
        # Run the script (may include DDL/DML). DuckDB will execute it.
        con.execute(sql_text)

        # If it *looks* like a query, try to fetch rows
        if looks_like_query(sql_text):
            try:
                df = con.fetchdf()
                print(df.head(20))
            except Exception:
                # Some queries may still not return a fetchable result in this context
                print("✅ Executed (no fetchable result).")
        else:
            print("✅ Executed (DDL/DML script, no result set expected).")

    except Exception as e:
        print(f"❌ Error in {sql_path.name}:\n{e}")
        raise

def main():
    con = duckdb.connect(DB_PATH)

    for sql_path in sorted(SQL_DIR.glob("*.sql")):
        run_file(con, sql_path)

    con.close()
    print("\n✅ Done.")

if __name__ == "__main__":
    main()

"""
main.py

Main entry point of the application.
"""
import os
import json
from dotenv import load_dotenv
from db_connector import get_connection, extract_schema, format_schema_for_prompt
from schema_analyzer import analyze_mapping, print_mapping_report
from sql_generator import generate_migration_sql, save_migration_sql

load_dotenv()

def main():
    # --- Configuration ---
    # Database credentials are read from the .env file.
    # In a production tool you'd use argparse for CLI arguments
    source_config = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", 5432)),
        "dbname": "source_legacy",
        "user": os.getenv("DB_USER", "postgres"),
        "password": os.getenv("DB_PASSWORD", ""),
    }
    target_config = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", 5432)),
        "dbname": "target_unified",
        "user": os.getenv("DB_USER", "postgres"),
        "password": os.getenv("DB_PASSWORD", ""),
    }

    # --- Step 1: Extract schemas ---
    print("Connecting to source database...")
    source_conn = get_connection(**source_config)
    source_schema = extract_schema(source_conn)
    source_conn.close()
    print(f"  Found {len(source_schema)} tables in source.\n")

    print("Connecting to target database...")
    target_conn = get_connection(**target_config)
    target_schema = extract_schema(target_conn)
    target_conn.close()
    print(f"  Found {len(target_schema)} tables in target.\n")

    # --- Step 2: Format schemas for the prompt ---
    source_text = format_schema_for_prompt(source_schema, "Source (Legacy)")
    target_text = format_schema_for_prompt(target_schema, "Target (Standardized)")

    # --- Step 3: Analyze mappings with Claude ---
    print("Analyzing schema mappings with Claude API...")
    mapping_result = analyze_mapping(source_text, target_text)

    # Print the report
    print_mapping_report(mapping_result)

    # Save mapping to JSON
    os.makedirs("../output", exist_ok=True)
    with open("../output/mapping_report.json", "w", encoding="utf-8") as f:
        json.dump(mapping_result, f, indent=2)
    print("\nMapping report saved to: ../output/mapping_report.json")

    # --- Step 4: Generate migration SQL ---
    print("\nGenerating migration SQL...")
    sql = generate_migration_sql(mapping_result)
    save_migration_sql(sql, "../output/migration.sql")

    print("\nDone.")

if __name__ == "__main__":
    main()
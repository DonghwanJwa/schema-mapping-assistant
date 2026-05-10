# Schema Mapping Assistant

A Python CLI tool that uses the Claude API to automatically analyze database schemas and generate column mappings and migration SQL for cross-system data migration.

## Problem

When migrating data between systems, manually mapping columns between source and target schemas is time-consuming and error-prone — especially when dealing with different naming conventions, data types, and structures.

## Solution

This tool automates schema analysis by:
- Connecting to source and target PostgreSQL databases
- Extracting schema metadata (tables, columns, types, constraints)
- Using Claude's API to intelligently match columns across schemas
- Flagging type mismatches and potential data loss risks
- Generating ready-to-review SQL transformation queries

## Tech Stack

- Python 3.10+
- Claude API (`claude-sonnet-4-6`)
- PostgreSQL + postgres_fdw
- psycopg2-binary
- python-dotenv

## Project Structure

```
schema-mapping-assistant/
├── src/
│   ├── main.py              # Entry point
│   ├── db_connector.py      # DB connection and schema extraction
│   ├── schema_analyzer.py   # Claude API: schema mapping analysis
│   ├── sql_generator.py     # Claude API: migration SQL generation
│   └── .env                 # Credentials (not committed)
├── output/                  # Generated reports and SQL (auto-created)
│   ├── mapping_report.json
│   └── migration.sql
├── setup_source.sql         # Source database schema + sample data
├── setup_target.sql         # Target database schema
└── requirements.txt
```

## Setup

### 1. Install dependencies

```bash
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
```

### 2. Set up PostgreSQL databases

```bash
psql -U postgres -c "CREATE DATABASE source_legacy;"
psql -U postgres -c "CREATE DATABASE target_unified;"

psql -U postgres -d source_legacy  -f setup_source.sql
psql -U postgres -d target_unified -f setup_target.sql
```

### 3. Configure environment variables

Create `src/.env`:

```env
ANTHROPIC_API_KEY=your_anthropic_api_key
DB_HOST=localhost
DB_PORT=5432
DB_USER=your_db_user
DB_PASSWORD=your_db_password
```

## Usage

Run from the `src/` directory:

```bash
cd src
python main.py
```

The tool will:
1. Connect to both databases and extract their schemas
2. Send the schemas to Claude for analysis
3. Print a mapping report to the console
4. Save `output/mapping_report.json`
5. Generate `output/migration.sql`

## Example Output

### Mapping Report (console)

```
======================================================================
SCHEMA MAPPING REPORT
======================================================================

emp_master  -->  employees
----------------------------------------------------------------------
Source Column             Target Column             Risk
----------------------------------------------------------------------
emp_no                    employee_id               [HIGH]
  ^ Transform: String key must be remapped to a generated integer ID via lookup table
hire_dt                   hire_date                 [HIGH]
  ^ Transform: VARCHAR date string must be cast to DATE using TO_DATE()
active_yn                 is_active                 [MEDIUM]
  ^ Transform: CHAR 'Y'/'N' must be converted to BOOLEAN

trn_records  -->  training_completions
----------------------------------------------------------------------
score_pct                 score                     [HIGH]
  ^ Transform: Percentage (0-100) must be divided by 100 to match target scale (0.000-1.000)
```

### Generated SQL structure (`migration.sql`)

```sql
-- STEP 1: PREREQUISITES
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER ...          -- TODO: replace with actual SOURCE connection value
CREATE USER MAPPING ...    -- TODO: replace with actual SOURCE credentials
CREATE SCHEMA IF NOT EXISTS migration_metadata;
CREATE TABLE migration_metadata.pre_migration_counts (...);
...

-- STEP 2: PRE-MIGRATION VALIDATION
INSERT INTO migration_metadata.pre_migration_counts
SELECT count(*) FROM source_schema.emp_master;
...

-- STEP 3: MIGRATION
SET CONSTRAINTS ALL DEFERRED;
INSERT INTO migration_metadata.key_mapping ...
INSERT INTO employees SELECT ... FROM source_schema.emp_master ...;
...

-- STEP 4: POST-MIGRATION VALIDATION
SET CONSTRAINTS ALL IMMEDIATE;
SELECT setval(...);
INSERT INTO migration_metadata.validation_results ...;
```

## Notes

- The generated `migration.sql` targets the TARGET database only — SOURCE data is accessed through `source_schema` (postgres_fdw)
- Before executing `migration.sql`, fill in the `-- TODO` placeholders in Step 1 with your actual SOURCE connection values
- All migration activity is tracked in `migration_metadata` tables for auditing and rollback planning

## Potential Extensions

This project could be extended in a number of directions depending on need.

**CLI & Usability**
- Source/target DB names, host, and model could be passed as command-line arguments via `argparse` rather than being hardcoded — `main.py` already has a note about this
- A `--dry-run` mode could allow running the analysis and printing the report without generating any SQL

**Migration Execution**
- A Python-based migration executor could read from source and write to target directly via `psycopg2`, enabling row-level error handling and live progress reporting
- Incremental migration could be explored, where only rows changed since the last run are migrated

**Database Support**
- The schema extraction in `db_connector.py` could be abstracted to support other database engines such as MySQL, SQL Server, or SQLite
- Multi-schema support could be added — currently only the `public` schema is queried

**Mapping Quality**
- A manual mapping override file (YAML or JSON) could allow users to correct mappings that Claude gets wrong before SQL is generated
- Claude could be asked to include a confidence score per column match alongside its mapping output

**Reporting**
- The mapping report could be exported to HTML or Excel in addition to JSON
- A rough Claude API cost estimate could be shown upfront based on schema size

**Validation**
- A Python-based post-migration validator could programmatically compare row counts, checksums, and sample rows between source and target, as an alternative to relying solely on the SQL validation queries

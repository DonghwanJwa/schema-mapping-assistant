"""
db_connector.py

Manage DB Connection and extract schema information.
"""
import psycopg2

def get_connection(host, port, dbname, user, password):
    """Create a database connection."""
    return psycopg2.connect(
        host=host,
        port=port,
        dbname=dbname,
        user=user,
        password=password
    )


def extract_schema(connection, schema_name="public"):
    """
    Extract table and column metadata from a PostgreSQL database.

    Returns a dict like:
    {
        "table_name": [
            {
                "column_name": "id",
                "data_type": "integer",
                "is_nullable": "NO",
                "column_default": "nextval(...)",
                "character_maximum_length": None
            },
            ...
        ]
    }
    """
    query = """
        SELECT
            t.table_name,
            c.column_name,
            c.data_type,
            c.is_nullable,
            c.column_default,
            c.character_maximum_length,
            c.numeric_precision,
            c.numeric_scale,
            c.ordinal_position
        FROM information_schema.tables t
        JOIN information_schema.columns c
            ON t.table_name = c.table_name
            AND t.table_schema = c.table_schema
        WHERE t.table_schema = %s
            AND t.table_type = 'BASE TABLE'
        ORDER BY t.table_name, c.ordinal_position;
    """

    cursor = connection.cursor()
    cursor.execute(query, (schema_name,))
    rows = cursor.fetchall()
    cursor.close()

    schema = {}
    for row in rows:
        table = row[0]
        if table not in schema:
            schema[table] = []
        schema[table].append({
            "column_name": row[1],
            "data_type": row[2],
            "is_nullable": row[3],
            "column_default": row[4],
            "character_maximum_length": row[5],
            "numeric_precision": row[6],
            "numeric_scale": row[7],
        })

    return schema


def format_schema_for_prompt(schema, db_label):
    """Format schema dict into a readable string for the LLM prompt."""
    lines = [f"==={db_label}===\n"]
    for table, columns in schema.items():
        lines.append(f"Table:{table}")
        for col in columns:
            col_desc = f"  - {col['column_name']} ({col['data_type']}"
            if col["character_maximum_length"]:
                col_desc += f", max_length={col['character_maximum_length']}"
            if col["numeric_precision"]:
                col_desc += f", precision={col['numeric_precision']}"
                if col["numeric_scale"]:
                    col_desc += f", scale={col['numeric_scale']}"
            col_desc += f", nullable={col['is_nullable']}"
            if col["column_default"]:
                col_desc += f", default={col['column_default']}"
            col_desc += ")"
            lines.append(col_desc)
        lines.append("")
    return "\n".join(lines)
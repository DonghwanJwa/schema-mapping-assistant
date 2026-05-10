"""
schema_analyzer.py

Send schemas to Claude to analyze mapping.
"""
import json
import anthropic
from dotenv import load_dotenv

load_dotenv()

def analyze_mapping(source_schema_text, target_schema_text):
    """
    Sned source and target schemas to Claude API.
    Returns structured mapping reommendations.
    """

    client = anthropic.Anthropic()
    prompt = f"""You are a data engineering expert specializing in database migrations and schema mapping.

I have a SOURCE database (legacy system) and a TARGET database (new standardized system). I need you to:

1. **Map columns**: For each target table, identify which source table and column maps to each target column.
2. **Flag type mismatches**: Where source and target data types differ, note what transformation is needed.
3. **Flag risks**: Identify any potential data loss, truncation, or conversion issues.
4. **Generate mapping summary**: Provide a clear mapping table.

SOURCE DATABASE SCHEMA:
{source_schema_text}

TARGET DATABASE SCHEMA:
{target_schema_text}

Respond in the following JSON format:
{{
    "table_mappings": [
        {{
            "target_table": "table_name",
            "source_table": "table_name",
            "column_mappings": [
                {{
                    "target_column": "column_name",
                    "source_column": "column_name",
                    "source_type": "type",
                    "target_type": "type",
                    "transformation_needed": true/false,
                    "transformation_note": "description of needed transformation or null",
                    "risk_level": "none|low|medium|high",
                    "risk_note": "description of risk or null"
                }}
            ]
        }}
    ],
    "overall_risks": [
        "list of high-level migration risks or concerns"
    ],
    "recommendations": [
        "list of recommendations for the migration"
    ]
}}

Be thorough. Consider type conversions, potential data truncation, encoding issues, and referential integrity.
Be precise and concise — limit transformation_note and risk_note to 1-2 sentences each. Do not repeat information already captured in other fields."""

    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=16384,
        messages=[{"role": "user", "content": prompt}],
    )

    if message.stop_reason == "max_tokens":
        raise RuntimeError("Claude response was truncated. Increase max_tokens further.")

    #Extract the text response
    response_text = message.content[0].text

    #Parse JSON from response (handle markdown code blocks if present)
    if "```json" in response_text:
        response_text = response_text.split("```json")[1].split("```")[0]
    elif "```" in response_text:
        response_text = response_text.split("```")[1].split("```")[0]

    return json.loads(response_text.strip())


def print_mapping_report(mapping_result):
    """Print a human-readable mapping report."""
    print("=" * 70)
    print("SCHEMA MAPPING REPORT")
    print("=" * 70)

    for table_map in mapping_result["table_mappings"]:
        print(f"\n{table_map['source_table']}  -->  {table_map['target_table']}")
        print("-" * 70)
        print(f"{'Source Column':<25} {'Target Column':<25} {'Risk':<10}")
        print("-" * 70)

        for col in table_map["column_mappings"]:
            risk = col.get("risk_level", "none")
            risk_display = f"[{risk.upper()}]" if risk != "none" else ""
            print(f"{col['source_column']:<25} {col['target_column']:<25} {risk_display:<10}")

            if col.get("transformation_needed"):
                print(f"  ^ Transform: {col['transformation_note']}")
            if col.get("risk_note"):
                print(f"  ^ Risk: {col['risk_note']}")

    if mapping_result.get("overall_risks"):
        print(f"\n{'=' * 70}")
        print("OVERALL RISKS")
        print("=" * 70)
        for risk in mapping_result["overall_risks"]:
            print(f"  - {risk}")

    if mapping_result.get("recommendations"):
        print(f"\n{'=' * 70}")
        print("RECOMMENDATIONS")
        print("=" * 70)
        for rec in mapping_result["recommendations"]:
            print(f"  - {rec}")
            
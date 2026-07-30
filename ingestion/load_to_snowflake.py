"""load_to_snowflake.py
Loads the California Hospital Q1 2025 Kaggle CSVs into Snowflake RAW_HEALTHCARE
using PUT (local file -> internal stage) followed by COPY INTO.

Usage: python load_to_snowflake.py
Requires a .env file (see .env.example) with Snowflake connection details.
"""
import csv
import logging
import os
import sys
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
log = logging.getLogger("load_to_snowflake")

load_dotenv()

REQUIRED_ENV_VARS = [
    "SNOWFLAKE_ACCOUNT", "SNOWFLAKE_USER", "SNOWFLAKE_PASSWORD",
    "SNOWFLAKE_ROLE", "SNOWFLAKE_WAREHOUSE", "SNOWFLAKE_DATABASE", "SNOWFLAKE_SCHEMA",
]

TABLE_CONFIG = {
    "patients.csv": {"table": "PATIENTS", "columns": [
        "patient_id", "first_name", "last_name", "dob", "age", "gender",
        "ethnicity", "insurance_type", "marital_status", "address",
        "city", "state", "zip", "phone", "email", "registration_date"]},
    "providers.csv": {"table": "PROVIDERS", "columns": [
        "provider_id", "name", "department", "specialty", "npi", "inhouse",
        "location", "years_experience", "contact_info", "email"]},
    "encounters.csv": {"table": "ENCOUNTERS", "columns": [
        "encounter_id", "patient_id", "provider_id", "visit_date", "visit_type",
        "department", "reason_for_visit", "diagnosis_code", "admission_type",
        "discharge_date", "length_of_stay", "status", "readmitted_flag"]},
    "diagnoses.csv": {"table": "DIAGNOSES", "columns": [
        "diagnosis_id", "encounter_id", "diagnosis_code", "diagnosis_description",
        "primary_flag", "chronic_flag"]},
    "procedures.csv": {"table": "PROCEDURES", "columns": [
        "procedure_id", "encounter_id", "procedure_code", "procedure_description",
        "procedure_date", "provider_id", "procedure_cost"]},
    "claims_and_billing.csv": {"table": "CLAIMS_AND_BILLING", "columns": [
        "billing_id", "patient_id", "encounter_id", "insurance_provider",
        "payment_method", "claim_id", "claim_billing_date", "billed_amount",
        "paid_amount", "claim_status", "denial_reason"]},
    "denials.csv": {"table": "DENIALS", "columns": [
        "claim_id", "denial_id", "denial_reason_code", "denial_reason_description",
        "denied_amount", "denial_date", "appeal_filed", "appeal_status",
        "appeal_resolution_date", "final_outcome"]},
}

STAGE_NAME = "RAW_HEALTHCARE.STG_CSV_LOAD"
FILE_FORMAT_NAME = "RAW_HEALTHCARE.FF_CSV_STANDARD"


def get_connection():
    missing = [v for v in REQUIRED_ENV_VARS if not os.getenv(v)]
    if missing:
        log.error("Missing required environment variables: %s", ", ".join(missing))
        sys.exit(1)
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        role=os.getenv("SNOWFLAKE_ROLE"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database=os.getenv("SNOWFLAKE_DATABASE"),
        schema=os.getenv("SNOWFLAKE_SCHEMA"),
    )


def validate_csv_header(csv_path, expected_columns):
    with open(csv_path, newline="", encoding="utf-8") as f:
        header = next(csv.reader(f))
    if [h.strip() for h in header] != expected_columns:
        raise ValueError("%s: header mismatch. expected=%s found=%s" % (csv_path.name, expected_columns, header))


def put_file(cursor, csv_path):
    log.info("PUT %s -> @%s", csv_path.name, STAGE_NAME)
    cursor.execute("PUT 'file://{}' @{} AUTO_COMPRESS=TRUE OVERWRITE=TRUE".format(csv_path.as_posix(), STAGE_NAME))


def copy_into(cursor, csv_filename, table, columns):
    staged_file = "{}.gz".format(csv_filename)
    select_cols = ", ".join("$" + str(i + 1) for i in range(len(columns)))
    target_cols = ", ".join(columns + ["_source_file"])
    copy_sql = "COPY INTO RAW_HEALTHCARE.{} ({}) FROM (SELECT {}, METADATA$FILENAME FROM @{}/{}) FILE_FORMAT = (FORMAT_NAME = {}) ON_ERROR = 'ABORT_STATEMENT'".format(
        table, target_cols, select_cols, STAGE_NAME, staged_file, FILE_FORMAT_NAME
    )
    log.info("COPY INTO RAW_HEALTHCARE.%s from %s", table, staged_file)
    cursor.execute(copy_sql)
    result = cursor.fetchall()
    rows_loaded = sum(r[3] for r in result) if result else 0
    log.info("  -> %s rows loaded into %s", rows_loaded, table)
    return rows_loaded


def main():
    csv_dir = Path(os.getenv("KAGGLE_CSV_DIR", "./data/raw_csv")).resolve()
    if not csv_dir.exists():
        log.error("CSV directory not found: %s", csv_dir)
        log.error("Download the Kaggle dataset and place the CSVs there first.")
        sys.exit(1)

    conn = get_connection()
    cursor = conn.cursor()
    summary = {}

    try:
        for csv_filename, config in TABLE_CONFIG.items():
            csv_path = csv_dir / csv_filename
            if not csv_path.exists():
                log.warning("Skipping %s - file not found in %s", csv_filename, csv_dir)
                continue
            validate_csv_header(csv_path, config["columns"])
            put_file(cursor, csv_path)
            rows_loaded = copy_into(cursor, csv_filename, config["table"], config["columns"])
            summary[config["table"]] = rows_loaded

        log.info("=" * 50)
        log.info("Load summary:")
        for table, count in summary.items():
            log.info("  %-25s %s rows", table, count)
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()

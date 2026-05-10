-- ============================================
-- TARGET DATABASE: target_unified
-- ============================================
-- This is the clean, standardized schema that
-- data from the legacy source system will be
-- migrated into. Uses proper data types, full
-- column names, and consistent naming conventions.
--
-- To use:
--   1. CREATE DATABASE target_unified;
--   2. Connect to target_unified
--   3. Run this script
-- ============================================

-- Drop tables if they already exist (safe to re-run this script)
DROP TABLE IF EXISTS training_completions;
DROP TABLE IF EXISTS project_assignments;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- Employees table
-- Note: proper DATE type, BOOLEAN, INTEGER IDs
CREATE TABLE employees (
    employee_id         INTEGER PRIMARY KEY,
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    department_id       INTEGER,
    hire_date           DATE,
    annual_salary       NUMERIC(12,2),
    manager_id          INTEGER,
    is_active           BOOLEAN,
    updated_at          TIMESTAMP WITH TIME ZONE
);

-- Departments table
CREATE TABLE departments (
    department_id       SERIAL PRIMARY KEY,
    department_name     VARCHAR(200),
    location_code       VARCHAR(20),
    annual_budget       NUMERIC(15,2),
    employee_count      INTEGER,
    created_date        DATE
);

-- Project assignments table
CREATE TABLE project_assignments (
    assignment_id       SERIAL PRIMARY KEY,
    employee_id         INTEGER,
    project_code        VARCHAR(50),
    role_name           VARCHAR(200),
    start_date          DATE,
    end_date            DATE,
    weekly_hours        NUMERIC(5,1)
);

-- Training completions table
-- Note: score stored as decimal 0.0-1.0 (not percentage),
-- boolean pass/fail, proper DATE types
CREATE TABLE training_completions (
    completion_id       SERIAL PRIMARY KEY,
    employee_id         INTEGER,
    course_code         VARCHAR(50),
    course_name         VARCHAR(300),
    completed_date      DATE,
    score               NUMERIC(4,3),       -- 0.000 to 1.000 (not 0-100)
    passed              BOOLEAN,
    certification_expiry DATE
);

-- Note: The source system has an equip_inv table that has
-- no equivalent in the target schema. The mapping tool
-- should flag this as an unmapped/orphan table.

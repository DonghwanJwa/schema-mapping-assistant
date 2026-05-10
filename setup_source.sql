-- ============================================
-- SOURCE DATABASE: source_legacy
-- ============================================
-- This simulates a legacy enterprise system with
-- inconsistent naming, string-typed dates, and
-- abbreviated column names — typical of the kind
-- of systems you'd encounter in real data migration work.
--
-- To use:
--   1. CREATE DATABASE source_legacy;
--   2. Connect to source_legacy
--   3. Run this script
-- ============================================

-- Drop tables if they already exist (safe to re-run this script)
DROP TABLE IF EXISTS trn_records;
DROP TABLE IF EXISTS equip_inv;
DROP TABLE IF EXISTS proj_assign;
DROP TABLE IF EXISTS emp_master;
DROP TABLE IF EXISTS dept_info;

-- Employee master table
-- Note: dates stored as VARCHAR, active flag as CHAR, IDs as strings
CREATE TABLE emp_master (
    emp_no          VARCHAR(20) PRIMARY KEY,
    f_name          VARCHAR(50),
    l_name          VARCHAR(50),
    dept_cd         VARCHAR(10),
    hire_dt         VARCHAR(10),        -- date stored as string 'YYYY-MM-DD'
    salary_amt      NUMERIC(10,2),
    mgr_emp_no      VARCHAR(20),
    active_yn       CHAR(1),            -- 'Y' or 'N' instead of boolean
    last_mod_ts     TIMESTAMP
);

-- Department information table
CREATE TABLE dept_info (
    dept_cd         VARCHAR(10) PRIMARY KEY,
    dept_nm         VARCHAR(100),
    loc_cd          VARCHAR(10),
    budget_amt      NUMERIC(15,2),
    head_count      INTEGER,
    create_dt       VARCHAR(10)         -- date stored as string
);

-- Project assignment table
CREATE TABLE proj_assign (
    assign_id       SERIAL PRIMARY KEY,
    emp_no          VARCHAR(20),
    proj_cd         VARCHAR(20),
    role_desc       VARCHAR(100),
    start_dt        VARCHAR(10),        -- date stored as string
    end_dt          VARCHAR(10),        -- date stored as string, NULL = ongoing
    hrs_per_wk      NUMERIC(4,1)
);

-- Equipment inventory table (no direct target equivalent — tests orphan detection)
CREATE TABLE equip_inv (
    equip_id        VARCHAR(15) PRIMARY KEY,
    equip_nm        VARCHAR(100),
    dept_cd         VARCHAR(10),
    purchase_dt     VARCHAR(10),
    purchase_amt    NUMERIC(10,2),
    condition_cd    CHAR(1),            -- 'G' = Good, 'F' = Fair, 'P' = Poor
    assigned_emp    VARCHAR(20)
);

-- Training records table
CREATE TABLE trn_records (
    trn_id          SERIAL PRIMARY KEY,
    emp_no          VARCHAR(20),
    course_cd       VARCHAR(20),
    course_nm       VARCHAR(200),
    complete_dt     VARCHAR(10),
    score_pct       NUMERIC(5,2),       -- stored as percentage 0-100
    pass_yn         CHAR(1),            -- 'Y' or 'N'
    cert_expiry_dt  VARCHAR(10)
);

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Departments
INSERT INTO dept_info VALUES
('D001', 'Engineering',       'LOC01', 500000.00, 25, '2015-03-15'),
('D002', 'Marketing',         'LOC02', 300000.00, 15, '2016-07-01'),
('D003', 'Operations',        'LOC01', 450000.00, 30, '2015-03-15'),
('D004', 'Human Resources',   'LOC02', 200000.00, 10, '2015-06-01'),
('D005', 'Finance',           'LOC03', 350000.00, 12, '2017-01-15');

-- Employees (mix of active and inactive, some with managers, some without)
INSERT INTO emp_master VALUES
('E001', 'John',    'Smith',    'D001', '2018-06-15', 85000.00,  NULL,   'Y', '2024-01-10 09:30:00'),
('E002', 'Jane',    'Park',     'D001', '2019-03-20', 92000.00,  'E001', 'Y', '2024-02-15 14:20:00'),
('E003', 'Mike',    'Lee',      'D002', '2020-01-10', 78000.00,  NULL,   'Y', '2024-01-05 11:00:00'),
('E004', 'Sara',    'Kim',      'D003', '2017-11-01', 95000.00,  NULL,   'N', '2023-12-01 08:45:00'),
('E005', 'David',   'Chen',     'D001', '2021-08-22', 88000.00,  'E001', 'Y', '2024-03-01 10:15:00'),
('E006', 'Emily',   'Wong',     'D004', '2019-05-10', 72000.00,  NULL,   'Y', '2024-02-20 16:30:00'),
('E007', 'Robert',  'Nguyen',   'D005', '2020-09-14', 91000.00,  NULL,   'Y', '2024-01-28 13:45:00'),
('E008', 'Maria',   'Garcia',   'D002', '2022-02-01', 68000.00,  'E003', 'Y', '2024-03-05 09:00:00'),
('E009', 'James',   'Patel',    'D003', '2018-04-15', 82000.00,  'E004', 'N', '2023-11-15 11:30:00'),
('E010', 'Linda',   'Nakamura', 'D001', '2023-01-09', 75000.00,  'E001', 'Y', '2024-03-10 08:00:00');

-- Project assignments (some ongoing with NULL end dates)
INSERT INTO proj_assign (emp_no, proj_cd, role_desc, start_dt, end_dt, hrs_per_wk) VALUES
('E001', 'PRJ-100', 'Lead Developer',      '2023-01-15', NULL,         30.0),
('E002', 'PRJ-100', 'Backend Developer',    '2023-02-01', NULL,         25.0),
('E003', 'PRJ-200', 'Campaign Manager',     '2023-06-01', '2024-01-31', 40.0),
('E005', 'PRJ-100', 'Frontend Developer',   '2023-03-15', NULL,         20.0),
('E005', 'PRJ-300', 'Code Reviewer',        '2023-09-01', NULL,         10.0),
('E006', 'PRJ-400', 'HR System Migration',  '2023-04-01', '2023-12-31', 35.0),
('E007', 'PRJ-500', 'Budget Forecasting',   '2023-07-01', NULL,         15.0),
('E008', 'PRJ-200', 'Content Specialist',   '2023-08-01', '2024-01-31', 30.0),
('E009', 'PRJ-300', 'Ops Lead',             '2023-05-01', '2023-10-31', 40.0),
('E010', 'PRJ-100', 'Junior Developer',     '2023-06-01', NULL,         35.0);

-- Equipment inventory
INSERT INTO equip_inv VALUES
('EQ001', 'MacBook Pro 16"',      'D001', '2023-01-15', 3499.99, 'G', 'E001'),
('EQ002', 'Dell Monitor 27"',     'D001', '2022-06-10', 549.99,  'G', 'E002'),
('EQ003', 'Standing Desk',        'D002', '2022-03-20', 899.00,  'F', 'E003'),
('EQ004', 'Projector XL-500',     'D003', '2020-11-05', 1299.00, 'P', NULL),
('EQ005', 'MacBook Pro 14"',      'D001', '2023-06-01', 2999.99, 'G', 'E005'),
('EQ006', 'Ergonomic Chair',      'D004', '2021-09-15', 1200.00, 'G', 'E006'),
('EQ007', 'ThinkPad X1 Carbon',   'D005', '2023-02-28', 1899.00, 'G', 'E007');

-- Training records (mix of passed and failed, some with expired certs)
INSERT INTO trn_records (emp_no, course_cd, course_nm, complete_dt, score_pct, pass_yn, cert_expiry_dt) VALUES
('E001', 'CRS-SEC01', 'Security Awareness Training',    '2023-03-15', 92.50, 'Y', '2024-03-15'),
('E001', 'CRS-AGI01', 'Agile Project Management',       '2023-06-20', 88.00, 'Y', NULL),
('E002', 'CRS-SEC01', 'Security Awareness Training',    '2023-03-15', 95.00, 'Y', '2024-03-15'),
('E002', 'CRS-PY01',  'Advanced Python',                '2023-09-10', 78.50, 'Y', NULL),
('E003', 'CRS-SEC01', 'Security Awareness Training',    '2023-04-01', 85.00, 'Y', '2024-04-01'),
('E003', 'CRS-MKT01', 'Digital Marketing Fundamentals', '2023-07-15', 91.00, 'Y', NULL),
('E004', 'CRS-SEC01', 'Security Awareness Training',    '2022-03-10', 60.00, 'N', NULL),
('E005', 'CRS-SEC01', 'Security Awareness Training',    '2023-09-01', 97.00, 'Y', '2024-09-01'),
('E006', 'CRS-HR01',  'Employment Law Basics',          '2023-05-20', 89.00, 'Y', '2025-05-20'),
('E007', 'CRS-FIN01', 'Financial Reporting Standards',  '2023-08-12', 94.50, 'Y', '2025-08-12'),
('E008', 'CRS-SEC01', 'Security Awareness Training',    '2023-11-01', 72.00, 'Y', '2024-11-01'),
('E009', 'CRS-SEC01', 'Security Awareness Training',    '2022-06-15', 45.00, 'N', NULL),
('E010', 'CRS-SEC01', 'Security Awareness Training',    '2024-01-10', 88.00, 'Y', '2025-01-10');

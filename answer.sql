-- ============================================================
-- POSTGRESQL ADVANCED SQL LAB
-- File: answer.sql
-- Database: bootcamp
-- ============================================================


-- ============================================================
-- STEP 1: BUILD A REUSABLE AUDIT LOG
-- ============================================================

-- Create the audit table

CREATE TABLE audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tbl TEXT,
    op TEXT,
    old_row JSONB,
    new_row JSONB,
    changed_by TEXT DEFAULT current_user,
    at TIMESTAMPTZ DEFAULT now()
);


-- Create the reusable audit function

CREATE OR REPLACE FUNCTION audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        tbl,
        op,
        old_row,
        new_row
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        to_jsonb(OLD),
        to_jsonb(NEW)
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;


-- Create the audit trigger on students

CREATE TRIGGER trg_audit
AFTER INSERT OR UPDATE OR DELETE
ON students
FOR EACH ROW
EXECUTE FUNCTION audit();


-- ============================================================
-- STEP 2: TEST THE AUDIT LOG
-- ============================================================

-- Update student ID 1

UPDATE students
SET name = 'Kofi M.'
WHERE id = 1;


-- Delete student ID 3

DELETE FROM students
WHERE id = 3;


-- Display the audit trail

SELECT
    tbl,
    op,
    old_row->>'name' AS was,
    new_row->>'name' AS now,
    at
FROM audit_log
ORDER BY at DESC;


-- ============================================================
-- STEP 3: MODEL A CATEGORY TREE
-- ============================================================

-- Create categories table

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT,
    parent_id INT REFERENCES categories(id)
);


-- Insert category hierarchy

INSERT INTO categories (name, parent_id) VALUES
    ('Electronics', NULL),
    ('Computers', 1),
    ('Laptops', 2),
    ('Phones', 1);


-- Display the category tree using a recursive CTE

WITH RECURSIVE tree AS (
    SELECT
        id,
        name,
        parent_id,
        0 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.id,
        c.name,
        c.parent_id,
        t.depth + 1
    FROM categories c
    JOIN tree t
        ON c.parent_id = t.id
)
SELECT
    repeat('  ', depth) || name AS tree
FROM tree
ORDER BY depth, name;


-- ============================================================
-- STEP 4: FLYWAY MIGRATIONS
-- ============================================================

-- Flyway commands are terminal commands, not SQL.
--
-- Example migration files:
--
-- migrations/
-- ├── V1__core_tables.sql
-- ├── V2__audit_log.sql
-- └── V3__categories.sql
--
-- Run the following commands from the terminal:
--
-- flyway -url=jdbc:postgresql://localhost/bootcamp -user=postgres migrate
-- flyway info


-- ============================================================
-- STEP 5: LEAST-PRIVILEGE SECURITY
-- ============================================================

-- Create read and write roles

CREATE ROLE app_read;
CREATE ROLE app_write;


-- Allow the roles to connect to the database

GRANT CONNECT
ON DATABASE bootcamp
TO app_read, app_write;


-- Allow the roles to use the public schema

GRANT USAGE
ON SCHEMA public
TO app_read, app_write;


-- Read-only permissions

GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO app_read;


-- Read/write permissions

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO app_write;


-- Create API user and assign write role

CREATE USER api
LOGIN
PASSWORD 'strong-secret'
IN ROLE app_write;


-- ============================================================
-- OPTIONAL: VERIFY PERMISSIONS
-- ============================================================

-- Check roles

\du


-- Check table privileges

\dp


-- ============================================================
-- END OF ASSIGNMENT
-- ============================================================

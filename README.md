# PostgreSQL Database Assignment

## Overview

This assignment demonstrates several important PostgreSQL database concepts:

- Audit logging using triggers
- JSONB data storage
- Hierarchical data using self-referencing tables
- Recursive Common Table Expressions (CTEs)
- Database schema migrations using Flyway
- Role-based access control
- Least-privilege database security

The main SQL solutions are contained in `answer.sql`.

---

## Project Structure

```text
postgresql-assignment/
│
├── answer.sql
├── README.md
│
└── migrations/
    ├── V1__core_tables.sql
    ├── V2__audit_log.sql
    └── V3__categories.sql
```

---

# Step 1: Reusable Audit Log

An `audit_log` table was created to record changes made to database tables.

The table stores:

- `tbl` - the table where the change occurred
- `op` - the operation performed
- `old_row` - the previous row stored as JSONB
- `new_row` - the new row stored as JSONB
- `changed_by` - the PostgreSQL user who made the change
- `at` - the time the change occurred

A reusable PostgreSQL trigger function named `audit()` was also created.

The trigger records:

- INSERT
- UPDATE
- DELETE

operations performed on the `students` table.

---

# Step 2: Test the Audit Log

The audit trigger was tested by updating student ID 1 and deleting student ID 3.

Example update:

```sql
UPDATE students
SET name = 'Kofi M.'
WHERE id = 1;
```

Example delete:

```sql
DELETE FROM students
WHERE id = 3;
```

The audit records can be viewed using:

```sql
SELECT
    tbl,
    op,
    old_row->>'name' AS was,
    new_row->>'name' AS now,
    at
FROM audit_log
ORDER BY at DESC;
```

For an UPDATE, both the old and new values are available.

For a DELETE, the old value is available while the new value is NULL.

---

# Step 3: Category Tree

A self-referencing `categories` table was created.

The `parent_id` column references the `id` column of the same table.

This allows categories to have parent-child relationships.

Example hierarchy:

```text
Electronics
  Computers
    Laptops
  Phones
```

The category data was inserted using:

```sql
INSERT INTO categories (name, parent_id) VALUES
    ('Electronics', NULL),
    ('Computers', 1),
    ('Laptops', 2),
    ('Phones', 1);
```

A recursive CTE was used to walk through the category hierarchy.

---

# Step 4: Flyway Migrations

Flyway is used to manage database schema changes in an ordered and repeatable way.

The migration files are organized as:

```text
migrations/
├── V1__core_tables.sql
├── V2__audit_log.sql
└── V3__categories.sql
```

The version numbers determine the order in which migrations are applied.

The migrations can be executed from the terminal using:

```shell
flyway -url=jdbc:postgresql://localhost/bootcamp -user=postgres migrate
```

Migration status can be checked using:

```shell
flyway info
```

Flyway records which migrations have already been applied, helping to prevent the same migration from being executed repeatedly.

---

# Step 5: Least-Privilege Security

Two PostgreSQL roles were created:

```text
app_read
app_write
```

## app_read

The `app_read` role receives only:

```text
SELECT
```

This allows the role to read data without modifying it.

## app_write

The `app_write` role receives:

```text
SELECT
INSERT
UPDATE
DELETE
```

This allows normal application data operations.

The API user was then created and assigned to the write role:

```sql
CREATE USER api
LOGIN
PASSWORD 'strong-secret'
IN ROLE app_write;
```

This means the API user inherits the permissions assigned to `app_write`.

---

# Technologies Used

- PostgreSQL
- SQL
- PL/pgSQL
- JSONB
- Recursive CTE
- PostgreSQL Triggers
- PostgreSQL Roles
- Flyway

---

# How to Run

## 1. Open PostgreSQL

Use PostgreSQL with pgAdmin 4, psql, or another PostgreSQL-compatible SQL client.

## 2. Select the `bootcamp` database

All assignment SQL should be executed against the `bootcamp` database.

## 3. Run `answer.sql`

Execute the SQL statements in `answer.sql`.

## 4. Run Flyway

From a terminal, run:

```shell
flyway -url=jdbc:postgresql://localhost/bootcamp -user=postgres migrate
```

Then check:

```shell
flyway info
```

## 5. Verify the results

Check the audit log:

```sql
SELECT * FROM audit_log;
```

Check the categories:

```sql
SELECT * FROM categories;
```

Check the PostgreSQL roles:

```sql
SELECT rolname
FROM pg_roles
WHERE rolname IN ('app_read', 'app_write', 'api');
```

---

# Learning Outcomes

After completing this assignment, I can:

1. Create PostgreSQL audit logs.
2. Use triggers to automatically record database changes.
3. Store row information as JSONB.
4. Build self-referencing database tables.
5. Use recursive CTEs to process hierarchical data.
6. Organize database changes using Flyway migrations.
7. Create PostgreSQL roles and users.
8. Apply the principle of least privilege.
9. Grant different database permissions to different users.

---

# Conclusion

This assignment demonstrates practical PostgreSQL database administration and development techniques. Audit triggers provide change tracking, recursive CTEs support hierarchical data, Flyway provides controlled schema versioning, and database roles help protect data through least-privilege access control.

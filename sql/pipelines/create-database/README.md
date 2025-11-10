# Pipeline to Automate SQL Script Execution in PostgreSQL

This Python script automates the execution of SQL files to create databases, schemas, and tables in PostgreSQL. It's especially useful for quickly setting up the **reminicence** database environment for the music management system.

## Requirements

* Python 3.6 or higher
* `psycopg2` library for PostgreSQL connection

## Installation

1. Make sure you have Python installed on your system.
2. Install the dependencies:

```bash
pip install psycopg2-binary
```

## File Structure

The script automatically searches for the following SQL files:

1. `01-create-database.sql` – Creates the user, database, and schema
2. `02-create-tables.sql` – Creates the system tables

The files should be in the directory specified by `--sql-dir` or, if omitted, will be automatically searched in the project structure (for example, `sql/ddl`).

---

## 🔄 Two-Step Execution

### 1️⃣ Step 1: Create the database and schema (as `postgres`)

To run your script, navigate to the path where you have the script:

```bash
cd C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\pipelines\create-database
```

Activate your virtual environment:

```bash
.\venv\Scripts\activate
```

Then execute the first step:

```bash
python sql_pipeline_auto.py --user postgres --password "Ariamo0612" --db-name postgres --sql-dir "C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl" --use-sql-for-db-creation
```

**Console Output**

```shell
(env) PS C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\pipelines\create-database> python sql_pipeline_auto.py --user postgres --password "Ariamo0612" --db-name postgres --sql-dir "C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl" --use-sql-for-db-creation
2025-11-01 19:26:39,394 - sql_pipeline - INFO - Connecting to PostgreSQL at localhost:5432 with user postgres
2025-11-01 19:26:39,394 - sql_pipeline - INFO - Using database: postgres, schema: reminicence_schema
2025-11-01 19:26:39,394 - sql_pipeline - INFO - SQL directory: C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl
2025-11-01 19:26:39,394 - sql_pipeline - INFO - Using SQL directory: C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl
2025-11-01 19:26:39,451 - sql_pipeline - INFO - Connected to PostgreSQL
2025-11-01 19:26:39,451 - sql_pipeline - INFO - Executing database creation script: C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl\01-create-database.sql
2025-11-01 19:26:39,451 - sql_pipeline - INFO - Executing SQL statement 1 of 6
2025-11-01 19:26:39,468 - sql_pipeline - INFO - Executing SQL statement 2 of 6
2025-11-01 19:26:39,765 - sql_pipeline - INFO - Executing SQL statement 3 of 6
2025-11-01 19:26:39,766 - sql_pipeline - INFO - Executing SQL statement 4 of 6
2025-11-01 19:26:39,770 - sql_pipeline - INFO - Executing SQL statement 5 of 6
2025-11-01 19:26:39,774 - sql_pipeline - INFO - Executing SQL statement 6 of 6
2025-11-01 19:26:39,780 - sql_pipeline - INFO - Successfully executed SQL file: C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl\01-create-database.sql
2025-11-01 19:26:39,780 - sql_pipeline - INFO - Database created!
```

After this step, the following components are created:

* **User:** `music_admin`
* **Database:** `reminicence`
* **Schema:** `reminicence_schema`

You can verify this in SQL Shell:

```bash
psql -U music_admin -d reminicence -p 5432
```

And check with:

```sql
SELECT 'role' AS type, rolname AS name
FROM pg_roles
WHERE rolname = 'music_admin'
UNION ALL
SELECT 'database' AS type, datname AS name
FROM pg_database
WHERE datname = 'reminicence'
UNION ALL
SELECT 'schema' AS type, schema_name AS name
FROM information_schema.schemata
WHERE schema_name = 'reminicence_schema';
```

---

### 2️⃣ Step 2: Create tables and load data (as `music_admin`)

Once the database exists, execute the second step with the new user:

```bash
python sql_pipeline_auto.py --user music_admin --password "Reminicence2025" --db-name reminicence --sql-dir "C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl"
```

**Console Output**

```shell
(env) PS C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\pipelines\create-database> python sql_pipeline_auto.py --user music_admin --password "Reminicence2025" --db-name reminicence --sql-dir "C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl"
2025-11-01 19:26:42,163 - sql_pipeline - INFO - Connecting to PostgreSQL at localhost:5432 with user music_admin
2025-11-01 19:26:42,163 - sql_pipeline - INFO - Using database: reminicence, schema: reminicence_schema
2025-11-01 19:26:42,163 - sql_pipeline - INFO - SQL directory: C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl
2025-11-01 19:26:42,163 - sql_pipeline - INFO - Using SQL directory: C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl
2025-11-01 19:26:42,244 - sql_pipeline - INFO - Connected to PostgreSQL - reminicence
2025-11-01 19:26:42,250 - sql_pipeline - INFO - Schema 'reminicence_schema' created successfully
2025-11-01 19:26:42,250 - sql_pipeline - INFO - Executing C:\DOP_Django\Reminicence\Bd-PosgrestSQL-Reminicence\sql\ddl\02-create-tables.sql
2025-11-01 19:26:42,261 - sql_pipeline - INFO - Executing SQL statement 1 of 72
2025-11-01 19:26:42,289 - sql_pipeline - INFO - Executing SQL statement 2 of 72
...
2025-11-01 19:26:42,548 - sql_pipeline - INFO - Executing SQL statement 67 of 72
2025-11-01 19:26:42,550 - sql_pipeline - INFO - Executing SQL statement 68 of 72
2025-11-01 19:26:42,551 - sql_pipeline - INFO - Executing remaining statements...
```

After successful execution, connect again to verify that the tables were created:

```bash
psql -U music_admin -d reminicence -p 5432
```

Then run:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'reminicence_schema';
```

✅ **Expected Output (example)**

```shell
    table_schema      |      table_name
----------------------+-------------------------
reminicence_schema    | playlists
reminicence_schema    | users
reminicence_schema    | artists
reminicence_schema    | albums
reminicence_schema    | songs
reminicence_schema    | playback_history
reminicence_schema    | devices
reminicence_schema    | user_device
reminicence_schema    | playlist_songs
reminicence_schema    | genres
reminicence_schema    | song_genres
reminicence_schema    | audit_log
(12 rows)
```

---

## Available Options

* `--host`: PostgreSQL host (default: localhost)
* `--port`: PostgreSQL port (default: 5432)
* `--user`: PostgreSQL user (required)
* `--password`: User password (required)
* `--db-name`: Database to use or create (default: reminicence)
* `--schema-name`: Schema to create or use (default: reminicence_schema)
* `--sql-dir`: Path where SQL files are located (default: automatic search)
* `--use-sql-for-db-creation`: Executes the `01-create-database.sql` file as part of the process

---

## Important Notes

* **Don't execute both steps with the same user** — the first step requires administrative privileges (`postgres`) and the second must use the new user (`music_admin`).
* If `01-create-database.sql` doesn't exist, the script can create the database and schema directly from code.
* For greater security, use **environment variables** to handle credentials safely.


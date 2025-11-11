# APEX World 2025

This branch contains the (updated) source code initially delivered at APEX World 2025 in March in Ede.

## Version history

| Date | Change |
| -- | -- |
| 250321 | initial version for APEX World |
| 251111 | updated for DOAG 2025 |

## Overview

The presentation is mainly demo-driven and consists of 3 parts:

1. Using APEX Gen AI Services to crete a table that will be used in subsequent examples
1. Create sample data using [fakerjs](https://fakerjs.dev/) ([GitHub](https://github.com/faker-js/faker))
1. Load [validator.js](https://github.com/validatorjs/validator.js) into the database and use it to validate a page item

## APEX Gen AI Services

The following prompts have been tested/used to generate the table:

- "create and run script table via APEX"
- "create data model with AI"
- "please create a table for emailing with json column"
- "please create a table for emailing with json column with 10 example data"
- "please create a table for emailing with json column with 10 example data including always email <person x>
- "create email table json column incl 10 example data"

Resulting table DDL can be found in `src/database`. It was created before the introduction of SQLcl projects.

At the end of this demo step the application should have been created.

## Sample Data Creation

Sample data can be generated using on faker-js. Source code can be found in `src/database/sampleData.ts`. It features many nice things about developing MLE in Typescript:

- linting (via [Biome](https://biomejs.dev/))
- formatting (also via [Biome](https://biomejs.dev/))
- type checking (with a nod to [Typescript](https://www.typescriptlang.org/))

Deploy the code via `npm run <target>` where target is either production or development. See [utils/deploy.sh](./utils/deploy.sh) for details. Requires the availability of named connections:

- emily_development
- emily_production

Ideally you connect to separate PDBs in your Oracle AI Database Free instance. Connect to the `CDB$ROOT` as SYSDBA and run the following commands:

```sql
alter session set db_create_file_dest = '/opt/oracle/oradata';
create pluggable database prodpdb from freepdb1;
alter pluggable database prodpdb open;
alter pluggable database prodpdb save state;

alter session set container = freepdb1;

grant db_developer_role to emily identified by development;
alter user emily quota 100m on users;

alter session set container = prodpdb;

grant db_developer_role to emily identified by production;
alter user emily quota 100m on users;

exit;
```

Create the aforementioned named connections next.

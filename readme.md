# Conference talks

This repository contains code I used during my various conference talks since 10/2024. Please let me know if you have questions or comments.

The easiest way to do so is by creating an issue, citing the branch.

## AskTOM Office Hours September 2026

This little project accompanies an [AskTOM Office Hours](https://asktom.oracle.com/ords/r/tech/catalog/session-landing-page?p2_event_id=112094547914581836676988226076716758975&p2_source_log=QR) session from September 2026 where Chris Saxon and Martin Bach discussed which language might suit you well for backend development.

## Code overview

The sample implements a small action-item service inside Oracle AI Database. Its main purpose is to compare database-resident JavaScript, using Multilingual Engine (MLE), with PL/SQL for the same backend tasks: validating JSON, reading and changing relational data, producing JSON responses, and handling errors.

The exported ORDS module is available below `/ords/emily/js`. It uses a SQL collection handler for listing action items and MLE JavaScript handlers for creating, retrieving, updating, and deleting individual items. A parallel PL/SQL package is included for a side-by-side implementation comparison; it is not called by the exported `js` ORDS module.

### Repository layout

| Path | Purpose |
| --- | --- |
| `.github` | CI Pipeline to be run with git push operations |
| `src/database/` | SQLcl project exports for the application |
| `dist` | Deployable part for the application |
| `api/openapi-catalog.json` | OpenAPI description of the ORDS module |
| `tests/action-item.api.test.js` | Vitest integration tests that call a running ORDS endpoint |
| `compose.yml` | Local Oracle AI Database Free and ORDS containers for lab use |

### Data model

The API works with action items and their assigned staff:

- `staff` stores the available people.
- `action_items` stores an action name and an `OPEN` or `COMPLETE` status.
- `action_item_team_members` associates staff with action items using the roles `LEAD` and `MEMBER`. Deleting an action item cascades to its team assignments.

The REST representation combines these rows into one JSON document:

```json
{
    "actionId": 42,
    "actionName": "Prepare the conference demonstration",
    "status": "OPEN",
    "team": [
        {
            "assignmentId": 101,
            "role": "LEAD",
            "staffId": 1,
            "staffName": "Avery Johnson"
        }
    ]
}
```

Create and update requests are checked against JSON Schemas. They reject unknown properties, require at least one team member and exactly one `LEAD`, and constrain the accepted status and role values. Updates additionally require the existing `actionId` and each team member's `assignmentId`.

### REST API

The default local base URL is `http://localhost:8080/ords/emily/js`.

| Method | Path | Implementation | Result |
| --- | --- | --- | --- |
| `GET` | `/actionItem/` | ORDS SQL collection handler | Lists action items; accepts an optional `search` query parameter |
| `POST` | `/actionItem/` | MLE JavaScript | Validates and creates an action item and its team |
| `GET` | `/actionItem/{id}` | MLE JavaScript | Returns one action item, `400` for a non-numeric ID, or `404` when absent |
| `PUT` | `/actionItem/{id}` | MLE JavaScript | Validates and updates an action item and its assignments |
| `DELETE` | `/actionItem/{id}` | MLE JavaScript |\ Deletes an action item and returns `204`, or `404` when absent |

The MLE handlers receive ORDS `req` and `resp` objects. They use the implicit database `session` to execute bind-aware SQL and `plsffi` to invoke `DBMS_JSON_SCHEMA` for request validation. Inserts use identity-column `RETURNING` values and `executeMany()` for team assignments; updates transform the submitted team array with `JSON_TABLE` and merge it into the assignment table.

The PL/SQL implementation follows the same overall CRUD flow with native `JSON`, SQL/JSON generation, `JSON_TABLE`, `DBMS_JSON_SCHEMA`, and `MERGE`. Keeping both implementations close together makes it possible to compare the language syntax against one data model and closely corresponding validation rules.

### Integration tests

The Vitest suite exercises the live REST API, including successful CRUD requests and invalid payload or identifier cases. It is an integration suite rather than a mocked unit test: the schema and ORDS definitions must already be deployed, the service must contain the expected seed data, and ORDS must be reachable.

Node.js 24 LTS is required. By default the tests use the local base URL above; set `ORDS_BASE_URL` to target another deployed environment.

```bash
npm ci
npm test
```

## Installation

This repository uses SQLcl Projects to deploy the entire application end-to-end. In order to get a working environment you need an Oracle AI Database 26ai instance such as [Oracle Free](https://www.oracle.com/database/free/) with [ORDS](https://www.oracle.com/ords/) installed. If you like, you can use the provided `compose.xml` file to bring up a database with ORDS on your local development environment. Both `podman-compose` and `docker-compose` can be used.

Before you can bring the stack up, create an `.env` file in the current directory by copying `.env_sample` and changing the passwords. Then bring the stack up (if you use podman, replace `docker-compose` with `podman-compose`)

```sh
docker compose up
```

This will take a minute to pull the images, start the database and install ORDS. During initialisation the database will create a user named `emily` you can use to deploy against.

Once the environment is in place, get SQLcl 26.2.2 and deply the application:

```
$ sql emily@localhost/freepdb1

...

project gen-artifact

project deploy -file <path to previously created artifact>
```

## Todo

The code in this repository is complete, but lacks polish. The ORDS endpoint isn't secured - neither TLS nor OAuth2 are implemented. Any production deployment certainly should address this. Error handling could and should also be improved.

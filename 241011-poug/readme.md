# POUG 2024

This talk is concerned with **Advanced JavaScript in Oracle Database 23ai.**

The presentation contains 3 demos:

1. Showing [Multilingual Engine](https://docs.oracle.com/en/database/oracle/oracle-database/23/mlejs/index.html) (MLE) modules and Environments in action
1. [APEX](https://apex.oracle.com) and MLE/JavaScript
1. JavaScript handlers for [Oracle REST Data Services](https://www.oracle.com/ords/) (ORDS)

You can find the code for each part in the relevant sub-directory.

The code was developed with, and tested against an _Always Free_ Oracle Autonomous Database-Serverless Version 23.6.0.24.07, APEX 24.1.0 instance. The instant client, release 23ai, is also needed to work with the Simple Oracle Document Access no-SQL API.

The examples work with a local Oracle Database 23ai Free as well, testing was performed against Oracle Database 23ai Free (23.5.0.24.07) and APEX 24.1.0. In that combination, you do not need the thick client.

## Introduction

[`introduction.sql`](./introduction.sql) demonstrates how to create a new account suitable for developing server-side JavaScript applications. A few additional examples, to be executed either in `sqlcl` or SQLDeveloper Next, provide a couple of use cases including:

- inline functions
- creation of call specifications in standalone functions and PL/SQL packages

> More details about [sqlcl](https://www.oracle.com/sqlcl) can be found with its [official documentation](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/index.html).

All subsequent code exmaples depend on the `EMILY` account and the utilities module to have been created. The EMILY account will be used later in the APEX example. You should create an APEX workspace based on the `EMILY` schema piror to starting the 2nd example.

## MLE Modules

A set of scripts, driven by `SQLcl` and Liquibase demonstrate how to use MLE modules in the database. Code deployment requires an active `SQLcl` connection to the database. Once the connection has been established, change into `01_mle_modules` and start the Liquibase deployment as follows:

```
cd 01_mle_modules
lb tag -tag poug-1
lb update -log -debug -changelog-file controller.xml
```

The code provided in `business_logic.js` is deployed as `DEMO_THINGS_MODULE`. It provides the core functionality of the application and will be reused as much as possible. The business logic is ported from PL/SQL to JavaScript from [Steve Muench's blog](https://diveintoapex.com/2024/03/05/simplify-apex-app-rest-apis-with-json-duality-views/). It's a great read, please head over there for background and motivation to this application.

Unit testing is an important aspect of development with JavaScript code. The project provides a couple of _test_ commands invoking _vitest_-driven Unit Tests. Ensure you configure the database connection using the following format in `./tools/dbConfig.js` (referenced in `./tools/api.js`). You need to created the file.

If you want to use Autonomous Database, use this snippet as a starting point:

```JavaScript
const dbConfig = {
    autonomousDB: {
        username: "your username",
        password: "your password",
        adb: true,
        connectionString: "your net*8 connection string",
        walletLocation: "/path/to/where/you/stored/the/wallet",
        configDir: "/path/to/where/you/unzipped/the/wallet",
        walletPassword: "your wallet password",
        libDir: "/path/to/instant_client_23*"
    }
}

export default dbConfig;
```

Remember that if you would like to use an Autonomous Database 23ai - Serverless (ADB-S) instance, you need to

- download and install the BASIC instant client package for your platform and make it known to the application by providing the `libDir`.
- get the wallet from your ADB-S instance
- store the wallet in a directory of choice (for example `tns`)
- unzip the wallet in the directory where you stored it
- provide values for
    - `walletLocation`
    - `configDir` (typically matching `walletLocation`)
    - `walletPassword`
    - the `adb` flag must be set to `true`

If your connection is against an Always-Free Database running in a VM or container, you don't need to provide

- `libDir`
- `walletPassword`
- `configDir`
- `walletLocation`
- set the `adb` flag to `false`

In both cases you need to ensure the options object passed to `api.init()` contains the thick flag set to true: that's necessary to allow unit testing of the noSQL SODA interface.

<!-- TODO: remove that dependency on the thick driver -->

If you use a local Docker instance with Database 23ai Free, this is your starting point:

```JavaScript
const dbConfig = {
    docker: {
        username: "your username",
        password: "your password",
        adb: false,
        connectionString: "localhost:1521/freepdb1",
    }
}

export default dbConfig;
```

**DO NOT CHECK ./tools/dbConfig.js INTO GIT**! Avoid storing sensitive information in Git.

Next, make sure to update the `beforeAll()` hook in `01_mle_modules/test/database.test.js`. It's possible to define multiple environments in `dbConfig.js` depending on what you'd like to test against. If you'd like to test against your Internet-faciing Autonomous Database, you could use a call similar to this:

```JavaScript
    describe("unit testing using vitest", () => {
        // initialise the connection to the database for all unit tests
        beforeAll(async () => {
            const options = {
                // used in combination with dbConfig.js
                adb: true,
                pool: false,
                env: "autonomousDB",
                thick: true
        };

        await api.init(options);
    });
```

The equivalent for a local containerised environment is shown here

```JavaScript
    describe("unit testing using vitest", () => {
        // initialise the connection to the database for all unit tests
        beforeAll(async () => {
            const options = {
                // used in combination with dbConfig.js
                adb: false,
                pool: false,
                env: "docker",
                thick: false
        };

        await api.init(options);
    });
```

## APEX and MLE

Before you can run this example you need to create an APEX (24.1 or later) workspace based on the existing `EMILY` schema. Rather than doing that manually, a little bit of code does it. Connect as `SYSTEM` to freepdb1 and run `setup.sql`

Once the workspace is created, switch back to the `EMILY` user session and import the APEX app into the new workspace:

```
cd ~/devel/javascript/conference-talks/241011-poug/02_apex_and_mle 
lb update -changelog-file apex_install.xml -override-app-workspace POUG_WS
```

Run the application and experiment with it.

Page 3 allows you to create/edit _things_. Using the code provided in the previous example it is possible to seamlessly process page items using JavaScript.

## ORDS Handlers

Beginning with ORDS 24.x it is possible to define [REST APIs using JavaScript handlers](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/24.2/orddg/developing-REST-applications.html#GUID-F1EFB0B5-E020-45CB-A176-8C8F045074CC), powered by MLE. The example code creates GET, POST, PUT, and DELETE handlers against the THINGS Duality View (created in example 01), allowing external applications to work with the data. The ORDS handlers use a no-SQL API to interact with the data. The same code used previously with the APEX app is referred to by the ORDS handlers.

It is assumed that ORDS is available, and configured. It should be, given that you used APEX in example 02 :) You also ORDS-enabled `EMILY`'s schema in `introduction.sql`.

Follow these steps to deploy the ORDS handlers to the `EMILY` account:

- change directory to `03_ords_handlers`
- Create a tag for Liquibase (`lb tag -poug-3`)
- Deploy the handlers (`lb update -changelog-file controller.xml`)

ORDS handlers can be tested using the provided unit tests in `03_ords_handlers/ords.tests.js`. The unit tests use the `fetch()` API extensively to

- insert a new document into the JSON Relational Duality View
- query the document back
- perform validations
- update the document
- delete the document

Create a dotenv file `.env.local` in `241011-poug` with following content to indicate the REST endpoint:

```sh
VITE_ORDS_URL=<URI>
```

The value of the URI depends on your target:

| Autonomous Database | Local Deployment |
| -- | -- |
| `https://<your autonomous DB>.oraclecloudapps.com/ords/emily/api` | `https://localhost:8181/ords/emily/api` |

Now you're ready to execute the unit tests using `npm run test02`. You should see the following output:

```
$ npx vitest run 03_ords_handlers/ords.test.js

 RUN  v2.0.5 /Users/martin.b.bach/devel/javascript/conference-talks/241011-poug

 ✓ 03_ords_handlers/ords.test.js (7) 1377ms
   ✓ testing ORDS handlers using the fetch() API (7) 1377ms
     ✓ ensure the ORDS endpoint (URL) is a valid URL
     ✓ POST to the JSON Relational Duality View 368ms
     ✓ GET the inserted document from the JSON Relational Duality View 373ms
     ✓ validate the price has been rounded to the nearest 99 cent
     ✓ ensure multiple entries for stock are consolildated in the same warehouse
     ✓ update the document using a PUT call against the JSON Relational Duality View
     ✓ DELETE the document from the JSON Relational Duality View

 Test Files  1 passed (1)
      Tests  7 passed (7)
   Start at  11:16:45
   Duration  1.63s (transform 37ms, setup 0ms, collect 45ms, tests 1.38s, environment 0ms, prepare 54ms)
```

In case of errors related to self-signed certificates when testing your local build, `export NODE_TLS_REJECT_UNAUTHORIZED=0` to accept these.

Happy coding!

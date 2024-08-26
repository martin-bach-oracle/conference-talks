# POUG 2024

This talk is concerned with **Advanced JavaScript in Oracle Database 23ai.**

The presentation contains 3 demos:

1. Showing [Multilingual Engine](https://docs.oracle.com/en/database/oracle/oracle-database/23/mlejs/index.html) (MLE) modules and Environments in action
1. [APEX](https://apex.oracle.com) and MLE/JavaScript
1. JavaScript handlers for [Oracle REST Data Services](https://www.oracle.com/ords/) (ORDS)

You can find the code for each part in the relevant sub-directory.

The code was developed with, and tested against an _Always Free_ Oracle Autonomous Database-Serverless Version 23.6.0.24.07, APEX 24.1.0 instance. The instant client, release 23ai, is also needed to work with the Simple Oracle Document Access no-SQL API.

## Introduction

[`introduction.sql`](./introduction.sql) demonstrates how to create a new account suitable for developing server-side JavaScript applications. A few additional examples, to be executed either in `sqlcl` or SQLDeveloper Next, provide a couple of use cases including

- inline functions
- creation of call specifications in standalone functions and PL/SQL packages

All subsequent code exmaples depend on the `EMILY` account and the utilities module to have been created. The EMILY account will be used later in the APEX example. You should create an APEX workspace based on the `EMILY` schema piror to starting the 2nd example.

## MLE Modules

A set of scripts, driven by `SQLcl` and Liquibase demonstrate how to use MLE modules in the database. Code deployment requires an active `SQLcl` connection. Then change into `01_mle_modules` and start the Liquibase deployment

```
cd 01_mle_modules
lb update -log -debug -changelog-file controller.xml
```

The code provided in `business_logic.js` is deployed as `DEMO_THINGS_MODULE`. It provides the core functionality of the application and will be reused as much as possible.

Unit testing is an important aspect of development with JavaScript code. The project provides a _test_ command invoking _vitest_-driven Unit Tests. Ensure you configure the database connection using the following format in `./tools/dbConfig.js` (referenced in `./tools/api.js`)

```JavaScript
const dbConfig = {
    environmentName: {
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

**DO NOT CHECK THIS FILE INTO GIT**!

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

If you would like to use an Autonomous Database 23ai - Serverless (ADB-S) instance, you need to

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

## APEX and MLE

Before you can run this example you need to create an APEX (24.1 or later) workspace based on the existing `EMILY` schema.

`sqlcl` is once more used to deploy code, this time it's an APEX application that will be deployed against the `EMILY` schema. Page 3 allows you to create/edit things. Using the code provided in the previous example it is possible to seamlessly process page items using JavaScript.

## ORDS Handlers

Beginning with ORDS 24.x it is possible to define REST APIs using JavaScript handlers. The example code creates GET, POST, PUT, and DELETE handlers against the THINGS Duality View (created in step 01), allowing external applications to work with the data. The ORDS handlers use a no-SQL API to interact with the data. The same code used previously with the APEX app is referred to by the ORDS handlers.

It is assumed that ORDS is available, and configured.

_This is work in progress_. Follow these steps to deploy the ORDS handlers against the `EMILY` account:

- ensure `EMILY`'s account is REST-enabled by calling `ords.enable_schema`
- create a new MLE module `ords_handler_impl_module` using the code found in `ords_handler_impl.js`
- run `ords_handler_aux.sql`
- execute `ords_handler.sql`

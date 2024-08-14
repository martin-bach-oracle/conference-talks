import oracledb from 'oracledb';
import dbConfig from './dbConfig.js'

// ------------------------------------------------------------------------------------ constants
const POOL_NAME = 'mle';            // used for oracledb.getPool() and createPool()

// ------------------------------------------------------------------------------------ code

/**
 * Check if the code runs on the client (node, deno, bun, browser), 
 * or server-side like in MLE. Client in this context === everything
 * that doesn't run directly inside the database
 * @returns {boolean} true if runtime = client, false if MLE
 */
function isClientRuntime() {

    let isClient = false;

    if (
        globalThis.process.release.name === 'node' ||
        globalThis.Bun ||
        globalThis.Deno ||
        typeof Window === 'function'
    ) {
        isClient = true;
    }

    return isClient;
}

/**
 * Add a database connection to the global `this` allowing the use of the
 * simplified MLE syntax.
 * @param {Connection} connection - the Oracle database connection to add to global this
 */
async function addToGlobalThis(connection) {
    
    Object.defineProperty(
        globalThis,
        'session',
        {
            value: connection,
            enumerable: false,
            configurable: false,
            writable: false
        }
    );

    Object.defineProperty(
        globalThis,
        'oracledb',
        {
            value: oracledb,
            enumerable: false,
            configurable: false,
            writable: false
        }
    );
} 

/**
 * Initialise database connections. 
 * 
 * @param {object} options - connection properties ({env: test, pool: false, adb: true})
 */
export async function init(options) {

    // defaults
    let localOptions = {
        env: "test",
        adb: false,
        pool: false
    }

    // override defaults
    if (options !== undefined) {
        localOptions.adb = options.adb !== undefined ? options.adb : false;
        localOptions.pool = options.pool !== undefined ? options.pool : false;
        localOptions.env = options.env !== undefined ? options.env : false;
    }

    // is the code running inside the database using MLE or on the client?
    // no need to deal with MLE, it has a built-in session object.
    if (isClientRuntime()) {

        let oracleDBptions = {
            user:             dbConfig[localOptions.env].username,
            password:         dbConfig[localOptions.env].password,
            connectionString: dbConfig[localOptions.env].connectionString
        };

        if (localOptions.adb) {
            oracleDBptions.configDir      = dbConfig[localOptions.env].configDir;
            oracleDBptions.walletLocation = dbConfig[localOptions.env].walletLocation;
            oracleDBptions.walletPassword = dbConfig[localOptions.env].walletPassword;
        }

        let connection;

        if (localOptions.pool) {

            // create/start the database connection pool if needed
            oracleDBptions.poolAlias = POOL_NAME;

            // there is no need to start _another_ connection pool
            // if one exists already.
            try {

                oracledb.getPool(oracleDBptions.poolAlias);
            } catch(err) {

                // pool does not exist, let's create it
                await oracledb.createPool(oracleDBptions);
            }

            connection = await oracledb.getConnection();
        } else {

            // "just" a database session
            connection = await oracledb.getConnection(oracleDBptions);
        }

        if (connection === undefined || connection === null) {
            throw new Error('a database connection could not be established');
        }

        await addToGlobalThis(connection);
    }
}

/**
 * close the session and/or connection pool. Nothing to do in an MLE environment.
 */
export async function tearDown() {

    if (isClientRuntime()) {
        
        try {

            await oracledb.getPool(POOL_NAME).close(10);

        } catch(err) {

            // no such pool defined, closing the session
            session.close();
        }
    }
}
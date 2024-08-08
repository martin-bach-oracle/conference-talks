import oracledb from 'oracledb';

/**
 * run as follows: `node --env-file .env 01_mle_modules/testing.js`
 */

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
 * @param {object} connectionOptions - connection properties ({ pool: true|false, adb: true|false})
 */
export async function init(connectionOptions) {

    // is the code running inside the database using MLE or on the client?
    if (isClientRuntime()) {

        if (connectionOptions === undefined) {
            connectionOptions = {
                adb: false,
                pool: false
            };
        }

        let options = {
            user: process.env.username,
            password: process.env.password,
            connectionString: process.env.connectionString
        };

        if (connectionOptions.adb) {
            options.configDir = process.env.configDir;
            options.walletLocation = process.env.walletLocation;
            options.walletPassword = process.env.walletPassword;
        }

        let connection;

        if (connectionOptions.pool) {

            options.poolAlias = POOL_NAME;

            // test if the pool exists
            try {

                oracledb.getPool(options.poolAlias);
            } catch(err) {

                // pool does not exist, let's create it
                await oracledb.createPool(options);
            }

            connection = await oracledb.getConnection();
        } else {

            // most likely server-side code (aka "MLE")
            connection = await oracledb.getConnection(options);
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
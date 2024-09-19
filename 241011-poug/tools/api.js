import oracledb from "oracledb";
import dbConfig from "./dbConfig.js";
import * as utils from "./utils.js";

// ------------------------------------------------------------------------------------ constants
const POOL_NAME = "mle"; // used for oracledb.getPool() and createPool()

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
		globalThis.process.release.name === "node" ||
		globalThis.Bun ||
		globalThis.Deno ||
		typeof Window === "function"
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
	Object.defineProperty(globalThis, "session", {
		value: connection,
		enumerable: false,
		configurable: false,
		writable: false,
	});

	Object.defineProperty(globalThis, "oracledb", {
		value: oracledb,
		enumerable: false,
		configurable: false,
		writable: false,
	});
}

/**
 * Initialise database connections.
 *
 * @param {object} options - connection properties (env name, create a pool, use thick mode)
 */
export async function init(options) {
	const defaults = {
		env: "test",
		pool: false,
		thick: false,
	};

	// biome-ignore lint: merging options to ensure subsequent code doesn't suffer runtime errors
	options = utils.mergeOptions(defaults, options);

	// is the code running inside the database using MLE or on the client?
	// no need to deal with MLE, it has a built-in session object.
	if (isClientRuntime()) {
		// prepare the options object to be passed to oracledb.getConnection()
		const oracleDBptions = {
			user: dbConfig[options.env].username,
			password: dbConfig[options.env].password,
			connectionString: dbConfig[options.env].connectionString,
		};

		if (dbConfig[options.env].adb) {
			oracleDBptions.configDir = dbConfig[options.env].configDir;
			oracleDBptions.walletLocation = dbConfig[options.env].walletLocation;
			oracleDBptions.walletPassword = dbConfig[options.env].walletPassword;
		}

		let connection;
		let clientOpts = {};

		if (options.thick) {
			if (process.platform === "win32" || process.platform === "darwin") {
				clientOpts = {
					libDir: dbConfig[options.env].libDir,
					configDir: dbConfig[options.env].configDir
				};
			}

			oracledb.initOracleClient(clientOpts); // enable node-oracledb Thick mode
		}

		if (options.pool) {
			// there is no need to start _another_ connection pool if one exists already.
			// this application's pool is identified by POOL_NAME
			try {
				// poolAlias will be used later as an option to createPool()
				oracleDBptions.poolAlias = POOL_NAME;
				oracledb.getPool(oracleDBptions.poolAlias);
			} catch (err) {
				// pool does not exist, let's create it
				await oracledb.createPool(oracleDBptions);
			}

			connection = await oracledb.getConnection();
		} else {
			// let's create "just" a database session without a pool
			connection = await oracledb.getConnection(oracleDBptions);
		}

		// if (connection === undefined || connection === null) {
		// 	throw new Error("a database connection could not be established");
		// }

		// by adding session, soda and oracledb to the global scope it is possible
		// to use the same code logic for client- and server-side JavaScript code.
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
		} catch (err) {
			// no such pool defined, closing the session
			session.close();
		}
	}
}

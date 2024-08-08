import * as api from '../tools/api.js';

/**
 * run as follows: `node --env-file .env 01_mle_modules/testing.js`
 */

const options = {                // used in combination with .env file 
    adb: true,
    pool: false
};

await api.init(options);

const result = await session.execute('select user', [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
console.log(`username: ${result.rows[0].USER}`);

await api.tearDown();
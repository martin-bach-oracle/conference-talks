
/**
 * Merge function's options with the defaults. To be used with node exclusively,
 * the function is part of the introduction.sql file.
 * 
 * @param {object} opts - options passed to the function
 * @param {object} defaults - the default options
 * @returns {object} merged options
 */
export function mergeOptions( defaults, opts = {}) {
    for (const key in defaults) {
        if (typeof opts.key === 'undefined') {
            opts.key = defaults.key;
        }
    }

    return opts;
}
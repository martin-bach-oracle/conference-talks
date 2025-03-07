
/**
 * Merge function's options with the defaults. To be used with node exclusively,
 * the function is part of the introduction.sql file.
 * 
 * @param {object} opts - options passed to the function
 * @param {object} defaults - the default options
 * @returns {object} merged options
 */
export function mergeOptions( defaults, options = {}) {
    for (const key in defaults) {
        if (typeof options[key] === 'undefined') {
            options[key] = defaults[key];
        }
      }
      return options;
}
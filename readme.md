# APEX World 2025

This branch contains the source code for the APEX World presentation.

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
- "please create a table for emailing with json column with 10 example data including always email <sonja.meyer@oracle.com>"
- "create email table json column incl 10 example data"

Resulting table DDL can be found in `src/database`.

At the end of this demo step the application should have been created.

## Sample Data Creation

Sample data can be generated using on faker-js. Source code can be found in `src/database/sampleData.ts`. It features many nice things about developing MLE in Typescript:

- linting (via [Biome](https://biomejs.dev/))
- formatting (also via [Biome](https://biomejs.dev/))
- type checking (with a nod to [Typescript](https://www.typescriptlang.org/))

Deploy the code via `npm run deploy`. See [utils/deploy.sh](./utils/deploy.sh) for details.

## Page Item Validation

Create a custom JavaScript module in APEX page designer:

```javascript

export function validateMetadata() {
    
}

# AGENTS.md

Top-level instructions for this project

<!-- inspired by https://github.com/Azure-Samples/serverless-recipes-javascript/tree/main -->

## Key Technologies and Frameworks

- **Runtime**: Node.js (>=20)
- **Database**: Oracle AI Database 26ai Free, Oracle REST Data Services 25.4.0 or later
- **Protocols**: Model Context Protocol (MCP) for AI tool integration
- **API documentation**: OpenAPI/Swagger specifications
- **Infrastructure**: Container images spun up by docker compose or GitHub Actions
- **Development**: GitHub, VS Code, GitHub Actions workflows

## Constraints and Requirements

- **Node.js version**: Minimum v24 LTS required for all samples
- **JavaScript**: use ECMAScript modules exclusively, add JSDoc for each function you create/change
- **Oracle Database**: Minimum Oracle AI Database 26ai 23.26.1.0
- **Oracle REST Data Services**: Minimum release 25.4.0
- **CI/CD**: based on SQLcl projects workflow

## Coding Guidelines

- **Language**: JavaScript and PL/SQL where appropriate, ECMAScript-only
- **Code style**: biome configuration as stored in the project's root directory
- **File structure**: governed by SQLcl's project export and stage commands: `src/database` and `dist`, respectively
- **Configuration**: Environment variables in `.env` for local development
- **Error handling**: Proper HTTP status codes and error messages in API responses

## Pull Request Guidelines

- **Build status**: All CI/CD checks must pass (build, lint, test across Node.js v24)
- **Documentation**: Update main README.md samples list if adding new samples
- **Testing**: Ensure `npm test`

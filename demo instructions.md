# Ohne Git kein DevOps, ohne DevOps keine moderne Softwareentwicklung

This hands-on tutorial, presented at the German Oracle User Group (DOAG) Conference in November 2025, demonstrates how to integrate Git with Oracle Database development workflows. The session recording and slides are available in the [conference agenda](https://meine.doag.org/events/anwenderkonferenz/2025/agenda/#agendaId.6588).

> [!IMPORTANT]
> To follow this tutorial, clone the repository and check out tag `251118_doag_git_start`:
> ```bash
> git clone <repository-url>
> git checkout 251118_doag_git_start
> ```

## Database Setup

Before starting, you need an [Oracle Database 23ai](https://www.oracle.com/database/free/) instance. Choose one of these options:

- [ ] [Always Free Autonomous Database (Serverless)](https://www.oracle.com/cloud/free/) in Oracle Cloud Infrastructure
- [ ] Local database installation (preferably containerised, running in podman or docker)
- [ ] Use the [development VM](https://www.oracle.com/database/free/)

Each of these options is well [documented online](https://www.oracle.com/database/free/).

This tutorial assumes a local database instance listening on port 1521 (default Oracle Net Listener port). You'll need two pluggable databases:

- freepdb1 (provided out of the box by the container image)
- prodpdb (to be created)

To create these accounts and configure the necessary connections:

1. Install [SQLcl](https://www.oracle.com/sqlcl) - the command-line interface for Oracle Database
2. Review and modify `setup/init.sql` according to your environment
3. Run `setup/init.sql` as a privileged user (SYSDBA)

You also need utPLSQL installed in FREEPDB1, instructions how to do so can be found on the [project's website](https://www.utplsql.org/utPLSQL/latest/userguide/install.html#headless-installation).

## Example 1

The first example introduces Git basics but isn't very realistic. Still, these basic principles are necessary to understand the following example workflow.

### Create the application scaffolding

Connect to your development database and initialize the project structure:

```sql
-- Create the SQLcl project structure for database version control
project init -connection-name development -name cicd -schemas demouser
```

Configure the project settings:

```sql
-- Prevent schema name emission in DDL scripts
-- This ensures deployments work across different schemas
project config set -name export.setTransform.emitSchema -value false

-- Configure Git branch settings for this tutorial
-- Note: In real projects, you would use 'main' or 'master' as your default branch
project config set -name git.defaultBranch -value 251118_doag_git
project config set -name git.protectedBranches -value "main,master,251118_doag_git"
```

> [!NOTE]
> For this tutorial, we use `251118_doag_git` as our main branch instead of the conventional `main` or `master`. This special setup is only for demonstration purposes.

### Commit the application scaffolding

Let's commit the changes made to the repository.

> [!WARNING]
> Unless you are using Trunk-Based-Development, committing directly to main (aka `251118_doag_git`) is a no-go. It's fine for this tutorial though.

```sql
-- check the status
! git status
-- stage the files
! git add .

-- double-check if everything is as expected
! git status

-- if there are no objections, it's time to create a commit
!git commit -m 'feat: sqlcl project init'
```

Alternatively perform these operations via your favourite IDE.

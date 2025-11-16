# Ohne Git kein DevOps, ohne DevOps keine moderne Softwareentwicklung

This hands-on tutorial, presented at the German Oracle User Group (DOAG) Conference in November 2025, demonstrates how to integrate Git with Oracle Database development workflows. The session recording and slides are available in the [conference agenda](https://meine.doag.org/events/anwenderkonferenz/2025/agenda/#agendaId.6588).

## Database Setup

Before starting, you need an [Oracle Database 23ai](https://www.oracle.com/database/free/) instance. Choose one of these options:

- [ ] [Always Free Autonomous Database (Serverless)](https://www.oracle.com/cloud/free/) in Oracle Cloud Infrastructure
- [ ] Local database installation (preferably containerised, running in podman or docker)
- [ ] Use the [development VM](https://www.oracle.com/database/free/)

Each of these options is well [documented online](https://www.oracle.com/database/free/).

This tutorial assumes a **local database instance** listening on port 1521 (default Oracle Net Listener port). If you don't have one, use one of the compose files located in the [JavaScript Blogposts repository](https://github.com/martin-bach-oracle/javascript-blogposts/tree/main/database). After the `{docker,podman} compose -f ... up` completes, complete these steps:

1. Install [SQLcl](https://www.oracle.com/sqlcl) - the command-line interface for Oracle Database
2. Review and modify `setup/init.sql` according to your environment
3. Run `setup/init.sql` as a privileged user (SYSDBA) connected to `CDB$ROOT`

You also need utPLSQL installed in FREEPDB1, instructions how to do so can be found on the [project's website](https://www.utplsql.org/utPLSQL/latest/userguide/install.html#headless-installation).

The repository you're browsing right now marks the reference implementation - you need to create a new repository (including on GitHub) for the demo!

```shell
[[ -d ~/devel/presentations/git-demo-doag ]] && rm -rvif ~/devel/presentations/git-demo-doag
mkdir ~/devel/presentations/git-demo-doag && cd ~/devel/presentations/git-demo-doag
git init .
```

Open a new VSCode window for this folder.

## Example 1

The first example introduces Git basics but isn't very realistic. Still, these basic principles are necessary to understand the following example workflow.

### Create the application scaffolding

Connect to your development database (`sql -name development` - the connection name is created automatically in `setup/init.sql`) and initialize the project structure:

```sql
-- Create the SQLcl project structure for database version control
project init -connection-name development -name cicd -schemas demouser

-- remove the readme
!rm README.md
```

### Commit the application scaffolding

Let's commit the changes made to the repository.

> [!WARNING]
> Unless you are using Trunk-Based-Development, committing directly to main is a no-go. It's fine for this tutorial though.

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

### Create the initial version of the application

The app maintains a list of items to be done, aka a todo list. Multiple users are supported, each user has the ability to assign priorities for a todo item, and they can categorize each item.

Our application is a multi-user todo list manager where:

- Each user has their own todo items
- Items can be organized into user-defined categories
- Each item tracks creation and target dates

Let's create the data model, starting with the users table:

```sql
-- use the stored connection created by init.sql
connect -n development

create table todo_users (
    user_id      number generated always as identity not null enable,
    username     varchar2(30 byte) not null enable,
    email        varchar2(255 byte) not null enable,
    created_date date default sysdate not null enable
);

alter table todo_users
    add constraint todo_users_pk primary key (user_id)
        using index enable;
alter table todo_users
    add constraint todo_users_username_uk unique (username)
        using index enable;
alter table todo_users
    add constraint todo_users_email_uk unique (email)
        using index enable;

create table todo_categories (
    category_id   number generated always as identity not null enable,
    user_id       number not null enable,
    category_name varchar2(50 byte) not null enable,
    created_date  date default sysdate not null enable
);

alter table todo_categories
    add constraint todo_categories_pk primary key (category_id)
        using index enable;
alter table todo_categories
    add constraint todo_categories_uk unique (user_id, category_name)
        using index enable;
alter table todo_categories
    add constraint todo_categories_fk_user foreign key (user_id)
        references todo_users(user_id) on delete cascade;

create table todo_items (
    item_id         number
        generated always as identity
    not null enable,
    user_id         number not null enable,
    category_id     number,
    title           varchar2(200 byte) not null enable,
    description     clob,
    priority        varchar2(10 byte) not null enable,
    target_date     date,
    completion_date date,
    created_date    date default sysdate not null enable
);

alter table todo_items
    add constraint todo_items_pk primary key ( item_id )
        using index enable;

alter table todo_items
    add constraint todo_items_priority_chk
        check ( priority in ( 'LOW', 'NORMAL', 'HIGH', 'low', 'normal', 'high' ) ) enable;

alter table todo_items
    add constraint todo_items_fk_category
        foreign key ( category_id )
            references todo_categories ( category_id )
                on delete set null
        enable;

alter table todo_items
    add constraint todo_items_fk_user
        foreign key ( user_id )
            references todo_users ( user_id )
                on delete cascade
        enable;
```

After the data model has been created locally it's time to export it for use with SQLcl's project command. You don't do this in MAIN, you create a new short-lived branch for that.

```sql
! git switch -c "initial_version"

project export
```

Review the status using `! git status` and if everything is fine, commit.

```sql
! git status --untracked-files=all
! git add .
! git commit -m "feat: add initial data model"
```

Maybe this is a good time to point out [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)?

### Prepare for Release 1.0.0

Now we'll stage the changes for our first release. This absolutely requires the files exported in the previous step to be committed to the repository.

First, stage the changes using `project stage`, like so:

```sql
-- Compare current branch with main and prepare deployment artifacts
-- -debug: Shows detailed progress
-- -verbose: Provides additional information about operations
project stage -debug -verbose
```

This command:

- Compares your current branch with the main branch as per the configuration
- Creates deployment scripts under the `dist/next` directory
- Requires previous changes to be committed to Git first

> [!NOTE]
> The `next` directory under `dist` is a convention in SQLcl projects, representing changes pending for the next release.

### Create version 1.0.0 of your application

With the changes staged, you can create the first release! In a real-world scenario you'd of course have unit and integration tests added at this stage, but for the sake of keeping this tutorial short, these steps have been omitted.

```sql
project release -version 1.0.0 -verbose
```

You will see the directory structure under `dist` change again, with everything that used to be under `next` moved to `1.0.0`, the release's name.

Time to commit these to git!

```sql
! git status -uall
! git add .
! git commit -m "feat: create release 1.0.0"
```

Your branch-`initial_version`-is now ready to be merged into production! Well, only in the context of this tutorial, this wouldn't be done that way in the real world. More about that in example 2.

### Merging changes into your main branch

Most projects protect the main branch, because it's their _production_ code. The code in main should always be _clean_ and _production ready_. Those who implement CI/CD to the letter are able to deploy main at the drop of the hat, thus rolling out a new version at any time.

This tutorial shows you the basic steps for merging into the main branch. You will learn more about real-world examples in a bit. Rarely do you merge into the protected branch in this way, if ever.

```sql
! git switch main
! git merge initial_version
```

You typically generate  `project gen-artifact -format zip -version 1.0.0` next, followed by an upload to your artefactory.

## Example 2

The second example takes it to the next level.

The previous example demonstrated the use of Git for a single developer. Admittedly, the scenario isn't particularly realistic, but you need to learn how to walk before you can run. Let's pick up the pace and involve a collaboration platform like GitHub.

You will need to add your own Git repository if you want to follow this tutorial.

### New ticket: add sample data

A few rows should be added to the tables. This can be done as part of the `project stage` command. For this to work reliably a small change is required: the identity columns for all tables are currently defined as `generated always...` which makes creating sample data difficult.

Before making any changes, create a new branch for the task:

```sql
-- ensure your're still on main
! git status

! git switch -c sample_data
```

Let's change the identity columns to `generated by default on null` or else it's impossible to use the insert script.

```sql
ALTER TABLE todo_categories MODIFY (category_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE todo_items MODIFY (item_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY);
ALTER TABLE todo_users MODIFY (user_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY);
```

Re-export the schema to add the changes to the Git repository.

```sql
project export
! git status -uall
! git add .
! git commit -m 'feat: change identity columns'
```

This sets the stage for the addition of the sample data, which you create next

```sql
project stage -verbose

project stage add-custom -file-name sampledata.sql
```

Now edit `dist/releases/next/changes/sample_data/_custom/sampledata.sql` and append the contents of `sampleData.sql`, making sure not to overwrite the file header.

Before moving on, let's commit those changes to the branch.

```sql
! git status -uall
! git add .
! git commit -m 'feat: finished adding sample data'
```

Once that's completed, let's merge the changes into main

```sql
! git switch main
! git merge sample_data
```

But this time let's not stop here: let's involve a remote repository. Create one in GitHub named _doag-git-dropme_. Add the remote repository

```
! git remote add origin git@github.com:martin-bach-oracle/doag-git-dropme.git
```

```sql
-- push the local branch to the remote repository
! git push -u origin main
```

Explore and review the GitHub repo.

With all the local commits pushed to the remote repository, it is safe to drop the local branches:

```sql
! git branch -va
! git branch -d initial_version
! git branch -d sample_data
```

Let's address another ticket, the addition of an API and unit tests.

```sql
! git switch -c cicd
```

Let's add some GitHub Actions involving a unit test. First, we need the unit tests, they are based on utPLSQL

```sql
create or replace package user_admin_pkg as
    procedure create_user(
        p_username todo_users.username%type,
        p_email todo_users.email%type
    );
end;
/

create or replace package body user_admin_pkg as
    procedure create_user(
        p_username todo_users.username%type,
        p_email todo_users.email%type
    ) as
    begin
        insert into todo_users (
            username,
            email
        ) values (
            p_username,
            p_email
        );
    end;
end;
/
```

Test the new functionality. If you get primary key violations something has gone wrong. It might be necessary to reset the sequences mapped to the identity columns. This _should_ have happened when the sample data was inserted.

```sql
alter table todo_categories modify
  category_id generated by default on null
  as identity (start with limit value);

alter table todo_items modify
  item_id generated by default on null
  as identity (start with limit value);

alter table todo_users modify
  user_id generated by default on null
  as identity (start with limit value);

Next, create a new user and test if it worked

declare
    l_num_users pls_integer;
begin
    user_admin_pkg.create_user('Toto', 'toto@nowhere.com');

    select
        count(*) into l_num_users
    from
        todo_users
    where
        email = 'toto@nowhere.com';
    
    if l_num_users != 1 then
        raise_application_error(-20001, 'insert apparently unsuccessful');
    end if;

    rollback;
end;
/
```

Awesome! That's the starting point for the unit test. Requires utPLSQL to be present in FREEPDB1

```sql
create or replace package test_user_admin_pkg as

    --%suite(Unit-tests covering the backend API)

    --%test(ensure new user is successfully created)
    procedure test_create_user;
end;
/

create or replace package body test_user_admin_pkg as
    procedure test_create_user as
        l_num_users pls_integer;
    begin
        user_admin_pkg.create_user('Toto', 'toto@nowhere.com');

        select
            count(*) into l_num_users
        from
            todo_users
        where
            email = 'toto@nowhere.com';
        
        ut.expect(l_num_users).to_equal(1);
    end;
end;
/
```

Now let's run the test

```sql
exec ut.run(ut_documentation_reporter(), a_color_console=>true)
```

If everything worked fine, export the schema

```sql
project export
```

As usual, stage files and commit

```sql
! git status -uall
! git add .
! git commit -m 'feat: add unit tests'
```

Time to add a CI/CD pipeline - this example uses GitHub Actions, there are many other options. Start by creating `.github/workflows`, and add a file named `cicd.yml` with the following contents:

```yaml
name: Continuous Integration and Delivery
on:
  push:
  pull_request:
  workflow_dispatch:

jobs:

  unit-tests-and-build:
    runs-on: ubuntu-latest
    services:
      oracle:
        image: gvenzl/oracle-free:23.9-slim
        env:
          ORACLE_PASSWORD: ${{ secrets.ORACLE_PASSWORD }}
          APP_USER: demouser
          APP_USER_PASSWORD: ${{ secrets.APP_USER_PASSWORD }}
        ports:
          - 1521:1521
        options: >-
          --health-cmd healthcheck.sh
          --health-interval 10s
          --health-timeout 5s
          --health-retries 10
      ords:
        image: container-registry.oracle.com/database/ords:25.3.1
        env:
          DBSERVICENAME: FREEPDB1
          DBHOST: oracle
          DBPORT: 1521
          ORACLE_PWD: ${{ secrets.ORACLE_PASSWORD }}
        ports:
          - 8080:8080
          - 8443:8443

    steps:
      - uses: actions/checkout@v4

      - name: setup SQLcl
        uses: gvenzl/setup-oracle-sqlcl@v1
        
      - name: install utPLSQL 3.1.14
        run: |
          curl -LO https://github.com/utPLSQL/utPLSQL/releases/download/v3.1.14/utPLSQL.zip
          unzip -q utPLSQL.zip
          sql sys/${{ secrets.ORACLE_PASSWORD }}@localhost/FREEPDB1 as sysdba @utPLSQL/source/install_headless.sql

      - name: Deploy the backend part of the application
        run: |
          {
            echo "whenever sqlerror exit"
            echo "start dist/install.sql"
          } | sql demouser/${{ secrets.APP_USER_PASSWORD }}@localhost/FREEPDB1
      - name: Execute all unit tests
        run: |
          {
            echo "set serveroutput on"
            echo "whenever sqlerror exit"
            echo "exec ut.run(ut_documentation_reporter(), a_color_console=>true);"
          } | sql demouser/${{ secrets.APP_USER_PASSWORD }}@localhost/FREEPDB1

      - name: Extract commit SHA
        id: vars
        run: echo "sha_short=$(git rev-parse --short HEAD)" >> "$GITHUB_OUTPUT"
      - name: build the SQLcl artifact
        run: |
          TAG=${{ steps.vars.outputs.sha_short }}
          echo "project gen-artifact -debug -version $TAG" | sql demouser/${{ secrets.APP_USER_PASSWORD }}@localhost/FREEPDB1

      - name: upload the SQLcl build artifact
        uses: actions/upload-artifact@v4
        with:
          name: sqlcl-artifacts
          path: artifact
```

Next head over to the GitHub repository and add secrets in settings -> secrets and variables -> Actions -> Repository Secrets. Create the following 2 secrets:

- APP_USER_PASSWORD
- ORACLE_PASSWORD

Time to commit and push!

```sql
! git status -uall
! git add .
! git commit -m "feat: add GitHub Actions CI/CD pipeline"
```

The next push should trigger the CI pipeline. If that was successful, add the unit tests to the application and mark release 1.0.1

```sql
project stage -verbose
project release -version 1.0.1
! git status -uall
! git add .
! git commit -m 'feat: add unit tests and create release 1.0.1'
! git push -u origin cicd
```

Now switch to the GitHub project and watch the CI pipeline.

If the CI pipeline is green, create a PR and merge into main.

## Summary

Git is a very useful collaboration tool. For some reason it's not as popular with database developers as it is with front-end devs. This doesn't need to be the case!

You can employ DevOps principles with databases just in the same way you do with stateless applications rendering cat pictures 😀

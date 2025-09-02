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

After the data model has been created locally it's time to export it for use with SQLcl's project command. You don't do this in MAIN (or `251118_doag_git` like in this example), you create a new short-lived branch for that.

```sql
! git switch -c "initial_version"

project export
```

Review the status using `! git status` and if everything is fine, commit.

```sql
! git add .
! git commit -m "feat: add initial data model"
```

### Prepare for Release 1.0

Now we'll stage the changes for our first release. First, stage the changes using `project stage`, like so:

```sql
-- Compare current branch with main and prepare deployment artifacts
-- -debug: Shows detailed progress
-- -verbose: Provides additional information about operations
project stage -debug -verbose
```

This command:

- Compares your current branch with the main branch as per the configuration (it's `251118_doag_git` in this case, `main` for most others)
- Creates deployment scripts under the `dist/next` directory
- Requires previous changes to be committed to Git first

> [!NOTE]
> The `next` directory under `dist` is a convention in SQLcl projects, representing changes pending for the next release.

### Create version 1.0 of your application

With the changes staged, you can create the first release! In a real-world scenario you'd of course have unit and integration tests added at this stage, but for the sake of keeping this tutorial short, these steps have been omitted.

```sql
project release -version 1.0 -verbose
```

You will see the directory structure under `dist` change again, with everything that used to be under `next` moved to `1.0`, the release's name.

Time to commit these to git!

```sql
! git status
! git add .
! git commit -m "feat: create release 1.0"
```

Your branch-`initial_version`-is now ready to be merged into production! Well, only in the context of this tutorial, this wouldn't be done that way in the real world. More about that in example 2.

### Merging changes into your main branch

Most projects protect the main branch, because it's their _production_ code. The code in main should always be _clean_ and _production ready_. Those who implement CI/CD to the letter are able to deploy main at the drop of the hat, thus rolling out a new version at any time.

This tutorial shows you the basic steps for merging into the main branch (`251118_doag_git` in this case). You will learn more about real-world examples in a bit. Rarely do you merge into the protected branch in this way, if ever.

```sql
! git switch 251118_doag_git
! git merge initial_version
```

You typically generate  `project gen-artifact -format zip -version 1.0` next, followed by an upload to your artefactory.

## Example 2

The second example takes it to the next level.

The previous example demonstrated the use of Git for a single developer. Admittedly, the scenario isn't particularly realistic, but you need to learn how to walk before you can run. Let's pick up the pace and involve a collaboration platform like GitHub.

You will need to add your own Git repository if you want to follow this tutorial. It's perhaps easiest to fork the original repository.

### New ticket: add sample data

A few rows should be added to the tables. This can be done as part of the `project stage` command. For this to work reliably a small change is required: the identity columns for all tables are currently defined as `generated always...` which makes creating sample data difficult. 

Before making any changes, create a new branch for the task:

```sql
-- ensure your're on main/master/251118_doag_git
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
! git status
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
! git status
! git add .
! git commit -m 'feat: finished adding sample data'
```

But this time let's not stop here: let's involve the remote repository.

```sql
-- push the local branch to the remote repository
! git push -u origin sample_data
```

Let's address another ticket, the addition of an API and unit tests. But before that, change this file and commit it against the repository.

```
! git status
! git add .
! git commit -m 'doc: amend demo instructions in preparation for cherry picking'
```

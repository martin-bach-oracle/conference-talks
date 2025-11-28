# Datenbank Tuning aimed at Java Developers

This repository shows the code example(s) written for the 2025 edition of Frankfurter IT-Tage. This talk focuses on
the _do_s and _don't_s when it comes to developing database applications in Java.

## Using the code

After an initial draft it became clear that a multi-module Maven project was necessary. Therefore you can find the various
demos in their respective sub-directories.

Intellij IDEA (community edition 2024.3.3) was used to create this project. Updates might be necessary. JDK 21 should 
be used for all examples.

### Open Telemetry Demo

The application is mainly based on [this blogpost by Anders Swanson](https://andersswanson.dev/2025/10/10/oracle-jdbc-tracing-with-spring-boot-opentelemetry/)
and his corresponding [Github repo](https://github.com/anders-swanson/oracle-database-code-samples/tree/main/spring-boot-jdbc-tracing).

Make sure to sync the maven project and download all sources. Once the project has been compiled, you can start the database
using the `compose.yml` file. Make sure to provide an `.env` file containing 

- `ORACLE_PASSWORD`
- `APP_USER_PASSWORD`

Whichever password you chose must be entered into a run configuration. The `application.yml` file, used to initialise
the Spring application, requires the password to be present as an environment variable. The local `.env` file is
configured for in the `otel` application run configuration.

Use `{docker,podman} compose up -d` to start the database and Zipkin. If you don't like Zipkin, swap it for your preferred
solution.

With the database up and running it's time to start the application. Wait for it to initialise, then run a few queries:

```shell
# get all currently defined todos
curl http://localhost:8080/todos 

# add a todo item to the list
curl --json '{ "task": "add a new item", "done": false }' http://localhost:8080/todos

# query again
curl -s http://localhost:8080/todos  | jq

# and get a specific item
curl -s http://localhost:8080/todos/1 | jq
```

Open the Zipkin interface on localhost [http://localhost:9411/zipkin/](http://localhost:9411/zipkin/) and show the traces.

This concludes the first demo.

### Client Info

Setting client info is a very small, very simple application demonstrating the effect of setting client info, module
and action in JDBC. You'll notice that the calls don't cause any overhead, simply because they piggy-back on the next
call to the database, not requiring a dedicated round trip.

Prepare by granting select on `v_$session` to `demouser`, something that should have occurred while the database was
initially set up. If not, check [the init.sql script](./setup/init.sql) for details.

Once you are ready, start a SQLcl session and connect as demouser. Run the select statements as indicated by the application.

That concludes this demo.
package com.example.demo.models;

/**
 * create sequence todo_seq cache 50
 * create table todo(id number primary key, task varchar2(255) not null, done boolean default false not null);
 * create using src/main/resources/db/changelog/db.changelog-master.xml
 */

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;

@Entity
public class Todo {
    private @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="todo_seq")
    @SequenceGenerator(name="todo_seq", sequenceName="todo_seq", allocationSize = 1)
    Long id;
    private String task;
    private Boolean done;

    public Todo() {}

    public Todo(long id, String task, boolean done) {
        this.id = id;
        this.task = task;
        this.done = done;
    }

    public Long getId() {
        return this.id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTask() {
        return this.task;
    }

    public void setTask(String task) {
        this.task = task;
    }

    public Boolean getDone() {
        return this.done;
    }

    public void setDone(Boolean done) {
        this.done = done;
    }

    @Override
    public String toString() {
        return String.format("Todo[id: '%d', task: '%s', done: '%s'", id, task, done);
    }
}

--liquibase formatted sql
--changeset mabach:02 dbms:oracle

create table todo(
    id number,
    constraint pk_todo primary key (id), 
    task varchar2(255) not null,
    done boolean default false not null
);
--liquibase formatted sql
--changeset mabach:01 dbms:oracle

create sequence todo_seq cache 50;
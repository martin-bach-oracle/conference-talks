--liquibase formatted sql
--changeset mabach:01 dbms:oracle

create sequence todo_seq increment by 50;
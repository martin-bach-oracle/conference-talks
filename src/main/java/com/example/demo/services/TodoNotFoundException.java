package com.example.demo.services;

public class TodoNotFoundException extends RuntimeException {

    public TodoNotFoundException(Long id) {
        super("could not find todo# " + id);
    }
}

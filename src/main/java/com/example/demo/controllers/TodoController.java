package com.example.demo.controllers;

// as per https://spring.io/guides/tutorials/rest

import java.util.List;

import com.example.demo.models.Todo;
import com.example.demo.repositories.TodoRepository;
import com.example.demo.utilities.TodoNotFoundException;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TodoController {
    private final TodoRepository repository;

    TodoController(TodoRepository repository) {
        this.repository = repository;
    }


    // Aggregate root
    @GetMapping("/todos")
    List<Todo> all() {
        return repository.findAll();
    }
    // end::get-aggregate-root[]

    @GetMapping("/todos/{id}")
    Todo one(@PathVariable Long id) {
        return repository
                .findById(id)
                .orElseThrow(() -> new TodoNotFoundException(id));
    }

    @PostMapping("/todos")
    Todo newTodo(@RequestBody Todo newTodo) {
        return repository.save(newTodo);
    }

    @PutMapping("/todos/{id}")
    Todo repaceTodo(@RequestBody Todo newTodo, @PathVariable Long id) {
        return repository.findById(id)
                .map(todo -> {
                    todo.setTask(newTodo.getTask());
                    todo.setDone(newTodo.getDone());
                    return repository.save(todo);
                })
                .orElseGet( () -> {
                    return repository.save(newTodo);
                });
    }

    @DeleteMapping("/todos/{id}")
    void deleteTodo(@PathVariable Long id) {
        repository.deleteById(id);
    }
}
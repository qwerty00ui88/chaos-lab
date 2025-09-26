package com.chaoslab.dashboard.terraform.domain;

import java.util.List;
import java.util.Optional;

public interface TaskRepository {
    Task create(String name, List<String> command);

    Optional<Task> find(String id);

    List<Task> findAll();
}

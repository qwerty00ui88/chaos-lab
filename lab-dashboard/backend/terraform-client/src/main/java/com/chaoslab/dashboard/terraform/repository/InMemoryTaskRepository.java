package com.chaoslab.dashboard.terraform.repository;

import com.chaoslab.dashboard.terraform.domain.Task;
import com.chaoslab.dashboard.terraform.domain.TaskRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.springframework.stereotype.Repository;

@Repository
public class InMemoryTaskRepository implements TaskRepository {

    private final ConcurrentMap<String, Task> tasks = new ConcurrentHashMap<>();

    @Override
    public Task create(String name, List<String> command) {
        String id = UUID.randomUUID().toString();
        Task task = new Task(id, name, command, Instant.now());
        tasks.put(id, task);
        return task;
    }

    @Override
    public Optional<Task> find(String id) {
        return Optional.ofNullable(tasks.get(id));
    }

    @Override
    public List<Task> findAll() {
        return List.copyOf(tasks.values());
    }
}

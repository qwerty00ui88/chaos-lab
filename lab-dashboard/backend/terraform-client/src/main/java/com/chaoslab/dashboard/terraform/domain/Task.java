package com.chaoslab.dashboard.terraform.domain;

import java.time.Instant;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicReference;

public class Task {

    private final String id;
    private final String name;
    private final List<String> command;
    private final Instant createdAt;
    private final AtomicReference<TaskState> state = new AtomicReference<>(TaskState.PENDING);
    private final CopyOnWriteArrayList<TaskLogEntry> logs = new CopyOnWriteArrayList<>();

    private volatile Instant startedAt;
    private volatile Instant completedAt;
    private volatile Integer exitCode;
    private volatile String errorMessage;

    public Task(String id, String name, List<String> command, Instant createdAt) {
        this.id = id;
        this.name = name;
        this.command = List.copyOf(command);
        this.createdAt = createdAt;
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public List<String> getCommand() {
        return command;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getStartedAt() {
        return startedAt;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public Integer getExitCode() {
        return exitCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public TaskState getState() {
        return state.get();
    }

    public List<TaskLogEntry> getLogs() {
        return logs;
    }

    public void markRunning() {
        this.startedAt = Instant.now();
        this.state.set(TaskState.RUNNING);
    }

    public void appendLog(String stream, String line) {
        logs.add(new TaskLogEntry(Instant.now(), stream, line));
    }

    public void markSuccess(int exitCode) {
        this.exitCode = exitCode;
        this.completedAt = Instant.now();
        this.state.set(TaskState.SUCCEEDED);
    }

    public void markFailure(int exitCode, String message) {
        this.exitCode = exitCode;
        this.errorMessage = message;
        this.completedAt = Instant.now();
        this.state.set(TaskState.FAILED);
    }
}

package com.chaoslab.dashboard.terraform.domain;

import java.time.Instant;

public record TaskSummary(
    String id,
    String name,
    TaskState state,
    Instant createdAt,
    Instant startedAt,
    Instant completedAt,
    Integer exitCode,
    String errorMessage
) {
    public static TaskSummary from(Task task) {
        return new TaskSummary(
            task.getId(),
            task.getName(),
            task.getState(),
            task.getCreatedAt(),
            task.getStartedAt(),
            task.getCompletedAt(),
            task.getExitCode(),
            task.getErrorMessage()
        );
    }
}

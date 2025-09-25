package com.chaoslab.dashboard.terraform.api;

import com.chaoslab.dashboard.terraform.domain.TaskLogEntry;
import java.time.Instant;

public record TaskLogResponse(
    Instant timestamp,
    String stream,
    String line
) {
    public static TaskLogResponse from(TaskLogEntry entry) {
        return new TaskLogResponse(entry.timestamp(), entry.stream(), entry.line());
    }
}

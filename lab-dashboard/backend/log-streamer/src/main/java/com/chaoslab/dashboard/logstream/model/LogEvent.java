package com.chaoslab.dashboard.logstream.model;

import java.time.Instant;

public record LogEvent(
    Instant timestamp,
    String level,
    String source,
    String message,
    String traceId
) {
}

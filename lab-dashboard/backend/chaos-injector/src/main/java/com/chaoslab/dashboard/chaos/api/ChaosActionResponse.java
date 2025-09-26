package com.chaoslab.dashboard.chaos.api;

import java.time.Instant;
import java.util.Map;

public record ChaosActionResponse(
    String action,
    String status,
    Instant triggeredAt,
    Map<String, Object> details
) {
    public static ChaosActionResponse success(String action, Map<String, Object> details) {
        return new ChaosActionResponse(action, "SUCCESS", Instant.now(), details);
    }

    public static ChaosActionResponse failure(String action, String message) {
        return new ChaosActionResponse(action, "FAILURE", Instant.now(), Map.of("error", message));
    }
}

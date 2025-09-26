package com.chaoslab.dashboard.chaos.api;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record PodCrashRequest(
    String namespace,
    @NotBlank(message = "labelSelector is required") String labelSelector,
    @Min(value = 1, message = "maxPods must be at least 1") int maxPods
) {
}

package com.chaoslab.dashboard.chaos.api;

import jakarta.validation.constraints.Min;

public record CpuStressRequest(@Min(value = 1, message = "seconds must be at least 1") int seconds) {
}

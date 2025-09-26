package com.chaoslab.dashboard.terraform.metrics;

import java.time.Instant;

public record KpiMetrics(
    String environment,
    String service,
    String window,
    double p95LatencyMs,
    double rps,
    double rpsChangePercent,
    double errorRatePercent,
    Instant capturedAt
) {
}

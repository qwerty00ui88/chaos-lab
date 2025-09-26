package com.chaoslab.dashboard.terraform.domain;

import java.time.Instant;

public record TaskLogEntry(Instant timestamp, String stream, String line) {
}

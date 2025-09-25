package com.chaoslab.dashboard.terraform.api;

import com.chaoslab.dashboard.terraform.domain.TaskSummary;

public record TaskSummaryResponse(TaskSummary task) {
    public static TaskSummaryResponse from(TaskSummary summary) {
        return new TaskSummaryResponse(summary);
    }
}

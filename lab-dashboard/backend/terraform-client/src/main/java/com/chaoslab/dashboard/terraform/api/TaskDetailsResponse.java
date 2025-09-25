package com.chaoslab.dashboard.terraform.api;

import com.chaoslab.dashboard.terraform.domain.Task;
import com.chaoslab.dashboard.terraform.domain.TaskSummary;
import java.util.List;

public record TaskDetailsResponse(
    TaskSummary summary,
    List<TaskLogResponse> logs
) {
    public static TaskDetailsResponse from(Task task) {
        return new TaskDetailsResponse(
            TaskSummary.from(task),
            task.getLogs().stream().map(TaskLogResponse::from).toList()
        );
    }
}

package com.chaoslab.dashboard.terraform.api;

import com.chaoslab.dashboard.terraform.domain.Task;
import com.chaoslab.dashboard.terraform.domain.TaskRepository;
import com.chaoslab.dashboard.terraform.domain.TaskSummary;
import java.util.Comparator;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/tasks")
public class TaskQueryController {

    private final TaskRepository taskRepository;

    public TaskQueryController(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @GetMapping
    public List<TaskSummaryResponse> list() {
        return taskRepository.findAll().stream()
            .map(TaskSummary::from)
            .sorted(Comparator.comparing(TaskSummary::createdAt).reversed())
            .map(TaskSummaryResponse::from)
            .toList();
    }

    @GetMapping("/{taskId}")
    @ResponseStatus(HttpStatus.OK)
    public TaskDetailsResponse get(@PathVariable("taskId") String taskId) {
        Task task = taskRepository.find(taskId)
            .orElseThrow(() -> new TaskNotFoundException(taskId));
        return TaskDetailsResponse.from(task);
    }
}

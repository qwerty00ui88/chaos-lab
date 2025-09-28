package com.chaoslab.dashboard.terraform.api;

import com.chaoslab.dashboard.terraform.domain.Task;
import com.chaoslab.dashboard.terraform.service.TerraformStatusService;
import com.chaoslab.dashboard.terraform.service.TerraformTaskService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class TerraformController {

    private final TerraformTaskService taskService;
    private final TerraformStatusService statusService;

    public TerraformController(TerraformTaskService taskService, TerraformStatusService statusService) {
        this.taskService = taskService;
        this.statusService = statusService;
    }

    @PostMapping("/terraform/apply")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public TaskLaunchResponse apply(@RequestBody(required = false) TaskLaunchRequest request) {
        Task task = taskService.apply(resolveEnv(request), resolveArgs(request));
        return new TaskLaunchResponse(task.getId());
    }

    @GetMapping("/terraform/status")
    public ResponseEntity<TerraformStatusResponse> status() {
        return ResponseEntity.ok(statusService.currentStatus());
    }

    @PostMapping("/terraform/destroy")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public TaskLaunchResponse destroy(@RequestBody(required = false) TaskLaunchRequest request) {
        Task task = taskService.destroy(resolveEnv(request), resolveArgs(request));
        return new TaskLaunchResponse(task.getId());
    }

    @PostMapping("/helm/rollout")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public TaskLaunchResponse helmRollout(@RequestBody(required = false) TaskLaunchRequest request) {
        Task task = taskService.helmRollout(resolveEnv(request), resolveArgs(request));
        return new TaskLaunchResponse(task.getId());
    }

    private java.util.Map<String, String> resolveEnv(TaskLaunchRequest request) {
        return request == null ? java.util.Map.of() : request.environment();
    }

    private java.util.List<String> resolveArgs(TaskLaunchRequest request) {
        return request == null ? java.util.List.of() : request.args();
    }
}

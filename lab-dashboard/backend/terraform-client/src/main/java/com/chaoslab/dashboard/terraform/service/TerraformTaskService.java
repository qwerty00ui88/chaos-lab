package com.chaoslab.dashboard.terraform.service;

import com.chaoslab.dashboard.terraform.config.ScriptProperties;
import com.chaoslab.dashboard.terraform.domain.Task;
import java.nio.file.Path;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class TerraformTaskService {

    private final ScriptProperties scriptProperties;
    private final TaskExecutionService taskExecutionService;

    public TerraformTaskService(ScriptProperties scriptProperties, TaskExecutionService taskExecutionService) {
        this.scriptProperties = scriptProperties;
        this.taskExecutionService = taskExecutionService;
    }

    public Task apply(Map<String, String> environmentOverrides, List<String> args) {
        Path script = scriptProperties.getTerraformApplyPath();
        return taskExecutionService.runScript(
            "terraform-apply",
            script,
            defaultArgs(args),
            defaultEnv(environmentOverrides)
        );
    }

    public Task destroy(Map<String, String> environmentOverrides, List<String> args) {
        Path script = scriptProperties.getTerraformDestroyPath();
        return taskExecutionService.runScript(
            "terraform-destroy",
            script,
            defaultArgs(args),
            defaultEnv(environmentOverrides)
        );
    }

    public Task helmRollout(Map<String, String> environmentOverrides, List<String> args) {
        Path script = scriptProperties.getHelmRolloutPath();
        return taskExecutionService.runScript(
            "helm-rollout",
            script,
            defaultArgs(args),
            defaultEnv(environmentOverrides)
        );
    }

    private List<String> defaultArgs(List<String> args) {
        return args == null ? Collections.emptyList() : List.copyOf(args);
    }

    private Map<String, String> defaultEnv(Map<String, String> env) {
        return env == null ? Collections.emptyMap() : Map.copyOf(env);
    }
}

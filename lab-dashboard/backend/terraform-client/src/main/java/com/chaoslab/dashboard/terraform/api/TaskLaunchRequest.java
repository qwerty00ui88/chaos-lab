package com.chaoslab.dashboard.terraform.api;

import java.util.List;
import java.util.Map;

public record TaskLaunchRequest(
    Map<String, String> environment,
    List<String> args
) {
    public TaskLaunchRequest {
        environment = environment == null ? Map.of() : Map.copyOf(environment);
        args = args == null ? List.of() : List.copyOf(args);
    }
}

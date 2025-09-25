package com.chaoslab.dashboard.chaos.api;

import com.chaoslab.dashboard.chaos.config.ChaosProperties;
import com.chaoslab.dashboard.chaos.service.KubernetesChaosService;
import com.chaoslab.dashboard.chaos.service.TargetFaultClient;
import io.kubernetes.client.openapi.ApiException;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/chaos")
public class ChaosController {

    private final KubernetesChaosService kubernetesChaosService;
    private final TargetFaultClient faultClient;
    private final ChaosProperties properties;

    public ChaosController(KubernetesChaosService kubernetesChaosService, TargetFaultClient faultClient, ChaosProperties properties) {
        this.kubernetesChaosService = kubernetesChaosService;
        this.faultClient = faultClient;
        this.properties = properties;
    }

    @PostMapping("/pod-crash")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ChaosActionResponse crashPods(@Valid @RequestBody PodCrashRequest request) throws ApiException {
        var result = kubernetesChaosService.deletePods(request.namespace(), request.labelSelector(), request.maxPods());
        return ChaosActionResponse.success("POD_CRASH", Map.of(
            "namespace", result.namespace(),
            "labelSelector", result.labelSelector(),
            "pods", result.pods()
        ));
    }

    @PostMapping("/order-latency")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ChaosActionResponse orderLatency() {
        String response = faultClient.triggerOrderLatency();
        return ChaosActionResponse.success("ORDER_LATENCY", Map.of(
            "target", properties.getTarget().getBaseUrl() + "/order/slow",
            "response", response
        ));
    }

    @PostMapping("/cpu-high")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ChaosActionResponse cpuHigh(@Valid @RequestBody CpuStressRequest request) {
        String response = faultClient.triggerCpuHigh(request.seconds());
        return ChaosActionResponse.success("CPU_HIGH", Map.of(
            "seconds", request.seconds(),
            "response", response
        ));
    }

    @PostMapping("/oom")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ChaosActionResponse oom() {
        String response = faultClient.triggerOom();
        return ChaosActionResponse.success("OOM", Map.of(
            "response", response
        ));
    }

    @PostMapping("/db-failover")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ChaosActionResponse dbFailover() {
        String response = faultClient.triggerDbFailover();
        return ChaosActionResponse.success("DB_FAILOVER", Map.of(
            "response", response
        ));
    }

    @ExceptionHandler(ApiException.class)
    @ResponseStatus(HttpStatus.BAD_GATEWAY)
    public ChaosActionResponse handleApiException(ApiException ex) {
        return ChaosActionResponse.failure("KUBERNETES_API", ex.getResponseBody() != null ? ex.getResponseBody() : ex.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ChaosActionResponse handleIllegalArgument(IllegalArgumentException ex) {
        return ChaosActionResponse.failure("VALIDATION", ex.getMessage());
    }
}

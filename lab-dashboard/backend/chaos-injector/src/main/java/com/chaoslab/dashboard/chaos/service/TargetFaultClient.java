package com.chaoslab.dashboard.chaos.service;

import com.chaoslab.dashboard.chaos.config.ChaosProperties;
import java.net.URI;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.util.UriComponentsBuilder;
import reactor.core.publisher.Mono;

@Component
public class TargetFaultClient {

    private static final Logger log = LoggerFactory.getLogger(TargetFaultClient.class);

    private final WebClient client;
    private final ChaosProperties properties;

    public TargetFaultClient(ChaosProperties properties, WebClient.Builder builder) {
        this.properties = properties;
        this.client = builder
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(256 * 1024))
            .build();
    }

    public String triggerOrderLatency() {
        return get("/order/slow");
    }

    public String triggerCpuHigh(int seconds) {
        LinkedMultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("sec", String.valueOf(seconds));
        return get("/faults/cpu", params);
    }

    public String triggerOom() {
        return get("/faults/oom");
    }

    public String triggerDbFailover() {
        return post("/faults/db/failover", Map.of());
    }

    private String get(String path) {
        return get(path, null);
    }

    private String get(String path, LinkedMultiValueMap<String, String> params) {
        URI uri = buildUri(path, params);
        log.info("Calling target GET {}", uri);
        return client.get()
            .uri(uri)
            .retrieve()
            .bodyToMono(String.class)
            .onErrorResume(ex -> Mono.just("Request failed: " + ex.getMessage()))
            .blockOptional()
            .orElse("No response");
    }

    private String post(String path, Map<String, Object> payload) {
        URI uri = buildUri(path, null);
        log.info("Calling target POST {}", uri);
        return client.post()
            .uri(uri)
            .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .bodyValue(payload)
            .retrieve()
            .bodyToMono(String.class)
            .onErrorResume(ex -> Mono.just("Request failed: " + ex.getMessage()))
            .blockOptional()
            .orElse("No response");
    }

    private URI buildUri(String path, LinkedMultiValueMap<String, String> params) {
        LinkedMultiValueMap<String, String> safeParams = params != null ? params : new LinkedMultiValueMap<>();
        return UriComponentsBuilder.fromUriString(properties.getTarget().getBaseUrl())
            .path(path)
            .queryParams(safeParams)
            .build()
            .toUri();
    }
}

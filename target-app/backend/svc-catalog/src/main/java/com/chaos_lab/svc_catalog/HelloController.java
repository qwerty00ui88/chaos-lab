package com.chaos_lab.svc_catalog;

import java.time.Instant;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/catalog")
public class HelloController {
    @GetMapping("/hello")
    public Map<String, Object> hello() {
        return Map.of(
            "service", "svc-catalog",
            "message", "Hello!",
            "ts", Instant.now().toString()
        );
    }
}

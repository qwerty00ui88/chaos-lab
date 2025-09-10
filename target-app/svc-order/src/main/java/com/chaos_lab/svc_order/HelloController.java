package com.chaos_lab.svc_order;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.Instant;
import java.util.Map;

@RestController
public class HelloController {
    @GetMapping("/hello")
    public Map<String, Object> hello() {
        return Map.of(
            "service", "svc-order",
            "message", "Hello!",
            "ts", Instant.now().toString()
        );
    }
}


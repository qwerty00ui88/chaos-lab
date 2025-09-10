package com.chaos_lab.svc_user;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.Instant;
import java.util.Map;

@RestController
public class HelloController {
    @GetMapping("/hello")
    public Map<String, Object> hello() {
        return Map.of(
            "service", "svc-user",
            "message", "Hello!",
            "ts", Instant.now().toString()
        );
    }
}

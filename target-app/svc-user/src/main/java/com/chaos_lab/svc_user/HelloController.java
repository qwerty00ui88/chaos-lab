package com.chaos_lab.svc_user;

import java.time.Instant;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/user")
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

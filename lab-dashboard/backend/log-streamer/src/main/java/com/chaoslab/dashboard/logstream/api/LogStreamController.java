package com.chaoslab.dashboard.logstream.api;

import com.chaoslab.dashboard.logstream.model.LogEvent;
import com.chaoslab.dashboard.logstream.service.LogStreamService;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import org.springframework.web.bind.annotation.CrossOrigin;

@RestController
@RequestMapping("/api/logs")
@CrossOrigin(origins = "*")
public class LogStreamController {

    private final LogStreamService logStreamService;

    public LogStreamController(LogStreamService logStreamService) {
        this.logStreamService = logStreamService;
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<LogEvent>> streamLogs() {
        return logStreamService.stream()
            .map(event -> ServerSentEvent.<LogEvent>builder()
                .event("log")
                .data(event)
                .build());
    }

    @PostMapping
    public void publish(@RequestBody LogEvent event) {
        logStreamService.publish(event);
    }
}

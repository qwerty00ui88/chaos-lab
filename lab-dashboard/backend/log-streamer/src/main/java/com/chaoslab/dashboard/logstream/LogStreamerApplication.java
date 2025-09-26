package com.chaoslab.dashboard.logstream;

import com.chaoslab.dashboard.logstream.config.LogStreamProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(LogStreamProperties.class)
public class LogStreamerApplication {
    public static void main(String[] args) {
        SpringApplication.run(LogStreamerApplication.class, args);
    }
}

package com.chaoslab.dashboard.chaos;

import com.chaoslab.dashboard.chaos.config.ChaosProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(ChaosProperties.class)
public class ChaosInjectorApplication {
    public static void main(String[] args) {
        SpringApplication.run(ChaosInjectorApplication.class, args);
    }
}

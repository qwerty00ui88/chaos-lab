package com.chaoslab.dashboard.terraform;

import com.chaoslab.dashboard.terraform.config.ScriptProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(ScriptProperties.class)
public class TerraformClientApplication {
    public static void main(String[] args) {
        SpringApplication.run(TerraformClientApplication.class, args);
    }
}

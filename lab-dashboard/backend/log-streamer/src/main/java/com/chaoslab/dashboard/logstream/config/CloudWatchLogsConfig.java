package com.chaoslab.dashboard.logstream.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.cloudwatchlogs.CloudWatchLogsAsyncClient;

@Configuration
@ConditionalOnProperty(prefix = "logstream.cloudwatch", name = "enabled", havingValue = "true")
public class CloudWatchLogsConfig {

    private final LogStreamProperties properties;

    public CloudWatchLogsConfig(LogStreamProperties properties) {
        this.properties = properties;
    }

    @Bean
    public CloudWatchLogsAsyncClient cloudWatchLogsAsyncClient() {
        return CloudWatchLogsAsyncClient.builder()
            .region(Region.of(properties.getCloudwatch().getRegion()))
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build();
    }
}

package com.chaoslab.dashboard.logstream.service;

import com.chaoslab.dashboard.logstream.config.LogStreamProperties;
import com.chaoslab.dashboard.logstream.model.LogEvent;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;
import reactor.util.retry.Retry;
import software.amazon.awssdk.services.cloudwatchlogs.CloudWatchLogsAsyncClient;
import software.amazon.awssdk.services.cloudwatchlogs.model.FilterLogEventsRequest;
import software.amazon.awssdk.services.cloudwatchlogs.model.FilteredLogEvent;

@Service
public class LogStreamService {

    private final Sinks.Many<LogEvent> sink = Sinks.many().multicast().onBackpressureBuffer();
    private final Flux<LogEvent> mergedStream;

    private static final List<String> LEVELS = List.of("INFO", "WARN", "ERROR");
    private static final List<String> SOURCES = List.of("terraform-client", "chaos-injector", "svc-order", "svc-user");
    private static final DateTimeFormatter TRACE_FMT = DateTimeFormatter.ofPattern("HHmmssSSS").withZone(ZoneOffset.UTC);

    private final LogStreamProperties properties;
    private final CloudWatchLogsAsyncClient cloudWatchClient;
    private final AtomicLong lastSeenTimestamp = new AtomicLong(0L);

    public LogStreamService(LogStreamProperties properties, ObjectProvider<CloudWatchLogsAsyncClient> cloudWatchClientProvider) {
        this.properties = properties;
        this.cloudWatchClient = cloudWatchClientProvider.getIfAvailable();

        Flux<LogEvent> demoStream = Flux.empty();
        if (properties.getDemo().isEnabled()) {
            demoStream = Flux.interval(java.time.Duration.ofSeconds(Math.max(1, properties.getDemo().getIntervalSeconds())))
                .map(tick -> randomLogEvent())
                .share();
        }

        Flux<LogEvent> cloudWatchStream = Flux.empty();
        if (properties.getCloudwatch().isEnabled() && cloudWatchClient != null
            && properties.getCloudwatch().getLogGroupName() != null) {
            cloudWatchStream = Flux.interval(java.time.Duration.ofSeconds(Math.max(1, properties.getCloudwatch().getPollIntervalSeconds())))
                .flatMap(tick -> fetchFromCloudWatch())
                .onErrorContinue((throwable, o) -> {
                    sink.tryEmitNext(new LogEvent(Instant.now(),
                        "ERROR",
                        "log-streamer",
                        "CloudWatch poll failed: " + throwable.getMessage(),
                        "cw-error"));
                })
                .share();
        }

        this.mergedStream = Flux.merge(sink.asFlux(), demoStream, cloudWatchStream);
    }

    public Flux<LogEvent> stream() {
        return mergedStream;
    }

    public void publish(LogEvent event) {
        sink.tryEmitNext(event);
    }

    private Flux<LogEvent> fetchFromCloudWatch() {
        LogStreamProperties.CloudWatch cw = properties.getCloudwatch();
        long startTime = lastSeenTimestamp.get() + 1;

        FilterLogEventsRequest.Builder builder = FilterLogEventsRequest.builder()
            .logGroupName(cw.getLogGroupName())
            .startTime(startTime)
            .limit(cw.getMaxEvents());

        if (cw.getLogStreamPrefix() != null && !cw.getLogStreamPrefix().isBlank()) {
            builder.logStreamNamePrefix(cw.getLogStreamPrefix());
        }

        return Mono.fromFuture(cloudWatchClient.filterLogEvents(builder.build()))
            .flatMapMany(response -> Flux.fromIterable(response.events()))
            .map(this::toLogEvent)
            .doOnNext(event -> lastSeenTimestamp.accumulateAndGet(event.timestamp().toEpochMilli(), Math::max));
    }

    private LogEvent toLogEvent(FilteredLogEvent event) {
        Instant timestamp = Instant.ofEpochMilli(event.timestamp());
        String source = event.logStreamName() != null ? event.logStreamName() : "cloudwatch";
        return new LogEvent(
            timestamp,
            "INFO",
            source,
            event.message(),
            event.eventId()
        );
    }

    private LogEvent randomLogEvent() {
        Instant now = Instant.now();
        String level = LEVELS.get(ThreadLocalRandom.current().nextInt(LEVELS.size()));
        String source = SOURCES.get(ThreadLocalRandom.current().nextInt(SOURCES.size()));
        String message = switch (level) {
            case "ERROR" -> "Experiment impact detected";
            case "WARN" -> "Latency elevated";
            default -> "Execution heartbeat";
        };
        String traceId = TRACE_FMT.format(now) + Integer.toHexString(ThreadLocalRandom.current().nextInt(0, 65535));
        return new LogEvent(now, level, source, message, traceId);
    }
}

package com.chaoslab.dashboard.terraform.service;

import com.chaoslab.dashboard.terraform.domain.Task;
import com.chaoslab.dashboard.terraform.domain.TaskRepository;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

@Service
public class TaskExecutionService {

    private static final Logger log = LoggerFactory.getLogger(TaskExecutionService.class);

    private final TaskRepository taskRepository;
    private final ExecutorService executor = Executors.newCachedThreadPool(r -> {
        Thread thread = new Thread(r);
        thread.setName("command-task-" + thread.getId());
        thread.setDaemon(true);
        return thread;
    });

    public TaskExecutionService(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    public Task runScript(String name, Path script, List<String> args, Map<String, String> environment) {
        Objects.requireNonNull(script, "script");
        verifyExecutable(script);

        List<String> command = new ArrayList<>();
        command.add(script.toAbsolutePath().toString());
        if (!CollectionUtils.isEmpty(args)) {
            command.addAll(args);
        }

        Task task = taskRepository.create(name, command);

        CompletableFuture.runAsync(() -> executeProcess(task, script, command, environment), executor)
            .exceptionally(ex -> {
                log.error("Task {} failed before execution", task.getId(), ex);
                task.appendLog("system", "Failed to start: " + ex.getMessage());
                task.markFailure(-1, ex.getMessage());
                return null;
            });

        return task;
    }

    private void executeProcess(Task task, Path script, List<String> command, Map<String, String> environment) {
        ProcessBuilder builder = new ProcessBuilder(command);
        builder.redirectErrorStream(false);
        builder.directory(script.getParent().toFile());

        if (environment != null) {
            builder.environment().putAll(environment);
        }

        task.markRunning();
        task.appendLog("system", "Executing: " + String.join(" ", command));

        try {
            Process process = builder.start();
            CompletableFuture<Void> stdout = consumeStream(process.getInputStream(), task, "stdout");
            CompletableFuture<Void> stderr = consumeStream(process.getErrorStream(), task, "stderr");

            int exitCode = process.waitFor();
            stdout.join();
            stderr.join();

            if (exitCode == 0) {
                task.markSuccess(exitCode);
            } else {
                task.markFailure(exitCode, "Process exited with code " + exitCode);
            }
        } catch (IOException e) {
            task.appendLog("system", "Execution failed: " + e.getMessage());
            task.markFailure(-1, e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            task.appendLog("system", "Execution interrupted: " + e.getMessage());
            task.markFailure(-1, e.getMessage());
        }
    }

    private CompletableFuture<Void> consumeStream(InputStream stream, Task task, String streamName) {
        return CompletableFuture.runAsync(() -> {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(stream))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    task.appendLog(streamName, line);
                }
            } catch (IOException e) {
                task.appendLog("system", "Failed to read " + streamName + ": " + e.getMessage());
            }
        }, executor);
    }

    private void verifyExecutable(Path script) {
        if (!Files.exists(script)) {
            throw new IllegalArgumentException("Script not found: " + script);
        }
        if (!Files.isExecutable(script)) {
            throw new IllegalArgumentException("Script is not executable: " + script);
        }
    }

    @PreDestroy
    public void shutdown() {
        executor.shutdownNow();
    }
}

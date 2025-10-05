package com.chaoslab.dashboard.terraform.service;

import com.chaoslab.dashboard.terraform.api.TerraformStatusResponse;
import com.chaoslab.dashboard.terraform.config.ScriptProperties;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class TerraformStatusService {

    private static final Logger log = LoggerFactory.getLogger(TerraformStatusService.class);

    private final ScriptProperties scriptProperties;

    public TerraformStatusService(ScriptProperties scriptProperties) {
        this.scriptProperties = scriptProperties;
    }

    public TerraformStatusResponse currentStatus() {
        Path workingDir = scriptProperties.getTerraformWorkingDirectory();
        if (!Files.isDirectory(workingDir)) {
            String message = "Terraform working directory not found: " + workingDir;
            log.warn(message);
            return TerraformStatusResponse.unknown(message);
        }

        List<String> command = List.of("terraform", "state", "list");
        ProcessBuilder builder = new ProcessBuilder(command);
        builder.directory(workingDir.toFile());
        builder.redirectErrorStream(true);
        builder.environment().putIfAbsent("TF_IN_AUTOMATION", "1");

        List<String> output = new ArrayList<>();
        try {
            Process process = builder.start();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.add(line);
                }
            }
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                String message = String.join("\n", output).trim();
                if (message.isEmpty()) {
                    message = "terraform state list exited with code " + exitCode;
                }
                log.warn("Failed to read terraform state (exit={})", exitCode);
                return TerraformStatusResponse.unknown(message);
            }

            boolean hasResources = output.stream().anyMatch(line -> line != null && !line.trim().isEmpty());
            if (hasResources) {
                return TerraformStatusResponse.enabled(null);
            }
            return TerraformStatusResponse.disabled(null);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            String message = ie.getMessage();
            log.warn("Terraform status check interrupted", ie);
            return TerraformStatusResponse.unknown(message);
        } catch (IOException ioe) {
            String message = ioe.getMessage();
            log.warn("Unable to determine terraform status", ioe);
            return TerraformStatusResponse.unknown(message);
        }
    }
}

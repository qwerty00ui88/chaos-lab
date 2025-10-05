package com.chaoslab.dashboard.terraform.config;

import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.util.StringUtils;

@ConfigurationProperties(prefix = "chaoslab.scripts")
public class ScriptProperties {

    private static final Path DEFAULT_BASE_DIR = Paths.get("/opt/chaos-dashboard/scripts");

    private Path baseDir = normalizeBase(DEFAULT_BASE_DIR);

    private Terraform terraform = new Terraform();

    private Helm helm = new Helm();

    private Path terraformWorkingDir = DEFAULT_BASE_DIR.resolve("../infra/onoff").normalize();

    public Path getBaseDir() {
        return baseDir;
    }

    public void setBaseDir(Path baseDir) {
        if (baseDir != null) {
            this.baseDir = normalizeBase(baseDir);
        }
    }

    public Terraform getTerraform() {
        return terraform;
    }

    public void setTerraform(Terraform terraform) {
        this.terraform = terraform;
    }

    public Helm getHelm() {
        return helm;
    }

    public void setHelm(Helm helm) {
        this.helm = helm;
    }

    public Path resolve(String script) {
        if (!StringUtils.hasText(script)) {
            throw new IllegalArgumentException("Script path must not be empty");
        }
        Path candidate = Paths.get(script).normalize();
        if (candidate.isAbsolute()) {
            return candidate;
        }
        return normalizeBase(baseDir).resolve(candidate).normalize();
    }

    public Path getTerraformWorkingDirectory() {
        Path candidate = terraformWorkingDir.normalize();
        if (candidate.isAbsolute()) {
            return candidate;
        }
        return candidate.toAbsolutePath().normalize();
    }

    public void setTerraformWorkingDir(Path terraformWorkingDir) {
        if (terraformWorkingDir != null) {
            this.terraformWorkingDir = terraformWorkingDir.normalize();
        }
    }

    public Path getTerraformApplyPath() {
        return resolve(terraform.getApply());
    }

    public Path getTerraformDestroyPath() {
        return resolve(terraform.getDestroy());
    }

    public Path getHelmRolloutPath() {
        return resolve(helm.getRollout());
    }

    private Path normalizeBase(Path base) {
        Path normalized = base.normalize();
        if (normalized.isAbsolute()) {
            return normalized;
        }
        return normalized.toAbsolutePath().normalize();
    }

    public static class Terraform {
        private String apply = "onoff/apply.sh";
        private String destroy = "onoff/destroy.sh";

        public String getApply() {
            return apply;
        }

        public void setApply(String apply) {
            this.apply = apply;
        }

        public String getDestroy() {
            return destroy;
        }

        public void setDestroy(String destroy) {
            this.destroy = destroy;
        }
    }

    public static class Helm {
        private String rollout = "onoff/helm-rollout.sh";

        public String getRollout() {
            return rollout;
        }

        public void setRollout(String rollout) {
            this.rollout = rollout;
        }
    }
}

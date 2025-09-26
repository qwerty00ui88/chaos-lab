package com.chaoslab.dashboard.terraform.config;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.util.StringUtils;

@ConfigurationProperties(prefix = "chaoslab.scripts")
public class ScriptProperties {

    private Path baseDir = Paths.get("/opt/chaos-dashboard/scripts");

    private Terraform terraform = new Terraform();

    private Helm helm = new Helm();

    public Path getBaseDir() {
        return baseDir;
    }

    public void setBaseDir(Path baseDir) {
        if (baseDir != null) {
            this.baseDir = baseDir;
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
        Path candidate = Paths.get(script);
        if (candidate.isAbsolute()) {
            return candidate.normalize();
        }
        return baseDir.resolve(candidate).normalize();
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

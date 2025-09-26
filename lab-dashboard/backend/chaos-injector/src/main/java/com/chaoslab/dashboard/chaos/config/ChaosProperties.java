package com.chaoslab.dashboard.chaos.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "chaoslab")
public class ChaosProperties {

    private final Kubernetes kubernetes = new Kubernetes();
    private final Target target = new Target();

    public Kubernetes getKubernetes() {
        return kubernetes;
    }

    public Target getTarget() {
        return target;
    }

    public static class Kubernetes {
        /**
         * Optional path to kubeconfig file. If not provided, in-cluster config or default loading rules are used.
         */
        private String configPath;

        /**
         * Optional kubeconfig context name.
         */
        private String context;

        /**
         * Default namespace used when requests do not specify one.
         */
        private String namespace = "default";

        public String getConfigPath() {
            return configPath;
        }

        public void setConfigPath(String configPath) {
            this.configPath = configPath;
        }

        public String getContext() {
            return context;
        }

        public void setContext(String context) {
            this.context = context;
        }

        public String getNamespace() {
            return namespace;
        }

        public void setNamespace(String namespace) {
            this.namespace = namespace;
        }
    }

    public static class Target {
        /**
         * Base URL of the target application used for HTTP based fault injections.
         */
        private String baseUrl = "http://target.chaos-lab.org";

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }
    }
}

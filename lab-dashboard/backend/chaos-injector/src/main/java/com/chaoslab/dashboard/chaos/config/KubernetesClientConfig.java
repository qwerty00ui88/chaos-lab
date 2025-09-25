package com.chaoslab.dashboard.chaos.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.kubernetes.client.openapi.ApiClient;
import io.kubernetes.client.openapi.apis.CoreV1Api;
import io.kubernetes.client.util.ClientBuilder;
import io.kubernetes.client.util.KubeConfig;
import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class KubernetesClientConfig {

    private static final Logger log = LoggerFactory.getLogger(KubernetesClientConfig.class);

    private final ChaosProperties properties;

    public KubernetesClientConfig(ChaosProperties properties) {
        this.properties = properties;
    }

    @Bean
    public ApiClient apiClient(ObjectMapper objectMapper) throws IOException {
        ApiClient client;
        ChaosProperties.Kubernetes kube = properties.getKubernetes();
        if (kube.getConfigPath() != null && !kube.getConfigPath().isBlank()) {
            log.info("Loading kubeconfig from {}", kube.getConfigPath());
            try (Reader reader = new FileReader(kube.getConfigPath())) {
                KubeConfig config = KubeConfig.loadKubeConfig(reader);
                if (kube.getContext() != null && !kube.getContext().isBlank()) {
                    config.setContext(kube.getContext());
                }
                client = ClientBuilder.kubeconfig(config).build();
            }
        } else {
            log.info("Using default Kubernetes client configuration");
            client = ClientBuilder.standard().build();
        }
        client.setUserAgent("chaos-injector/0.0.1");
        io.kubernetes.client.openapi.Configuration.setDefaultApiClient(client);
        return client;
    }

    @Bean
    public CoreV1Api coreV1Api(ApiClient apiClient) {
        return new CoreV1Api(apiClient);
    }
}

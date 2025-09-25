package com.chaoslab.dashboard.chaos.service;

import com.chaoslab.dashboard.chaos.config.ChaosProperties;
import io.kubernetes.client.openapi.ApiException;
import io.kubernetes.client.openapi.apis.CoreV1Api;
import io.kubernetes.client.openapi.models.V1DeleteOptions;
import io.kubernetes.client.openapi.models.V1Pod;
import io.kubernetes.client.openapi.models.V1PodList;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class KubernetesChaosService {

    private static final Logger log = LoggerFactory.getLogger(KubernetesChaosService.class);

    private final CoreV1Api coreV1Api;
    private final ChaosProperties properties;

    public KubernetesChaosService(CoreV1Api coreV1Api, ChaosProperties properties) {
        this.coreV1Api = coreV1Api;
        this.properties = properties;
    }

    public PodKillResult deletePods(String namespace, String labelSelector, int maxPods) throws ApiException {
        String effectiveNamespace = StringUtils.hasText(namespace) ? namespace : properties.getKubernetes().getNamespace();
        if (!StringUtils.hasText(labelSelector)) {
            throw new IllegalArgumentException("labelSelector must not be empty");
        }
        if (maxPods <= 0) {
            throw new IllegalArgumentException("maxPods must be greater than zero");
        }

        log.info("Deleting up to {} pods in namespace '{}' matching selector '{}'", maxPods, effectiveNamespace, labelSelector);
        V1PodList pods = coreV1Api.listNamespacedPod(
            effectiveNamespace,
            null,
            null,
            null,
            null,
            labelSelector,
            null,
            null,
            null,
            null,
            null,
            false
        );

        List<PodKillResult.PodRef> terminated = new ArrayList<>();
        int count = 0;
        for (V1Pod pod : pods.getItems()) {
            if (count >= maxPods) {
                break;
            }
            if (pod.getMetadata() == null || pod.getMetadata().getName() == null) {
                continue;
            }
            String podName = pod.getMetadata().getName();
            coreV1Api.deleteNamespacedPod(podName, effectiveNamespace, null, null, null, null, null, new V1DeleteOptions());
            terminated.add(new PodKillResult.PodRef(podName, pod.getMetadata().getNamespace(), Instant.now()));
            count++;
            log.info("Requested deletion for pod {}/{}", effectiveNamespace, podName);
        }

        return new PodKillResult(effectiveNamespace, labelSelector, terminated);
    }

    public record PodKillResult(String namespace, String labelSelector, List<PodRef> pods) {
        public record PodRef(String name, String namespace, Instant deletedAt) {
        }
    }
}

package com.chaoslab.dashboard.logstream.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "logstream")
public class LogStreamProperties {

    private final Demo demo = new Demo();
    private final CloudWatch cloudwatch = new CloudWatch();

    public Demo getDemo() {
        return demo;
    }

    public CloudWatch getCloudwatch() {
        return cloudwatch;
    }

    public static class Demo {
        private boolean enabled = true;
        private int intervalSeconds = 2;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public int getIntervalSeconds() {
            return intervalSeconds;
        }

        public void setIntervalSeconds(int intervalSeconds) {
            this.intervalSeconds = intervalSeconds;
        }
    }

    public static class CloudWatch {
        private boolean enabled = false;
        private String region = "ap-northeast-2";
        private String logGroupName;
        private String logStreamPrefix;
        private int pollIntervalSeconds = 5;
        private int maxEvents = 100;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getRegion() {
            return region;
        }

        public void setRegion(String region) {
            this.region = region;
        }

        public String getLogGroupName() {
            return logGroupName;
        }

        public void setLogGroupName(String logGroupName) {
            this.logGroupName = logGroupName;
        }

        public String getLogStreamPrefix() {
            return logStreamPrefix;
        }

        public void setLogStreamPrefix(String logStreamPrefix) {
            this.logStreamPrefix = logStreamPrefix;
        }

        public int getPollIntervalSeconds() {
            return pollIntervalSeconds;
        }

        public void setPollIntervalSeconds(int pollIntervalSeconds) {
            this.pollIntervalSeconds = pollIntervalSeconds;
        }

        public int getMaxEvents() {
            return maxEvents;
        }

        public void setMaxEvents(int maxEvents) {
            this.maxEvents = maxEvents;
        }
    }
}

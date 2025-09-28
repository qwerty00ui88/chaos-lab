package com.chaoslab.dashboard.terraform.api;

public record TerraformStatusResponse(boolean enabled, String state, String message) {
    public static TerraformStatusResponse enabled(String message) {
        return new TerraformStatusResponse(true, "enabled", message);
    }

    public static TerraformStatusResponse disabled(String message) {
        return new TerraformStatusResponse(false, "disabled", message);
    }

    public static TerraformStatusResponse unknown(String message) {
        return new TerraformStatusResponse(false, "unknown", message);
    }
}

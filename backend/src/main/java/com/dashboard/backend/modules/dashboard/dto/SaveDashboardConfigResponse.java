package com.dashboard.backend.modules.dashboard.dto;

public record SaveDashboardConfigResponse(
        int versionNo,
        String updatedAt
) {
}

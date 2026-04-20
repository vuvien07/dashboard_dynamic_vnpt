package com.dashboard.backend.modules.dashboard.dto;

public record DashboardListItemResponse(
        String id,
        String name,
        String visibility,
        String status,
        String updatedAt
) {
}

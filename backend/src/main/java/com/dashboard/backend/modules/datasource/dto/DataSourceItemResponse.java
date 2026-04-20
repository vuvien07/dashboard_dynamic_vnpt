package com.dashboard.backend.modules.datasource.dto;

public record DataSourceItemResponse(
        String id,
        String name,
        String type,
        String status
) {
}

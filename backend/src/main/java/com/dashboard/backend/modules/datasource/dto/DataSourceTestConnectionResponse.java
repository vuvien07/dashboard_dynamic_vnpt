package com.dashboard.backend.modules.datasource.dto;

public record DataSourceTestConnectionResponse(
        String dataSourceId,
        boolean success,
        String message
) {
}

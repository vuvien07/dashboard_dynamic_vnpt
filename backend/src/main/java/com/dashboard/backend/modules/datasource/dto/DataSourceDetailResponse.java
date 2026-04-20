package com.dashboard.backend.modules.datasource.dto;

import java.util.Map;

public record DataSourceDetailResponse(
        String id,
        String name,
        String type,
        String status,
        String jdbcUrl,
        String username,
        Map<String, Object> fieldMapping
) {
}

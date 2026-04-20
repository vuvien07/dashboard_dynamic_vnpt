package com.dashboard.backend.modules.datasource.dto;

import java.util.Map;

public record DataSourceQueryResponse(
        String dataSourceId,
        String shape,
        Map<String, Object> payload
) {
}

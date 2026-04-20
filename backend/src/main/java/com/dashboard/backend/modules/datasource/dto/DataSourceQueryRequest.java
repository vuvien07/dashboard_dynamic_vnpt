package com.dashboard.backend.modules.datasource.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.List;
import java.util.Map;

public record DataSourceQueryRequest(
        @NotBlank String widgetId,
        @NotBlank String dataSourceId,
        String widgetTypeCode,
        Map<String, Object> queryConfig,
        List<FilterRequest> filters
) {
}

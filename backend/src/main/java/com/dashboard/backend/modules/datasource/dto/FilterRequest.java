package com.dashboard.backend.modules.datasource.dto;

import java.util.List;

public record FilterRequest(
        String type,
        String targetTable,
        String targetField,
        String fieldType,
        List<String> dashboardWidgetIds,
        Object value
) {
}

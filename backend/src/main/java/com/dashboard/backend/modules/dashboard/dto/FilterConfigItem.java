package com.dashboard.backend.modules.dashboard.dto;

import java.util.List;
import java.util.Map;

public record FilterConfigItem(
        String id,
        String label,
        String placeholder,
        String type,
        String targetTable,
        String targetField,
        String fieldType,
        List<String> dashboardWidgetIds
) {
}

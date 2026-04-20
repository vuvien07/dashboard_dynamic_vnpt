package com.dashboard.backend.modules.dashboard.dto;

import java.util.Map;

public record WidgetConfigItem(
        String id,
        String widgetTypeCode,
        String title,
        Map<String, Object> props,
        String dataSourceId,
        Map<String, Object> queryConfig,
        Integer refreshIntervalSec
) {
}

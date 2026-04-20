package com.dashboard.backend.modules.dashboard.dto;

import java.util.List;
import java.util.Map;

public record DashboardConfigResponse(
        DashboardMeta dashboard,
        List<WidgetConfigItem> widgets,
        Map<String, List<LayoutItem>> layouts,
        Map<String, List<LayoutItem>> filterLayouts,
        List<FilterConfigItem> filters
) {
}

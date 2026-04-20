package com.dashboard.backend.modules.dashboard.dto;

import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.Map;

public record SaveDashboardConfigRequest(
        @NotNull Integer expectedVersionNo,
        @NotNull List<WidgetConfigItem> widgets,
        @NotNull Map<String, List<LayoutItem>> layouts,
        @NotNull List<FilterConfigItem> filters,
        @NotNull Map<String, List<LayoutItem>> filterLayouts,
        List<String> filterIds,
        String changeNote
) {
}

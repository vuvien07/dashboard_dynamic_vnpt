package com.dashboard.backend.modules.widget.dto;

import java.util.Map;

public record WidgetTypeResponse(
        String id,
        String code,
        String name,
        String category,
        String icon,
        Map<String, Object> propsSchema,
        Map<String, Object> defaultProps
) {
}

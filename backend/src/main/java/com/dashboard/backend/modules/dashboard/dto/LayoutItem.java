package com.dashboard.backend.modules.dashboard.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record LayoutItem(
        String widgetId,
        int x,
        int y,
        int w,
        int h,
        @JsonProperty("static") boolean staticLayout
) {
}

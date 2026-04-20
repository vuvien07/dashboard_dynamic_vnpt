package com.dashboard.backend.modules.widget.controller;

import com.dashboard.backend.modules.widget.dto.WidgetTypeResponse;
import com.dashboard.backend.modules.widget.service.WidgetTypeService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/widget-types")
public class WidgetTypeController {

        private final WidgetTypeService widgetTypeService;

        public WidgetTypeController(WidgetTypeService widgetTypeService) {
                this.widgetTypeService = widgetTypeService;
        }

    @GetMapping
    public Map<String, List<WidgetTypeResponse>> list() {
                return Map.of("items", widgetTypeService.listActive());
    }
}

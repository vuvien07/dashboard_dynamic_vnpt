package com.dashboard.backend.modules.dashboard.controller;

import com.dashboard.backend.modules.dashboard.dto.*;
import com.dashboard.backend.modules.dashboard.service.DashboardService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/dashboards")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping
    public Map<String, List<DashboardListItemResponse>> list() {
        return Map.of("items", dashboardService.listDashboards());
    }

    @GetMapping("/{type}/filterOption")
    public Map<String, List<OptionListItemResponse>> listFilterOption(@PathVariable String type) {
        return Map.of("items", dashboardService.listOptions(type));
    }

    @PostMapping
    public DashboardMeta create(@Valid @RequestBody CreateDashboardRequest request) {
        return dashboardService.createDashboard(request);
    }

    @DeleteMapping("/{dashboardId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String dashboardId) {
        dashboardService.deleteDashboard(dashboardId);
    }

    @GetMapping("/{dashboardId}/config")
    public DashboardConfigResponse getConfig(@PathVariable String dashboardId) {
        return dashboardService.getConfig(dashboardId);
    }

    @PutMapping("/{dashboardId}/config")
    public SaveDashboardConfigResponse saveConfig(@PathVariable String dashboardId,
                                                  @Valid @RequestBody SaveDashboardConfigRequest request) {
        return dashboardService.saveConfig(dashboardId, request);
    }

    @GetMapping("/schema")
    public Map<String, List<AnalyticSchemaItemResponse>> listAnalyticTablesAndColumns() {
        return dashboardService.listAnalyticTablesAndColumns();
    }

    @GetMapping("/{targetTable}/{targetField}/values")
    public List<Object> getValuesFromTable(@PathVariable String targetTable, @PathVariable String targetField) {
        return dashboardService.getValuesFromTable(targetTable, targetField);
    }
}

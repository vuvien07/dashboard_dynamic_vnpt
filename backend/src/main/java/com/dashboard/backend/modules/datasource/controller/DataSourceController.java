package com.dashboard.backend.modules.datasource.controller;

import com.dashboard.backend.modules.datasource.dto.DataSourceDetailResponse;
import com.dashboard.backend.modules.datasource.dto.DataSourceItemResponse;
import com.dashboard.backend.modules.datasource.dto.DataSourceQueryRequest;
import com.dashboard.backend.modules.datasource.dto.DataSourceQueryResponse;
import com.dashboard.backend.modules.datasource.dto.DataSourceTestConnectionResponse;
import com.dashboard.backend.modules.datasource.dto.DataSourceUpsertRequest;
import com.dashboard.backend.modules.datasource.service.DataSourceService;
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
@RequestMapping("/api/v1/data-sources")
public class DataSourceController {

    private final DataSourceService dataSourceService;

    public DataSourceController(DataSourceService dataSourceService) {
        this.dataSourceService = dataSourceService;
    }

    @GetMapping
    public Map<String, List<DataSourceItemResponse>> list() {
        return Map.of("items", dataSourceService.listDataSources());
    }

    @GetMapping("/{dataSourceId}")
    public DataSourceDetailResponse detail(@PathVariable String dataSourceId) {
        return dataSourceService.getDataSource(dataSourceId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DataSourceDetailResponse create(@Valid @RequestBody DataSourceUpsertRequest request) {
        return dataSourceService.createDataSource(request);
    }

    @PutMapping("/{dataSourceId}")
    public DataSourceDetailResponse update(@PathVariable String dataSourceId,
                                           @Valid @RequestBody DataSourceUpsertRequest request) {
        return dataSourceService.updateDataSource(dataSourceId, request);
    }

    @DeleteMapping("/{dataSourceId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String dataSourceId) {
        dataSourceService.deleteDataSource(dataSourceId);
    }

    @PostMapping("/{dataSourceId}/test-connection")
    public DataSourceTestConnectionResponse testConnection(@PathVariable String dataSourceId) {
        return dataSourceService.testConnection(dataSourceId);
    }

    @PostMapping("/query")
    public DataSourceQueryResponse query(@Valid @RequestBody DataSourceQueryRequest request) {
        return dataSourceService.query(request);
    }
}

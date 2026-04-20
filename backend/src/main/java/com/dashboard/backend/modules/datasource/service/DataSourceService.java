package com.dashboard.backend.modules.datasource.service;

import com.dashboard.backend.modules.datasource.dto.*;
import com.dashboard.backend.modules.datasource.entity.DataSourceEntity;
import com.dashboard.backend.modules.datasource.repository.DataSourceRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.Connection;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class DataSourceService {

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private final DataSourceRepository dataSourceRepository;
    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    public DataSourceService(DataSourceRepository dataSourceRepository,
                             JdbcTemplate jdbcTemplate,
                             ObjectMapper objectMapper) {
        this.dataSourceRepository = dataSourceRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = objectMapper;
    }

    public List<DataSourceItemResponse> listDataSources() {
        return dataSourceRepository.findAllByOrderByNameAsc().stream()
                .map(entity -> new DataSourceItemResponse(
                        entity.getId(),
                        entity.getName(),
                        entity.getType(),
                        entity.getStatus()
                ))
                .toList();
    }

    public DataSourceDetailResponse getDataSource(String id) {
        DataSourceEntity entity = mustExist(id);
        return toDetail(entity);
    }

    @Transactional
    public DataSourceDetailResponse createDataSource(DataSourceUpsertRequest request) {
        if (dataSourceRepository.existsById(request.id())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Data source id already exists");
        }

        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
        DataSourceEntity entity = new DataSourceEntity();
        entity.setId(request.id());
        entity.setName(request.name());
        entity.setType(request.type());
        entity.setStatus(request.status());
        entity.setJdbcUrl(request.jdbcUrl());
        entity.setUsername(request.username());
        entity.setPassword(request.password());
        entity.setFieldMappingJson(toJson(request.fieldMapping()));
        entity.setCreatedAt(now);
        entity.setUpdatedAt(now);
        dataSourceRepository.save(entity);
        return toDetail(entity);
    }

    @Transactional
    public DataSourceDetailResponse updateDataSource(String id, DataSourceUpsertRequest request) {
        DataSourceEntity entity = mustExist(id);
        entity.setName(request.name());
        entity.setType(request.type());
        entity.setStatus(request.status());
        entity.setJdbcUrl(request.jdbcUrl());
        entity.setUsername(request.username());
        entity.setPassword(request.password());
        entity.setFieldMappingJson(toJson(request.fieldMapping()));
        entity.setUpdatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        dataSourceRepository.save(entity);
        return toDetail(entity);
    }

    @Transactional
    public void deleteDataSource(String id) {
        DataSourceEntity entity = mustExist(id);
        dataSourceRepository.delete(entity);
    }

    public DataSourceTestConnectionResponse testConnection(String id) {
        DataSourceEntity entity = mustExist(id);
        if (isApiDataSource(entity)) {
            try {
                Map<String, Object> mapping = parseMap(entity.getFieldMappingJson());
                String apiUrl = stringValue(entity.getJdbcUrl());
                if (apiUrl.isBlank()) {
                    return new DataSourceTestConnectionResponse(entity.getId(), false, "API URL is required for api datasource");
                }

                HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(apiUrl))
                        .timeout(Duration.ofSeconds(10));

                String method = stringValue(mapping.get("apiMethod"));
                if (method.isBlank()) {
                    method = "GET";
                }
                method = method.toUpperCase(Locale.ROOT);

                for (Map.Entry<String, String> header : headerMap(mapping.get("apiHeaders")).entrySet()) {
                    builder.header(header.getKey(), header.getValue());
                }

                HttpRequest request = builder.method(method, HttpRequest.BodyPublishers.noBody()).build();
                HttpResponse<Void> response = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.discarding());
                boolean success = response.statusCode() >= 200 && response.statusCode() < 300;
                String message = success
                        ? "API reachable (" + response.statusCode() + ")"
                        : "API responded " + response.statusCode();
                return new DataSourceTestConnectionResponse(entity.getId(), success, message);
            } catch (Exception ex) {
                return new DataSourceTestConnectionResponse(entity.getId(), false, ex.getMessage());
            }
        }

        try {
            JdbcClient client = createJdbcClient(entity);
            DataSourceEntity dataSourceEntity = mustExist(id);

            switch (dataSourceEntity.getType()) {
                case "postgresql":
                    client.sql("SELECT EXTRACT(EPOCH FROM now())")
                            .query(Number.class)
                            .single();
                    break;
                case "clickhouse":
                    client.sql("SELECT toUnixTimestamp64Micro(now64())")
                            .query(Number.class)
                            .single();
                    break;
                default:
                    throw new IllegalStateException("Unknown type: " + dataSourceEntity.getType());
            }

            return new DataSourceTestConnectionResponse(entity.getId(), true, "Connection success");
        } catch (Exception ex) {
            return new DataSourceTestConnectionResponse(entity.getId(), false, "Connection failed");
            // optionally log ex here
        }
    }

    public DataSourceQueryResponse query(DataSourceQueryRequest request) {
        DataSourceEntity entity = mustExist(request.dataSourceId());
        String widgetType = request.widgetTypeCode() == null ? "" : request.widgetTypeCode();
        String shape = resolveShape(request, widgetType);

        if (isApiDataSource(entity)) {
            Map<String, Object> payload = buildApiPayload(entity, request, shape);
            return new DataSourceQueryResponse(request.dataSourceId(), shape, payload);
        }

        if ("single".equals(shape)) {
            return new DataSourceQueryResponse(request.dataSourceId(), shape, buildSingleValuePayload(entity, request));
        }
        if ("timeseries".equals(shape)) {
            return new DataSourceQueryResponse(request.dataSourceId(), shape, buildTimeSeriesPayload(entity, request));
        }
        if ("category".equals(shape)) {
            return new DataSourceQueryResponse(request.dataSourceId(), shape, buildCategoryPayload(entity, request));
        }
        if ("table".equals(shape)) {
            return new DataSourceQueryResponse(request.dataSourceId(), shape, buildTablePayload(entity, request));
        }
        if ("list".equals(shape)) {
            return new DataSourceQueryResponse(request.dataSourceId(), shape, buildListPayload(entity, request));
        }

        return new DataSourceQueryResponse(request.dataSourceId(), "single", Map.of(
                "title", metricName(request),
                "value", 0,
                "unit", "count"
        ));
    }

    private boolean isTimeseriesWidget(String widgetTypeCode) {
        return List.of("line-chart", "area-chart", "scatter-chart", "timeline").contains(widgetTypeCode);
    }

    private boolean isCategoryWidget(String widgetTypeCode) {
        return List.of("bar-chart", "pie-chart", "heatmap", "geo-map").contains(widgetTypeCode);
    }

    private boolean isTableWidget(String widgetTypeCode) {
        return "data-table".equals(widgetTypeCode) || "table".equals(widgetTypeCode);
    }

    private String shapeForWidgetType(String widgetTypeCode) {
        if (isTimeseriesWidget(widgetTypeCode)) {
            return "timeseries";
        }
        if (isCategoryWidget(widgetTypeCode)) {
            return "category";
        }
        if (isTableWidget(widgetTypeCode)) {
            return "table";
        }
        if ("list".equals(widgetTypeCode)) {
            return "list";
        }
        return "single";
    }

    private String resolveShape(DataSourceQueryRequest request, String widgetTypeCode) {
        if ("custom.html".equals(widgetTypeCode)) {
            String requestedShape = requestedShape(request);
            if (!requestedShape.isBlank()) {
                return requestedShape;
            }
        }
        return shapeForWidgetType(widgetTypeCode);
    }

    private String requestedShape(DataSourceQueryRequest request) {
        if (request.queryConfig() == null) {
            return "";
        }
        Object rawShape = request.queryConfig().get("shape");
        if (rawShape == null) {
            return "";
        }
        String shape = rawShape.toString().trim().toLowerCase(Locale.ROOT);
        return switch (shape) {
            case "single", "timeseries", "category", "table", "list" -> shape;
            default -> "";
        };
    }

    private boolean isApiDataSource(DataSourceEntity entity) {
        return "api".equalsIgnoreCase(stringValue(entity.getType()));
    }

    private String metricName(DataSourceQueryRequest request) {
        Object rawMetric = request.queryConfig() == null ? null : request.queryConfig().get("metric");
        if (rawMetric == null || rawMetric.toString().isBlank()) {
            return "value";
        }
        return rawMetric.toString().trim();
    }

    /**
     * Trả danh sách tên metric từ queryConfig.
     * Hỗ trợ cả key "metric" (chuỗi đơn) lẫn "metrics" (mảng) để tương thích nhiều widget.
     */
    @SuppressWarnings("unchecked")
    private List<String> metricNames(DataSourceQueryRequest request) {
        if (request.queryConfig() == null) {
            return List.of("value");
        }
        Object rawMetrics = request.queryConfig().get("metrics");
        if (rawMetrics instanceof List<?> list && !list.isEmpty()) {
            List<String> metrics = list.stream()
                    .map(Object::toString)
                    .map(String::trim)
                    .filter(item -> !item.isBlank())
                    .toList();
            if (!metrics.isEmpty()) {
                return metrics;
            }
        }
        Object rawMetric = request.queryConfig().get("metric");
        if (rawMetric != null && !rawMetric.toString().isBlank()) {
            return List.of(rawMetric.toString().trim());
        }
        return List.of("value");
    }

//    private Integer normalizedMonth(DataSourceQueryRequest request) {
//        Integer month = request.month();
//        if (month == null || month < 1 || month > 12) {
//            return null;
//        }
//        return month;
//    }

    private String normalizedTextFilter(String value) {
        if (value == null) {
            return null;
        }
        String next = value.trim();
        return next.isBlank() ? null : next;
    }

    private JdbcClient.StatementSpec bindGlobalFilters(JdbcClient.StatementSpec statement, List<FilterRequest> filters) {
        for (FilterRequest filter : filters) {
            if(filter.value() == null) {
                continue;
            }
            if (filter.type().equals("range")) {
                statement.param(filter.targetField() + "_from", parseValueFromPgType(filter.fieldType(), ((Map<String, Object>) filter.value()).get("min")));
                statement.param(filter.targetField() + "_to", parseValueFromPgType(filter.fieldType(), ((Map<String, Object>) filter.value()).get("max")));
            } else {
                statement.param(filter.targetField(), parseValueFromPgType(filter.fieldType(), filter.value()));
            }
        }
        return statement;
    }

    private Object parseValueFromPgType(String pgType, Object value) {
        return switch (pgType) {
            case "numeric" -> Double.parseDouble(value.toString());
            case "date" -> LocalDate.parse(value.toString());
            default -> value;
        };
    }

    private Map<String, Object> buildSingleValuePayload(DataSourceEntity entity, DataSourceQueryRequest request) {
        JdbcClient client = createJdbcClient(entity);
        String metric = metricName(request);
        StringBuilder queryBuilder = new StringBuilder();
        List<FilterRequest> filterRequest = request.filters().stream().filter((f) -> f.dashboardWidgetIds()
                .contains(request.widgetId()) && f.targetTable().equals("analytics_metric_points")).toList();
        queryBuilder.append("""
                        SELECT value
                        FROM analytics_metric_points
                        WHERE data_source_id = :dataSourceId AND metric_code = :metric
                """);
        if(!filterRequest.isEmpty()) {
            for (FilterRequest filter : filterRequest) {
                if (filter.value() != null) {
                    queryBuilder.append(
                            entity.getType().equals("postgresql") ? buildConditionalQueryWithPostgres(filter)
                                    : buildConditionalQueryWithClickhouse(filter)
                    );
                }
            }
        }

        queryBuilder.append(" ").append("""
                ORDER BY point_date DESC
                        LIMIT 1
                """);
        Double base = bindGlobalFilters(
                client.sql(queryBuilder.toString())
                        .param("dataSourceId", request.dataSourceId())
                        .param("metric", metric),
                filterRequest)
                .query(Double.class)
                .optional()
                .orElse(0.0);

        StringBuilder queryBuilder2 = new StringBuilder();

        queryBuilder2.append("""
                        SELECT value
                        FROM analytics_metric_points
                        WHERE data_source_id = :dataSourceId AND metric_code = :metric
                """);

        if(!filterRequest.isEmpty()) {
            for (FilterRequest filter : filterRequest) {
                if (filter.value() != null) {
                    queryBuilder2.append(
                            entity.getType().equals("postgresql") ? buildConditionalQueryWithPostgres(filter)
                                    : buildConditionalQueryWithClickhouse(filter)
                    );
                }
            }
        }

        queryBuilder2.append(" ").append(entity.getType().equals("postgresql") ? """
                ORDER BY point_date DESC
                        OFFSET 1 LIMIT 1
                """ : entity.getType().equals("clickhouse") ? """
                ORDER BY point_date DESC
                        LIMIT 1 OFFSET 1
                """ : "");

        Double previous = bindGlobalFilters(
                client.sql(queryBuilder2.toString())
                        .param("dataSourceId", request.dataSourceId())
                        .param("metric", metric),
                filterRequest)
                .query(Double.class)
                .optional()
                .orElse(base);

        String unit = metric.contains("rate") || metric.contains("margin") ? "%" : "count";
        if (metric.contains("revenue") || metric.contains("cpa") || metric.contains("value")) {
            unit = "currency";
        }

        return Map.of(
                "title", metric,
                "value", base,
                "previous", previous,
                "unit", unit
        );
    }

    private Map<String, Object> buildTimeSeriesPayload(DataSourceEntity entity, DataSourceQueryRequest request) {
        JdbcClient client = createJdbcClient(entity);
        List<String> metrics = metricNames(request);

        // Giữ thứ tự ngày để dùng làm labels chung
        java.util.LinkedHashSet<String> labelSet = new java.util.LinkedHashSet<>();
        // metric → (date → value)
        java.util.Map<String, java.util.Map<String, Double>> metricDateMap = new java.util.LinkedHashMap<>();
        List<FilterRequest> filterRequest = request.filters().stream().filter((f) -> f.dashboardWidgetIds()
                .contains(request.widgetId()) && f.targetTable().equals("analytics_metric_points")).toList();
        StringBuilder queryBuilder = new StringBuilder();
        queryBuilder.append("""
                            SELECT point_date, value, target_value
                            FROM analytics_metric_points
                            WHERE data_source_id = :dataSourceId AND metric_code = :metric
                """);

        if(!filterRequest.isEmpty()) {
            for (FilterRequest filter : filterRequest) {
                if (filter.value() != null) {
                    queryBuilder.append(
                            entity.getType().equals("postgresql") ? buildConditionalQueryWithPostgres(filter)
                                    : buildConditionalQueryWithClickhouse(filter)
                    );
                }
            }
        }

        queryBuilder.append(" ").append("""
                            ORDER BY point_date ASC
                                            LIMIT 365
                """);

        for (String metric : metrics) {
            List<Map<String, Object>> points = bindGlobalFilters(
                    client.sql(queryBuilder.toString())
                            .param("dataSourceId", request.dataSourceId())
                            .param("metric", metric),
                    filterRequest)
                    .query((rs, rowNum) -> Map.<String, Object>of(
                            "label", rs.getDate("point_date").toString(),
                            "value", rs.getDouble("value"),
                            "target", rs.getDouble("target_value")
                    ))
                    .list();

            java.util.Map<String, Double> dateToValue = new java.util.LinkedHashMap<>();
            for (Map<String, Object> p : points) {
                String lbl = p.get("label").toString();
                labelSet.add(lbl);
                dateToValue.put(lbl, ((Number) p.get("value")).doubleValue());
            }
            metricDateMap.put(metric, dateToValue);
        }

        List<String> labels = new java.util.ArrayList<>(labelSet);
        labels.sort(Comparator.naturalOrder());

        // Nếu chỉ có 1 metric → giữ series "actual" + "target" như cũ
        if (metrics.size() == 1) {
            String metric = metrics.get(0);
            java.util.Map<String, Double> dv = metricDateMap.get(metric);
            List<Double> actual = labels.stream().map(l -> dv.getOrDefault(l, 0.0)).toList();

            StringBuilder queryBuilder2 = new StringBuilder();
            queryBuilder2.append("""
                                SELECT point_date, target_value
                                FROM analytics_metric_points
                                WHERE data_source_id = :dataSourceId AND metric_code = :metric
                    """);

            if(!filterRequest.isEmpty()) {
                for (FilterRequest filter : filterRequest) {
                    if (filter.value() != null) {
                        queryBuilder2.append(
                                entity.getType().equals("postgresql") ? buildConditionalQueryWithPostgres(filter)
                                        : buildConditionalQueryWithClickhouse(filter)
                        );
                    }
                }
            }

            queryBuilder2.append(" ").append("""
                                ORDER BY point_date ASC
                                                LIMIT 365
                    """);

            // target cần query lại vì đã không lưu ở trên — tái dùng dv nhưng cần target riêng
            List<Map<String, Object>> rawPoints = bindGlobalFilters(
                    client.sql(queryBuilder2.toString())
                            .param("dataSourceId", request.dataSourceId())
                            .param("metric", metric),
                    filterRequest)
                    .query((rs, rowNum) -> Map.<String, Object>of(
                            "label", rs.getDate("point_date").toString(),
                            "target", rs.getDouble("target_value")
                    ))
                    .list();
            java.util.Map<String, Double> targetMap = new java.util.HashMap<>();
            for (Map<String, Object> p : rawPoints) {
                targetMap.put(p.get("label").toString(), ((Number) p.get("target")).doubleValue());
            }
            List<Double> target = labels.stream().map(l -> targetMap.getOrDefault(l, 0.0)).toList();

            String yUnit = metric.contains("revenue") || metric.contains("cost") ? "currency" : "count";
            return Map.of(
                    "labels", labels,
                    "series", List.of(
                            Map.of("name", "actual", "data", actual),
                            Map.of("name", "target", "data", target)
                    ),
                    "yUnit", yUnit
            );
        }

        // Nhiều metric → mỗi metric = 1 series
        List<Map<String, Object>> series = new java.util.ArrayList<>();
        for (String metric : metrics) {
            java.util.Map<String, Double> dv = metricDateMap.get(metric);
            List<Double> values = labels.stream().map(l -> dv.getOrDefault(l, 0.0)).toList();
            series.add(Map.of("name", metric, "data", values));
        }

        String firstMetric = metrics.get(0);
        String yUnit = firstMetric.contains("revenue") || firstMetric.contains("cost") ? "currency" : "count";

        return Map.of(
                "labels", labels,
                "series", series,
                "yUnit", yUnit
        );
    }

    private Map<String, Object> buildCategoryPayload(DataSourceEntity entity, DataSourceQueryRequest request) {
        JdbcClient client = createJdbcClient(entity);
        String metric = metricName(request);

        StringBuilder queryBuilder = new StringBuilder();
        List<FilterRequest> filterRequest = request.filters().stream().filter((f) -> f.dashboardWidgetIds()
                .contains(request.widgetId()) && f.targetTable().equals("analytics_category_values")).toList();
        queryBuilder.append("""
                        SELECT dimension_label, value
                        FROM analytics_category_values
                        WHERE data_source_id = :dataSourceId AND metric_code = :metric
                """);

        if(!filterRequest.isEmpty()) {
            for (FilterRequest filter : filterRequest) {
                if (filter.value() != null) {
                    queryBuilder.append(
                            entity.getType().equals("postgresql") ? buildConditionalQueryWithPostgres(filter)
                                    : buildConditionalQueryWithClickhouse(filter)
                    );
                }
            }
        }
        queryBuilder.append(" ").append("""
                        ORDER BY value DESC
                        LIMIT 8
                """);

        List<Map<String, Object>> rows = bindGlobalFilters(
                client.sql(queryBuilder.toString())
                        .param("dataSourceId", request.dataSourceId())
                        .param("metric", metric),
                filterRequest)
                .query((rs, rowNum) -> Map.<String, Object>of(
                        "label", rs.getString("dimension_label"),
                        "value", rs.getDouble("value")
                ))
                .list();

        List<String> labels = rows.stream().map(item -> item.get("label").toString()).toList();
        List<Double> values = rows.stream().map(item -> ((Number) item.get("value")).doubleValue()).toList();

        return Map.of(
                "labels", labels,
                "values", values,
                "unit", metric.contains("revenue") ? "currency" : "count"
        );
    }

    private Map<String, Object> buildTablePayload(DataSourceEntity entity, DataSourceQueryRequest request) {
        JdbcClient client = createJdbcClient(entity);
        String dataset = datasetName(request, "top_products");


        List<String> columns = List.of("name", "value", "trend", "owner", "updatedAt");
        List<FilterRequest> filterRequest = request.filters().stream().filter((f) -> f.dashboardWidgetIds()
                .contains(request.widgetId()) && f.targetTable().equals("analytics_category_values")).toList();

        StringBuilder queryBuilder = new StringBuilder();
        queryBuilder.append("""
                        SELECT name, value, trend, owner, updated_at
                        FROM analytics_table_rows
                        WHERE data_source_id = :dataSourceId AND dataset_code = :dataset
                """);

        if(!filterRequest.isEmpty()) {
            for (FilterRequest filter : filterRequest) {
                if (filter.value() != null) {
                    queryBuilder.append(
                            entity.getType().equals("postgresql") ? buildConditionalQueryWithPostgres(filter)
                                    : buildConditionalQueryWithClickhouse(filter)
                    );
                }
            }
        }
        queryBuilder.append(" ").append("""
                        ORDER BY value DESC
                        LIMIT 10
                """);

        List<Map<String, Object>> rows = bindGlobalFilters(
                client.sql(queryBuilder.toString())
                        .param("dataSourceId", request.dataSourceId())
                        .param("dataset", dataset),
                filterRequest)
                .query((rs, rowNum) -> {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("name", rs.getString("name"));
                    row.put("value", rs.getDouble("value"));
                    row.put("trend", rs.getDouble("trend"));
                    row.put("owner", rs.getString("owner"));
                    Timestamp timestamp = rs.getTimestamp("updated_at");
                    row.put("updatedAt", timestamp == null ? null : timestamp.toInstant().toString());
                    return row;
                })
                .list();

        return Map.of(
                "columns", columns,
                "rows", rows
        );
    }

    private Map<String, Object> buildListPayload(DataSourceEntity entity, DataSourceQueryRequest request) {
        JdbcClient client = createJdbcClient(entity);
        String dataset = datasetName(request, "services");

        StringBuilder queryBuilder = new StringBuilder();
        List<FilterRequest> filterRequest = request.filters().stream().filter((f) -> f.dashboardWidgetIds()
                .contains(request.widgetId()) && f.targetTable().equals("analytics_list_items")).toList();
        queryBuilder.append("""
                        SELECT label, value, status
                        FROM analytics_list_items
                        WHERE data_source_id = :dataSourceId AND dataset_code = :dataset
                """);

        if(!filterRequest.isEmpty()) {
            for (FilterRequest filter : filterRequest) {
                if (filter.value() != null) {
                    queryBuilder.append(
                            entity.getType().equals("postgresql") ? buildConditionalQueryWithPostgres(filter)
                                    : buildConditionalQueryWithClickhouse(filter)
                    );
                }
            }
        }
        queryBuilder.append(" ").append("""
                        ORDER BY sort_order ASC
                        LIMIT 20
                """);

        List<Map<String, Object>> items = bindGlobalFilters(
                client.sql(queryBuilder.toString())
                        .param("dataSourceId", request.dataSourceId())
                        .param("dataset", dataset),
                filterRequest)
                .query((rs, rowNum) -> Map.<String, Object>of(
                        "label", rs.getString("label"),
                        "value", rs.getDouble("value"),
                        "status", rs.getString("status")
                ))
                .list();

        return Map.of("items", items);
    }

    private String datasetName(DataSourceQueryRequest request, String defaultValue) {
        if (request.queryConfig() == null) {
            return defaultValue;
        }
        Object dataset = request.queryConfig().get("dataset");
        if (dataset == null || dataset.toString().isBlank()) {
            return defaultValue;
        }
        return dataset.toString();
    }

    private Map<String, Object> buildApiPayload(DataSourceEntity entity,
                                                DataSourceQueryRequest request,
                                                String shape) {
        Map<String, Object> mapping = parseMap(entity.getFieldMappingJson());
        String apiUrl = stringValue(entity.getJdbcUrl());
        if (apiUrl.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "API URL is required for api datasource");
        }

        String method = stringValue(mapping.get("apiMethod"));
        if (method.isBlank()) {
            method = "GET";
        }
        method = method.toUpperCase(Locale.ROOT);

        String apiBody = null;
        if (request.queryConfig() != null && request.queryConfig().get("apiBody") != null) {
            apiBody = toJsonValue(request.queryConfig().get("apiBody"));
        }

        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(apiUrl))
                .timeout(Duration.ofSeconds(12));

        for (Map.Entry<String, String> header : headerMap(mapping.get("apiHeaders")).entrySet()) {
            builder.header(header.getKey(), header.getValue());
        }

        HttpRequest httpRequest = "GET".equals(method)
                ? builder.GET().build()
                : builder.method(method, apiBody == null
                        ? HttpRequest.BodyPublishers.noBody()
                        : HttpRequest.BodyPublishers.ofString(apiBody))
                .build();

        try {
            HttpResponse<String> response = HTTP_CLIENT.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                        "API query failed: " + response.statusCode());
            }

            Object rawJson = parseAny(response.body());
            List<Map<String, Object>> rows = normalizeApiRows(rawJson, mapping);

            if ("timeseries".equals(shape)) {
                return buildApiTimeseriesPayload(rows, request, mapping);
            }
            if ("category".equals(shape)) {
                return buildApiCategoryPayload(rows, request, mapping);
            }
            if ("table".equals(shape)) {
                return buildApiTablePayload(rows, mapping);
            }
            if ("list".equals(shape)) {
                return buildApiListPayload(rows, mapping);
            }
            return buildApiSinglePayload(rows, request, mapping);
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, ex.getMessage(), ex);
        }
    }

    private Object parseAny(String json) {
        if (json == null || json.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(json, Object.class);
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Invalid JSON from API", ex);
        }
    }

    private List<Map<String, Object>> normalizeApiRows(Object rawJson, Map<String, Object> mapping) {
        String dataPath = stringValue(mapping.get("apiDataPath"));
        Object extracted = dataPath.isBlank() ? rawJson : readByPath(rawJson, dataPath);

        if (extracted instanceof List<?> list) {
            return list.stream().filter(Map.class::isInstance).map(item -> castMap(item)).toList();
        }
        if (rawJson instanceof List<?> list) {
            return list.stream().filter(Map.class::isInstance).map(item -> castMap(item)).toList();
        }
        if (extracted instanceof Map<?, ?> map) {
            return List.of(castMap(map));
        }
        return List.of();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> castMap(Object value) {
        return (Map<String, Object>) value;
    }

    private Object readByPath(Object source, String pathText) {
        String path = stringValue(pathText);
        if (path.isBlank()) {
            return source;
        }

        Object current = source;
        for (String key : path.split("\\.")) {
            if (!(current instanceof Map<?, ?> currentMap)) {
                return null;
            }
            current = currentMap.get(key);
            if (current == null) {
                return null;
            }
        }
        return current;
    }

    private Map<String, Object> buildApiSinglePayload(List<Map<String, Object>> rows,
                                                      DataSourceQueryRequest request,
                                                      Map<String, Object> mapping) {
        List<Map<String, Object>> metricRows = apiMetricRows(rows, request, mapping);
        String valueField = fieldName(mapping, "valueField", "value");
        String previousField = fieldName(mapping, "previousValueField", "previous");

        Map<String, Object> first = metricRows.isEmpty() ? Map.of() : metricRows.getFirst();
        Map<String, Object> second = metricRows.size() > 1 ? metricRows.get(1) : Map.of();
        double currentValue = parseNumber(first.get(valueField), 0);

        return Map.of(
                "title", metricName(request),
                "value", currentValue,
                "previous", parseNumber(first.get(previousField), parseNumber(second.get(valueField), currentValue)),
                "unit", fieldName(mapping, "unit", "count")
        );
    }

    private Map<String, Object> buildApiTimeseriesPayload(List<Map<String, Object>> rows,
                                                          DataSourceQueryRequest request,
                                                          Map<String, Object> mapping) {
        String dateField = fieldName(mapping, "dateField", "date");
        String valueField = fieldName(mapping, "valueField", "value");
        String metricField = fieldName(mapping, "metricField", "metric");
        String targetField = fieldName(mapping, "targetValueField", "target");
        List<String> metrics = metricNames(request);

        java.util.Set<String> labelsSet = new java.util.HashSet<>();
        Map<String, Map<String, Double>> byMetric = new LinkedHashMap<>();
        for (String metric : metrics) {
            byMetric.put(metric, new LinkedHashMap<>());
        }
        Map<String, Double> targetMap = new LinkedHashMap<>();

        for (Map<String, Object> row : rows) {
            String rawDate = stringValue(row.get(dateField));
            String label = rawDate.length() >= 10 ? rawDate.substring(0, 10) : rawDate;
            if (label.isBlank()) {
                continue;
            }
            labelsSet.add(label);

            String rowMetric = stringValue(row.get(metricField));
            if (rowMetric.isBlank()) {
                rowMetric = metrics.getFirst();
            }
            byMetric.computeIfAbsent(rowMetric, ignored -> new LinkedHashMap<>())
                    .put(label, parseNumber(row.get(valueField), 0));
            targetMap.put(label, parseNumber(row.get(targetField), 0));
        }

        List<String> labels = new ArrayList<>(labelsSet);
        labels.sort(Comparator.naturalOrder());

        List<Map<String, Object>> series = new ArrayList<>();
        for (String metric : metrics) {
            Map<String, Double> values = byMetric.getOrDefault(metric, Map.of());
            List<Double> data = labels.stream().map(label -> values.getOrDefault(label, 0.0)).toList();
            series.add(Map.of("name", metric, "data", data));
        }

        if (metrics.size() == 1) {
            List<Double> target = labels.stream().map(label -> targetMap.getOrDefault(label, 0.0)).toList();
            series.add(Map.of("name", "target", "data", target));
        }

        return Map.of(
                "labels", labels,
                "series", series,
                "yUnit", fieldName(mapping, "unit", "count")
        );
    }

    private Map<String, Object> buildApiCategoryPayload(List<Map<String, Object>> rows,
                                                        DataSourceQueryRequest request,
                                                        Map<String, Object> mapping) {
        List<Map<String, Object>> metricRows = apiMetricRows(rows, request, mapping);
        String labelField = fieldName(mapping, "labelField", "label");
        String valueField = fieldName(mapping, "valueField", "value");

        List<String> labels = metricRows.stream()
                .map(row -> {
                    String label = stringValue(row.get(labelField));
                    if (!label.isBlank()) {
                        return label;
                    }
                    String fallback = stringValue(row.get("name"));
                    return fallback.isBlank() ? "Unknown" : fallback;
                })
                .toList();

        List<Double> values = metricRows.stream().map(row -> parseNumber(row.get(valueField), 0)).toList();

        return Map.of(
                "labels", labels,
                "values", values,
                "unit", fieldName(mapping, "unit", "count")
        );
    }

    private Map<String, Object> buildApiTablePayload(List<Map<String, Object>> rows, Map<String, Object> mapping) {
        int limit = (int) Math.round(parseNumber(mapping.get("tableLimit"), 20));
        if (limit < 1) {
            limit = 20;
        }
        List<Map<String, Object>> sliced = rows.stream().limit(limit).toList();
        List<String> columns = sliced.isEmpty() ? List.of() : new ArrayList<>(sliced.getFirst().keySet());

        return Map.of(
                "columns", columns,
                "rows", sliced
        );
    }

    private Map<String, Object> buildApiListPayload(List<Map<String, Object>> rows, Map<String, Object> mapping) {
        String labelField = fieldName(mapping, "labelField", "label");
        String valueField = fieldName(mapping, "valueField", "value");
        String statusField = fieldName(mapping, "statusField", "status");

        List<Map<String, Object>> items = rows.stream().limit(30).map(row -> {
            String label = stringValue(row.get(labelField));
            if (label.isBlank()) {
                String fallback = stringValue(row.get("name"));
                label = fallback.isBlank() ? "Unknown" : fallback;
            }
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label", label);
            item.put("value", parseNumber(row.get(valueField), 0));
            item.put("status", stringValue(row.get(statusField)).isBlank() ? "healthy" : stringValue(row.get(statusField)));
            return item;
        }).toList();

        return Map.of("items", items);
    }

    private List<Map<String, Object>> apiMetricRows(List<Map<String, Object>> rows,
                                                    DataSourceQueryRequest request,
                                                    Map<String, Object> mapping) {
        String metricField = fieldName(mapping, "metricField", "metric");
        String metric = metricName(request);
        List<Map<String, Object>> filtered = rows.stream()
                .filter(row -> metric.equals(stringValue(row.get(metricField))))
                .toList();
        return filtered.isEmpty() ? rows : filtered;
    }

    private String fieldName(Map<String, Object> mapping, String key, String fallback) {
        String value = stringValue(mapping.get(key));
        return value.isBlank() ? fallback : value;
    }

    private Map<String, String> headerMap(Object value) {
        if (!(value instanceof Map<?, ?> map)) {
            return Map.of();
        }
        Map<String, String> headers = new LinkedHashMap<>();
        for (Map.Entry<?, ?> entry : map.entrySet()) {
            String key = entry.getKey() == null ? "" : entry.getKey().toString().trim();
            if (key.isBlank()) {
                continue;
            }
            headers.put(key, entry.getValue() == null ? "" : entry.getValue().toString());
        }
        return headers;
    }

    private String stringValue(Object value) {
        return value == null ? "" : value.toString().trim();
    }

    private double parseNumber(Object value, double fallback) {
        if (value == null) {
            return fallback;
        }
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        try {
            return Double.parseDouble(value.toString());
        } catch (Exception ex) {
            return fallback;
        }
    }

    private String toJsonValue(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid apiBody JSON", ex);
        }
    }

    private DataSourceEntity mustExist(String id) {
        return dataSourceRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Data source not found"));
    }

    private DataSourceDetailResponse toDetail(DataSourceEntity entity) {
        return new DataSourceDetailResponse(
                entity.getId(),
                entity.getName(),
                entity.getType(),
                entity.getStatus(),
                entity.getJdbcUrl(),
                entity.getUsername(),
                parseMap(entity.getFieldMappingJson())
        );
    }

    private Map<String, Object> parseMap(String json) {
        if (json == null || json.isBlank()) {
            return Map.of();
        }
        try {
            return objectMapper.readValue(json, MAP_TYPE);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot parse json", ex);
        }
    }

    private String toJson(Map<String, Object> value) {
        try {
            return objectMapper.writeValueAsString(value == null ? Map.of() : value);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot serialize json", ex);
        }
    }

    private JdbcClient createJdbcClient(DataSourceEntity entity) {
        if (entity.getJdbcUrl() == null || entity.getJdbcUrl().isBlank()) {
            return JdbcClient.create(jdbcTemplate);
        }

        DriverManagerDataSource dynamic = new DriverManagerDataSource();
        dynamic.setDriverClassName(getJdbcDriverClassName(entity.getType()));
        dynamic.setUrl(entity.getJdbcUrl());
        dynamic.setUsername(entity.getUsername());
        dynamic.setPassword(entity.getPassword());

        return JdbcClient.create(dynamic);
    }

    private String getJdbcDriverClassName(String typeDataSouce) {
        return switch (typeDataSouce) {
            case "postgresql" -> "org.postgresql.Driver";
            case "clickhouse" -> "com.clickhouse.jdbc.ClickHouseDriver";
            default -> throw new IllegalStateException("Unknown type: " + typeDataSouce);
        };
    }

    private String buildConditionalQueryWithPostgres(FilterRequest filterRequest) {
        String field = filterRequest.targetField();

        return switch (filterRequest.type()) {
            case "equals"             -> " AND " + field + " = :" + field;
            case "less-than"          -> " AND " + field + " < :" + field;
            case "less-than-equals"   -> " AND " + field + " <= :" + field;
            case "greater-than"       -> " AND " + field + " > :" + field;
            case "greater-than-equals"-> " AND " + field + " >= :" + field;
            case "in"    -> " AND " + field + " IN (:" + field + ")";
            case "range" -> " AND " + field + " BETWEEN :" + field + "_from"
                    + " AND :" + field + "_to";
            default -> throw new IllegalStateException("Unknown filter type: " + filterRequest.type());
        };
    }

    private String buildConditionalQueryWithClickhouse(FilterRequest filterRequest) {
        String field = filterRequest.targetField();

        return switch (filterRequest.type()) {
            case "equals"             -> " AND " + field + " = :" + field;
            case "less-than"          -> " AND " + field + " < :" + field;
            case "less-than-equals"   -> " AND " + field + " <= :" + field;
            case "greater-than"       -> " AND " + field + " > :" + field;
            case "greater-than-equals"-> " AND " + field + " >= :" + field;
            case "in"    -> " AND " + field + " IN (:" + field + ")";
            case "range" -> " AND " + field + " BETWEEN :" + field + "_from"
                    + " AND :" + field + "_to";
            default -> throw new IllegalStateException("Unknown filter type: " + filterRequest.type());
        };
    }
}

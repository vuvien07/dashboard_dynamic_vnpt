package com.dashboard.backend.modules.dashboard.service;

import com.dashboard.backend.modules.dashboard.dto.*;
import com.dashboard.backend.modules.dashboard.entity.*;
import com.dashboard.backend.modules.dashboard.repository.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class DashboardService {

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final DashboardRepository dashboardRepository;
    private final DashboardWidgetRepository dashboardWidgetRepository;
    private final WidgetLayoutRepository widgetLayoutRepository;
    private final FilterOptionRepository filterOptionRepository;
    private final FilterRepository filterRepository;
    private final FilterLayoutRepository filterLayoutRepository;
    private final ObjectMapper objectMapper;
    private final JdbcTemplate jdbcTemplate;
    private final FilterGroupWidgetRepository filterGroupWidgetRepository;

    public DashboardService(DashboardRepository dashboardRepository,
                            DashboardWidgetRepository dashboardWidgetRepository,
                            WidgetLayoutRepository widgetLayoutRepository, FilterOptionRepository filterOptionRepository, FilterRepository filterRepository, FilterLayoutRepository filterLayoutRepository,
                            ObjectMapper objectMapper, JdbcTemplate jdbcTemplate, FilterGroupWidgetRepository filterGroupWidgetRepository) {
        this.dashboardRepository = dashboardRepository;
        this.dashboardWidgetRepository = dashboardWidgetRepository;
        this.widgetLayoutRepository = widgetLayoutRepository;
        this.filterOptionRepository = filterOptionRepository;
        this.filterRepository = filterRepository;
        this.filterLayoutRepository = filterLayoutRepository;
        this.objectMapper = objectMapper;
        this.jdbcTemplate = jdbcTemplate;
        this.filterGroupWidgetRepository = filterGroupWidgetRepository;
    }

    public List<DashboardListItemResponse> listDashboards() {
        return dashboardRepository.findAllByOrderByUpdatedAtDesc().stream()
                .map(item -> new DashboardListItemResponse(
                        item.getId(),
                        item.getName(),
                        item.getVisibility(),
                        item.getStatus(),
                        item.getUpdatedAt().toString()
                ))
                .toList();
    }

    public List<OptionListItemResponse> listOptions(String type) {
        return filterOptionRepository.findByType(type).stream()
                .map(item -> new OptionListItemResponse(item.getCode(), item.getName()))
                .toList();
    }

    @Transactional
    public DashboardMeta createDashboard(CreateDashboardRequest request) {
        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
        DashboardEntity dashboard = new DashboardEntity();
        dashboard.setId("db-" + UUID.randomUUID());
        dashboard.setName(request.name());
        dashboard.setDescription(request.description());
        dashboard.setVisibility(request.visibility() == null || request.visibility().isBlank() ? "private" : request.visibility());
        dashboard.setStatus("draft");
        dashboard.setCurrentVersionNo(1);
        dashboard.setCreatedAt(now);
        dashboard.setUpdatedAt(now);
        dashboardRepository.save(dashboard);

        return new DashboardMeta(dashboard.getId(), dashboard.getName(), dashboard.getCurrentVersionNo());
    }

    @Transactional
    public void deleteDashboard(String dashboardId) {
        DashboardEntity dashboard = mustExist(dashboardId);
        widgetLayoutRepository.deleteByDashboardId(dashboardId);
        dashboardWidgetRepository.deleteByDashboardId(dashboardId);
        dashboardRepository.delete(dashboard);
    }

    @Transactional
    public DashboardConfigResponse getConfig(String dashboardId) {
        DashboardEntity dashboard = mustExist(dashboardId);
        List<DashboardWidgetEntity> widgetEntities = dashboardWidgetRepository.findByDashboardId(dashboardId);
        List<WidgetLayoutEntity> layoutEntities = widgetLayoutRepository.findByDashboardId(dashboardId);
        List<FilterLayoutEntity> filterLayoutEntityEntities = filterLayoutRepository.findByDashboardId(dashboardId);
        List<FilterEntity> filterEntityEntities = filterRepository.findByDashboardId(dashboardId);

        List<WidgetConfigItem> widgets = widgetEntities.stream().map(this::toWidgetDto).toList();
        List<FilterConfigItem> filters = filterEntityEntities.stream().map(this::toFilterDto).toList();
        Map<String, List<LayoutItem>> layouts = toLayoutMap(layoutEntities);
        Map<String, List<LayoutItem>> filterLayouts = toFilterLayoutMap(filterLayoutEntityEntities);

        return new DashboardConfigResponse(
                new DashboardMeta(dashboard.getId(), dashboard.getName(), dashboard.getCurrentVersionNo()),
                widgets,
                layouts,
                filterLayouts,
                filters
        );
    }

    @Transactional
    public SaveDashboardConfigResponse saveConfig(String dashboardId, SaveDashboardConfigRequest request) {
        DashboardEntity dashboard = mustExist(dashboardId);

        if (!dashboard.getCurrentVersionNo().equals(request.expectedVersionNo())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "VERSION_CONFLICT");
        }

        filterGroupWidgetRepository.deleteByFilterIds(request.filterIds());
        widgetLayoutRepository.deleteByDashboardId(dashboardId);
        dashboardWidgetRepository.deleteByDashboardId(dashboardId);
        filterLayoutRepository.deleteByDashboardId(dashboardId);
        filterRepository.deleteByDashboardId(dashboardId);

        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
        Map<String, DashboardWidgetEntity> widgetsById = new HashMap<>();
        Map<String, FilterEntity> filtersById = new HashMap<>();

        List<DashboardWidgetEntity> widgetsToSave = new ArrayList<>();
        for (WidgetConfigItem item : request.widgets()) {
            String widgetId = item.id() == null || item.id().isBlank() ? "w-" + UUID.randomUUID() : item.id();
            DashboardWidgetEntity entity = new DashboardWidgetEntity();
            entity.setId(widgetId);
            entity.setDashboard(dashboard);
            entity.setWidgetTypeCode(item.widgetTypeCode());
            entity.setTitle(item.title());
            entity.setPropsJson(toJson(item.props()));
            entity.setDataSourceId(item.dataSourceId());
            entity.setQueryConfigJson(toJson(item.queryConfig()));
            entity.setRefreshIntervalSec(item.refreshIntervalSec());
            entity.setCreatedAt(now);
            entity.setUpdatedAt(now);
            widgetsToSave.add(entity);
            widgetsById.put(widgetId, entity);
        }
        dashboardWidgetRepository.saveAll(widgetsToSave);

        List<WidgetLayoutEntity> layoutsToSave = new ArrayList<>();
        for (Map.Entry<String, List<LayoutItem>> entry : request.layouts().entrySet()) {
            String breakpoint = entry.getKey();
            for (LayoutItem item : entry.getValue()) {
                DashboardWidgetEntity widgetEntity = widgetsById.get(item.widgetId());
                if (widgetEntity == null) {
                    continue;
                }
                WidgetLayoutEntity layout = new WidgetLayoutEntity();
                layout.setId("lay-" + UUID.randomUUID());
                layout.setDashboard(dashboard);
                layout.setWidget(widgetEntity);
                layout.setBreakpoint(breakpoint);
                layout.setX(item.x());
                layout.setY(item.y());
                layout.setW(item.w());
                layout.setH(item.h());
                layout.setIsStatic(item.staticLayout());
                layoutsToSave.add(layout);
            }
        }
        widgetLayoutRepository.saveAll(layoutsToSave);

        for (FilterConfigItem item : request.filters()) {
            String filterId = item.id() == null || item.id().isBlank() ? "f-" + UUID.randomUUID() : item.id();
            FilterEntity filterEntity = new FilterEntity();
            filterEntity.setId(filterId);
            filterEntity.setDashboard(dashboard);
            filterEntity.setLabel(item.label());
            filterEntity.setPlaceholder(item.placeholder());
            filterEntity.setType(item.type());
            filterEntity.setTargetTable(item.targetTable());
            filterEntity.setTargetField(item.targetField());
            filterEntity.setFieldType(item.fieldType());
            filterRepository.save(filterEntity);
            List<FilterGroupWidgetEntity> filterGroupWidgetEntities = new ArrayList<>();
            for (String widgetId : item.dashboardWidgetIds()) {
                FilterGroupWidgetEntity filterGroupWidgetEntity = new FilterGroupWidgetEntity();
                filterGroupWidgetEntity.setId("fgw-" + UUID.randomUUID());
                filterGroupWidgetEntity.setFilterEntity(filterEntity);
                filterGroupWidgetEntity.setDashboardWidget(widgetsById.get(widgetId));
                filterGroupWidgetEntities.add(filterGroupWidgetEntity);
            }
            filterGroupWidgetRepository.saveAll(filterGroupWidgetEntities);
            filtersById.put(filterId, filterEntity);
        }

        List<FilterLayoutEntity> filterLayoutsToSave = new ArrayList<>();
        for (Map.Entry<String, List<LayoutItem>> entry : request.filterLayouts().entrySet()) {
            String breakpoint = entry.getKey();
            for (LayoutItem item : entry.getValue()) {
                FilterEntity filterEntity = filtersById.get(item.widgetId());
                if (filterEntity == null) {
                    continue;
                }
                FilterLayoutEntity layout = new FilterLayoutEntity();
                layout.setId("lay-" + UUID.randomUUID());
                layout.setDashboard(dashboard);
                layout.setFilterEntity(filterEntity);
                layout.setBreakpoint(breakpoint);
                layout.setX(item.x());
                layout.setY(item.y());
                layout.setW(item.w());
                layout.setH(item.h());
                layout.setIsStatic(item.staticLayout());
                filterLayoutsToSave.add(layout);
            }
        }
        filterLayoutRepository.saveAll(filterLayoutsToSave);

        dashboard.setCurrentVersionNo(dashboard.getCurrentVersionNo() + 1);
        dashboard.setUpdatedAt(now);
        dashboardRepository.save(dashboard);

        return new SaveDashboardConfigResponse(dashboard.getCurrentVersionNo(), dashboard.getUpdatedAt().toString());
    }

    private DashboardEntity mustExist(String dashboardId) {
        return dashboardRepository.findById(dashboardId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Dashboard not found"));
    }

    private WidgetConfigItem toWidgetDto(DashboardWidgetEntity entity) {
        return new WidgetConfigItem(
                entity.getId(),
                entity.getWidgetTypeCode(),
                entity.getTitle(),
                parseMap(entity.getPropsJson()),
                entity.getDataSourceId(),
                parseMap(entity.getQueryConfigJson()),
                entity.getRefreshIntervalSec()
        );
    }

    private FilterConfigItem toFilterDto(FilterEntity entity) {
        return new FilterConfigItem(
                entity.getId(),
                entity.getLabel(),
                entity.getPlaceholder(),
                entity.getType(),
                entity.getTargetTable(),
                entity.getTargetField(),
                entity.getFieldType(),
                entity.getFilterGroupWidgetEntities().stream().map(FilterGroupWidgetEntity::getDashboardWidget)
                        .map(DashboardWidgetEntity::getId).toList()
        );
    }

    private Map<String, List<LayoutItem>> toLayoutMap(List<WidgetLayoutEntity> layoutEntities) {
        Map<String, List<LayoutItem>> layouts = new LinkedHashMap<>();
        for (WidgetLayoutEntity entity : layoutEntities) {
            layouts.computeIfAbsent(entity.getBreakpoint(), ignored -> new ArrayList<>())
                    .add(new LayoutItem(
                            entity.getWidget().getId(),
                            entity.getX(),
                            entity.getY(),
                            entity.getW(),
                            entity.getH(),
                            Boolean.TRUE.equals(entity.getIsStatic())
                    ));
        }
        return layouts;
    }

    private Map<String, List<LayoutItem>> toFilterLayoutMap(List<FilterLayoutEntity> layoutEntities) {
        Map<String, List<LayoutItem>> layouts = new LinkedHashMap<>();
        for (FilterLayoutEntity entity : layoutEntities) {
            layouts.computeIfAbsent(entity.getBreakpoint(), ignored -> new ArrayList<>())
                    .add(new LayoutItem(
                            entity.getFilterEntity().getId(),
                            entity.getX(),
                            entity.getY(),
                            entity.getW(),
                            entity.getH(),
                            Boolean.TRUE.equals(entity.getIsStatic())
                    ));
        }
        return layouts;
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

    public Map<String, List<AnalyticSchemaItemResponse>> listAnalyticTablesAndColumns() {
        Map<String, List<AnalyticSchemaItemResponse>> result = new HashMap<>();
        jdbcTemplate.query("""
                SELECT
                    t.table_name,
                    c.column_name,
                    c.data_type
                FROM information_schema.tables t
                JOIN information_schema.columns c
                    ON c.table_name = t.table_name
                    AND c.table_schema = t.table_schema
                WHERE t.table_schema = 'public'
                    AND t.table_name LIKE 'analytics%'
                ORDER BY t.table_name, c.ordinal_position
                """,
                (row) -> {
                    String tableName = row.getString("table_name");
                    String columnName = row.getString("column_name");
                    String dataType = row.getString("data_type");
                    AnalyticSchemaItemResponse item = new AnalyticSchemaItemResponse(columnName, dataType);
                    result.computeIfAbsent(tableName, ignored -> new ArrayList<>()).add(item);
                }
        );
        return result;
    }

    public List<Object> getValuesFromTable(String tableName, String columnName) {
        String sql = "SELECT DISTINCT " + columnName
                + " FROM " + tableName
                + " ORDER BY " + columnName
                + " LIMIT 200";
        return jdbcTemplate.queryForList(sql, Object.class);
    }
}

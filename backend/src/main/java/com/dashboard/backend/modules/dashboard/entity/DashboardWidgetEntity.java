package com.dashboard.backend.modules.dashboard.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;

@Entity
@Table(name = "dashboard_widgets")
public class DashboardWidgetEntity {

    @Id
    @Column(length = 80, nullable = false)
    private String id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "dashboard_id")
    private DashboardEntity dashboard;

    @Column(name = "widget_type_code", length = 50, nullable = false)
    private String widgetTypeCode;

    @Column(length = 150)
    private String title;

    @Column(name = "props_json", columnDefinition = "text", nullable = false)
    private String propsJson;

    @Column(name = "data_source_id", length = 80)
    private String dataSourceId;

    @Column(name = "query_config_json", columnDefinition = "text")
    private String queryConfigJson;

    @Column(name = "refresh_interval_sec")
    private Integer refreshIntervalSec;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public DashboardEntity getDashboard() {
        return dashboard;
    }

    public void setDashboard(DashboardEntity dashboard) {
        this.dashboard = dashboard;
    }

    public String getWidgetTypeCode() {
        return widgetTypeCode;
    }

    public void setWidgetTypeCode(String widgetTypeCode) {
        this.widgetTypeCode = widgetTypeCode;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getPropsJson() {
        return propsJson;
    }

    public void setPropsJson(String propsJson) {
        this.propsJson = propsJson;
    }

    public String getDataSourceId() {
        return dataSourceId;
    }

    public void setDataSourceId(String dataSourceId) {
        this.dataSourceId = dataSourceId;
    }

    public String getQueryConfigJson() {
        return queryConfigJson;
    }

    public void setQueryConfigJson(String queryConfigJson) {
        this.queryConfigJson = queryConfigJson;
    }

    public Integer getRefreshIntervalSec() {
        return refreshIntervalSec;
    }

    public void setRefreshIntervalSec(Integer refreshIntervalSec) {
        this.refreshIntervalSec = refreshIntervalSec;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}

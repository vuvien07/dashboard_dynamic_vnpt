package com.dashboard.backend.modules.widget.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "widget_types")
public class WidgetTypeEntity {

    @Id
    @Column(length = 80, nullable = false)
    private String id;

    @Column(length = 50, nullable = false, unique = true)
    private String code;

    @Column(length = 120, nullable = false)
    private String name;

    @Column(length = 50, nullable = false)
    private String category;

    @Column(length = 80)
    private String icon;

    @Column(name = "props_schema_json", columnDefinition = "text", nullable = false)
    private String propsSchemaJson;

    @Column(name = "default_props_json", columnDefinition = "text", nullable = false)
    private String defaultPropsJson;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public String getPropsSchemaJson() {
        return propsSchemaJson;
    }

    public void setPropsSchemaJson(String propsSchemaJson) {
        this.propsSchemaJson = propsSchemaJson;
    }

    public String getDefaultPropsJson() {
        return defaultPropsJson;
    }

    public void setDefaultPropsJson(String defaultPropsJson) {
        this.defaultPropsJson = defaultPropsJson;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }
}

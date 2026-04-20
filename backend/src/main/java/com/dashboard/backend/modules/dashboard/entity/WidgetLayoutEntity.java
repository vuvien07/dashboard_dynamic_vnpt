package com.dashboard.backend.modules.dashboard.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "widget_layouts")
public class WidgetLayoutEntity {

    @Id
    @Column(length = 80, nullable = false)
    private String id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "dashboard_id")
    private DashboardEntity dashboard;

    @ManyToOne(optional = false)
    @JoinColumn(name = "widget_id")
    private DashboardWidgetEntity widget;

    @Column(length = 20, nullable = false)
    private String breakpoint;

    @Column(nullable = false)
    private Integer x;

    @Column(nullable = false)
    private Integer y;

    @Column(nullable = false)
    private Integer w;

    @Column(nullable = false)
    private Integer h;

    @Column(name = "is_static", nullable = false)
    private Boolean isStatic;

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

    public DashboardWidgetEntity getWidget() {
        return widget;
    }

    public void setWidget(DashboardWidgetEntity widget) {
        this.widget = widget;
    }

    public String getBreakpoint() {
        return breakpoint;
    }

    public void setBreakpoint(String breakpoint) {
        this.breakpoint = breakpoint;
    }

    public Integer getX() {
        return x;
    }

    public void setX(Integer x) {
        this.x = x;
    }

    public Integer getY() {
        return y;
    }

    public void setY(Integer y) {
        this.y = y;
    }

    public Integer getW() {
        return w;
    }

    public void setW(Integer w) {
        this.w = w;
    }

    public Integer getH() {
        return h;
    }

    public void setH(Integer h) {
        this.h = h;
    }

    public Boolean getIsStatic() {
        return isStatic;
    }

    public void setIsStatic(Boolean aStatic) {
        isStatic = aStatic;
    }
}

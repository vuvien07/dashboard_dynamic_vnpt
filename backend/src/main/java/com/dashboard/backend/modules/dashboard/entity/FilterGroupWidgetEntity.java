package com.dashboard.backend.modules.dashboard.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "filter_group_widgets")
public class FilterGroupWidgetEntity {
    @Id
    @Size(max = 80)
    @Column(name = "id", nullable = false, length = 80)
    private String id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "filter_id", nullable = false)
    private FilterEntity filterEntity;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dashboard_widget_id", nullable = false)
    private DashboardWidgetEntity dashboardWidget;

}
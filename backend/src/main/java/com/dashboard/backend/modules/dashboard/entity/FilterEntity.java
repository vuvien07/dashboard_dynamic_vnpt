package com.dashboard.backend.modules.dashboard.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.util.LinkedHashSet;
import java.util.Set;

@Getter
@Setter
@Entity
@Table(name = "filters")
public class FilterEntity {
    @Id
    @Size(max = 80)
    @Column(name = "id", nullable = false, length = 80)
    private String id;

    @Size(max = 255)
    @NotNull
    @Column(name = "label", nullable = false)
    private String label;

    @Size(max = 255)
    @NotNull
    @Column(name = "placeholder", nullable = false)
    private String placeholder;

    @Size(max = 255)
    @NotNull
    @Column(name = "type", nullable = false)
    private String type;

    @Size(max = 80)
    @NotNull
    @Column(name = "target_table", nullable = false, length = 80)
    private String targetTable;

    @Size(max = 80)
    @NotNull
    @Column(name = "target_field", nullable = false, length = 80)
    private String targetField;

    @Size(max = 80)
    @NotNull
    @Column(name = "field_type", nullable = false, length = 80)
    private String fieldType;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dashboard_id", nullable = false)
    private DashboardEntity dashboard;

    @OneToMany(mappedBy = "filterEntity")
    private Set<FilterGroupWidgetEntity> filterGroupWidgetEntities = new LinkedHashSet<>();

    @OneToMany(mappedBy = "filterEntity")
    private Set<FilterLayoutEntity> filterLayoutEntities = new LinkedHashSet<>();
}
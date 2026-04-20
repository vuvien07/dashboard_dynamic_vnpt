package com.dashboard.backend.modules.dashboard.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "filter_layouts")
public class FilterLayoutEntity {
    @Id
    @Size(max = 80)
    @Column(name = "id", nullable = false, length = 80)
    private String id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dashboard_id", nullable = false)
    private DashboardEntity dashboard;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "filter_id", nullable = false)
    private FilterEntity filterEntity;

    @Size(max = 20)
    @NotNull
    @Column(name = "breakpoint", nullable = false, length = 20)
    private String breakpoint;

    @NotNull
    @Column(name = "x", nullable = false)
    private Integer x;

    @NotNull
    @Column(name = "y", nullable = false)
    private Integer y;

    @NotNull
    @Column(name = "w", nullable = false)
    private Integer w;

    @NotNull
    @Column(name = "h", nullable = false)
    private Integer h;

    @NotNull
    @Column(name = "is_static", nullable = false)
    private Boolean isStatic = false;

}
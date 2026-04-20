package com.dashboard.backend.modules.dashboard.repository;

import com.dashboard.backend.modules.dashboard.entity.DashboardWidgetEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DashboardWidgetRepository extends JpaRepository<DashboardWidgetEntity, String> {
    List<DashboardWidgetEntity> findByDashboardId(String dashboardId);

    void deleteByDashboardId(String dashboardId);
}

package com.dashboard.backend.modules.dashboard.repository;

import com.dashboard.backend.modules.dashboard.entity.WidgetLayoutEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WidgetLayoutRepository extends JpaRepository<WidgetLayoutEntity, String> {
    List<WidgetLayoutEntity> findByDashboardId(String dashboardId);

    void deleteByDashboardId(String dashboardId);
}

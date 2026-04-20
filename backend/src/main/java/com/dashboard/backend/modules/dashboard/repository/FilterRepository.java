package com.dashboard.backend.modules.dashboard.repository;

import com.dashboard.backend.modules.dashboard.entity.FilterEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface FilterRepository extends JpaRepository<FilterEntity, String> {
    @Query("select f from FilterEntity f where f.dashboard.id=?1")
    List<FilterEntity> findByDashboardId(String dashboardId);

    void deleteByDashboardId(String dashboardId);
}

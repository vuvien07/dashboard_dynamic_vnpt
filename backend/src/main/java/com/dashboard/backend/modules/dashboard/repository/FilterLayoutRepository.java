package com.dashboard.backend.modules.dashboard.repository;

import com.dashboard.backend.modules.dashboard.entity.FilterLayoutEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface FilterLayoutRepository extends JpaRepository<FilterLayoutEntity, String> {
    @Query("select f from FilterLayoutEntity f where f.dashboard.id = ?1")
    List<FilterLayoutEntity> findByDashboardId(String dashboardId);

    void deleteByDashboardId(String dashboardId);
}

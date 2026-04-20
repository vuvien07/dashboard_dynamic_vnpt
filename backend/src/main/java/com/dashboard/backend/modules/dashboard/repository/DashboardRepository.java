package com.dashboard.backend.modules.dashboard.repository;

import com.dashboard.backend.modules.dashboard.entity.DashboardEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DashboardRepository extends JpaRepository<DashboardEntity, String> {
    List<DashboardEntity> findAllByOrderByUpdatedAtDesc();
}

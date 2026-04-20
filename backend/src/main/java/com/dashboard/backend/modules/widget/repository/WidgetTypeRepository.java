package com.dashboard.backend.modules.widget.repository;

import com.dashboard.backend.modules.widget.entity.WidgetTypeEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WidgetTypeRepository extends JpaRepository<WidgetTypeEntity, String> {
    List<WidgetTypeEntity> findByIsActiveTrueOrderByNameAsc();
}

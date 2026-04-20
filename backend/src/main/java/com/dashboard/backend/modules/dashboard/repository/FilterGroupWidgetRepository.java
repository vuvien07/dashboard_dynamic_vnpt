package com.dashboard.backend.modules.dashboard.repository;

import com.dashboard.backend.modules.dashboard.entity.FilterGroupWidgetEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface FilterGroupWidgetRepository extends JpaRepository<FilterGroupWidgetEntity, String> {

    @Modifying
    @Query("delete from FilterGroupWidgetEntity f where f.filterEntity.id in ?1")
    void deleteByFilterIds(List<String> filterIds);
}

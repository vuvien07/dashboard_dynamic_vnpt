package com.dashboard.backend.modules.dashboard.repository;

import com.dashboard.backend.modules.dashboard.entity.FilterOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface FilterOptionRepository extends JpaRepository<FilterOption, String> {
    @Query("SELECT f FROM FilterOption f WHERE f.type = ?1 ORDER BY f.code")
    List<FilterOption> findByType(String type);
}

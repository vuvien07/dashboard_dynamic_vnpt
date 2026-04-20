package com.dashboard.backend.modules.datasource.repository;

import com.dashboard.backend.modules.datasource.entity.DataSourceEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DataSourceRepository extends JpaRepository<DataSourceEntity, String> {
    List<DataSourceEntity> findAllByOrderByNameAsc();
}

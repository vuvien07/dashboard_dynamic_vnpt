package com.dashboard.backend.modules.datasource.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.Map;

public record DataSourceUpsertRequest(
        @NotBlank String id,
        @NotBlank String name,
        @NotBlank String type,
        @NotBlank String status,
        String jdbcUrl,
        String username,
        String password,
        Map<String, Object> fieldMapping
) {
}

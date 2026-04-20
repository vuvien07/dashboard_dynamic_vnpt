package com.dashboard.backend.modules.dashboard.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateDashboardRequest(
        @NotBlank String name,
        String description,
        String visibility
) {
}

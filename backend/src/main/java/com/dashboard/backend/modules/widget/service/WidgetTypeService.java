package com.dashboard.backend.modules.widget.service;

import com.dashboard.backend.modules.widget.dto.WidgetTypeResponse;
import com.dashboard.backend.modules.widget.entity.WidgetTypeEntity;
import com.dashboard.backend.modules.widget.repository.WidgetTypeRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class WidgetTypeService {

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final WidgetTypeRepository widgetTypeRepository;
    private final ObjectMapper objectMapper;

    public WidgetTypeService(WidgetTypeRepository widgetTypeRepository, ObjectMapper objectMapper) {
        this.widgetTypeRepository = widgetTypeRepository;
        this.objectMapper = objectMapper;
    }

    public List<WidgetTypeResponse> listActive() {
        return widgetTypeRepository.findByIsActiveTrueOrderByNameAsc().stream()
                .map(this::toResponse)
                .toList();
    }

    private WidgetTypeResponse toResponse(WidgetTypeEntity entity) {
        return new WidgetTypeResponse(
                entity.getId(),
                entity.getCode(),
                entity.getName(),
                entity.getCategory(),
                entity.getIcon(),
                parseMap(entity.getPropsSchemaJson()),
                parseMap(entity.getDefaultPropsJson())
        );
    }

    private Map<String, Object> parseMap(String json) {
        try {
            return objectMapper.readValue(json, MAP_TYPE);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot parse widget type json", ex);
        }
    }
}

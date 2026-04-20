-- Dữ liệu mẫu cho hệ thống Dashboard Y tế (PostgreSQL)
-- Domain: Healthcare / Hospital Management System
-- Safe to run multiple times (idempotent via DELETE + ON CONFLICT)

BEGIN;

-- ============================================================================
-- Dọn dẹp dữ liệu dashboard cũ (nếu có) trước khi import domain y tế
-- ============================================================================
DELETE FROM widget_layouts  WHERE dashboard_id IN ('db-sales-analytics','db-exec-overview','db-marketing-perf','db-ops-monitor','db-sales-main');
DELETE FROM dashboard_widgets WHERE dashboard_id IN ('db-sales-analytics','db-exec-overview','db-marketing-perf','db-ops-monitor','db-sales-main');
DELETE FROM dashboards WHERE id IN ('db-sales-analytics','db-exec-overview','db-marketing-perf','db-ops-monitor','db-sales-main');

-- ============================================================================
-- Widget Types - Các loại widget trực quan hóa (không đổi theo domain)
-- ============================================================================
INSERT INTO widget_types (id, code, name, category, icon, props_schema_json, default_props_json, is_active)
VALUES
    ('wt-kpi-card', 'kpi-card', 'KPI Card', 'metrics', 'chart-bar', '{"type":"object"}', '{"format":"number","showTrend":true,"trendColor":"auto"}', TRUE),
    ('wt-metric-card', 'metric-card', 'Metric Card', 'metrics', 'calculator', '{"type":"object"}', '{"decimals":2,"prefix":"","suffix":""}', TRUE),
    ('wt-gauge', 'gauge', 'Gauge Chart', 'metrics', 'speedometer', '{"type":"object"}', '{"min":0,"max":100,"showValue":true}', TRUE),
    ('wt-progress', 'progress-bar', 'Progress Bar', 'metrics', 'tasks', '{"type":"object"}', '{"showPercentage":true,"color":"primary"}', TRUE),
    ('wt-line-chart', 'line-chart', 'Line Chart', 'chart', 'chart-line', '{"type":"object"}', '{"smooth":true,"showPoints":true,"showLegend":true}', TRUE),
    ('wt-bar-chart', 'bar-chart', 'Bar Chart', 'chart', 'chart-column', '{"type":"object"}', '{"horizontal":false,"stacked":false,"showValues":false}', TRUE),
    ('wt-area-chart', 'area-chart', 'Area Chart', 'chart', 'chart-area', '{"type":"object"}', '{"stacked":false,"fillOpacity":0.6}', TRUE),
    ('wt-pie-chart', 'pie-chart', 'Pie Chart', 'chart', 'chart-pie', '{"type":"object"}', '{"showLegend":true,"donut":false,"showPercentage":true}', TRUE),
    ('wt-scatter', 'scatter-chart', 'Scatter Chart', 'chart', 'chart-scatter', '{"type":"object"}', '{"showTrendline":false,"pointSize":4}', TRUE),
    ('wt-heatmap', 'heatmap', 'Heat Map', 'chart', 'grid', '{"type":"object"}', '{"colorScheme":"blues","showValues":true}', TRUE),
    ('wt-table', 'data-table', 'Data Table', 'table', 'table', '{"type":"object"}', '{"pageSize":10,"sortable":true,"filterable":true}', TRUE),
    ('wt-list', 'list', 'List View', 'table', 'list', '{"type":"object"}', '{"showIcons":true,"compact":false}', TRUE),
    ('wt-timeline', 'timeline', 'Timeline', 'other', 'clock', '{"type":"object"}', '{"orientation":"vertical","showDates":true}', TRUE),
    ('wt-map', 'geo-map', 'Geographic Map', 'other', 'map', '{"type":"object"}', '{"zoom":3,"center":{"lat":0,"lng":0}}', TRUE)
ON CONFLICT (id) DO UPDATE SET
    code = EXCLUDED.code,
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    icon = EXCLUDED.icon,
    props_schema_json = EXCLUDED.props_schema_json,
    default_props_json = EXCLUDED.default_props_json,
    is_active = EXCLUDED.is_active;

-- ============================================================================
-- Dashboards - Hệ thống Quản lý Bệnh viện
-- ============================================================================
INSERT INTO dashboards (id, name, description, visibility, status, current_version_no, created_at, updated_at)
VALUES
    ('db-patient-mgmt',  'Tổng quan Bệnh nhân',    'Theo dõi nhập-xuất viện, công suất giường bệnh và phân bổ bệnh nhân theo khoa, loại bảo hiểm', 'private', 'published', 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('db-clinical-perf', 'Hiệu suất Lâm sàng',     'Chỉ số phẫu thuật, thời gian nằm viện trung bình, tỷ lệ tái nhập viện và công suất ICU',        'private', 'published', 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('db-pharmacy-mgmt', 'Quản lý Dược phẩm',      'Kê đơn, tồn kho thuốc, cấp phát và cảnh báo hết hàng theo nhóm dược',                          'private', 'published', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('db-hospital-ops',  'Vận hành Bệnh viện',     'Doanh thu, tỷ lệ thu hồi, công suất nhân lực, thời gian chờ và hài lòng bệnh nhân',             'private', 'published', 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET
    name               = EXCLUDED.name,
    description        = EXCLUDED.description,
    visibility         = EXCLUDED.visibility,
    status             = EXCLUDED.status,
    current_version_no = EXCLUDED.current_version_no,
    updated_at         = CURRENT_TIMESTAMP;

-- ============================================================================
-- Dashboard Widgets - Tổng quan Bệnh nhân (db-patient-mgmt)
-- ============================================================================
INSERT INTO dashboard_widgets (id, dashboard_id, widget_type_code, title, props_json, data_source_id, query_config_json, refresh_interval_sec, created_at, updated_at)
VALUES
    -- Hàng 1: KPI tóm tắt
    ('w-pt-inpatients',      'db-patient-mgmt', 'kpi-card',   'Tổng bệnh nhân nội trú',   '{"format":"number","decimals":0,"showTrend":true,"color":"#2563eb"}',                                                                                                'ds-patients', '{"metric":"total_inpatients","period":"today"}',           60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-pt-new-admissions',  'db-patient-mgmt', 'kpi-card',   'Nhập viện hôm nay',         '{"format":"number","decimals":0,"showTrend":true,"color":"#16a34a"}',                                                                                                'ds-patients', '{"metric":"new_admissions","period":"today"}',             60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-pt-discharges',      'db-patient-mgmt', 'kpi-card',   'Xuất viện hôm nay',         '{"format":"number","decimals":0,"showTrend":true,"color":"#0891b2"}',                                                                                                'ds-patients', '{"metric":"discharge_count","period":"today"}',            60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-pt-outpatient',      'db-patient-mgmt', 'kpi-card',   'Lượt khám ngoại trú',       '{"format":"number","decimals":0,"showTrend":true,"color":"#7c3aed"}',                                                                                                'ds-patients', '{"metric":"outpatient_visits","period":"today"}',          60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    -- Hàng 2: Gauge + Xu hướng
    ('w-pt-bed-occ',         'db-patient-mgmt', 'gauge',      'Công suất giường bệnh (%)', '{"min":0,"max":100,"showValue":true,"suffix":"%","thresholds":[{"value":70,"color":"#16a34a"},{"value":85,"color":"#f59e0b"},{"value":95,"color":"#dc2626"}]}',       'ds-patients', '{"metric":"bed_occupancy_rate","period":"today"}',         120, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-pt-admission-trend', 'db-patient-mgmt', 'line-chart', 'Xu hướng nhập-xuất viện (90 ngày)', '{"smooth":true,"showPoints":false,"showLegend":true,"colors":["#2563eb","#16a34a"],"yAxisFormat":"number"}',                                                'ds-patients', '{"metrics":["new_admissions","discharge_count"],"period":"90_days","granularity":"day"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    -- Hàng 3: Biểu đồ phân bổ + Bảng
    ('w-pt-dept-bar',        'db-patient-mgmt', 'bar-chart',  'Bệnh nhân theo khoa',       '{"horizontal":true,"stacked":false,"showValues":true,"colors":["#2563eb","#7c3aed","#0891b2","#16a34a","#f59e0b","#dc2626","#64748b"]}',                             'ds-patients', '{"dimension":"department","metric":"new_admissions","period":"current_month"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-pt-insurance-pie',   'db-patient-mgmt', 'pie-chart',  'Phân loại bảo hiểm',        '{"showLegend":true,"donut":true,"showPercentage":true,"innerRadius":0.55,"colors":["#2563eb","#16a34a","#f59e0b"]}',                                                'ds-patients', '{"dimension":"insurance","metric":"total_inpatients","period":"current_month"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-pt-top-diagnoses',   'db-patient-mgmt', 'data-table', 'Chẩn đoán hàng đầu',        '{"pageSize":10,"sortable":true,"filterable":false,"striped":true,"columns":[{"key":"name","label":"Chẩn đoán"},{"key":"value","label":"Số BN"},{"key":"trend","label":"Thay đổi (%)","format":"percentage"}]}', 'ds-patients', '{"dataset":"top_diagnoses","limit":10,"sort":"value_desc"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- ============================================================================
-- Dashboard Widgets - Hiệu suất Lâm sàng (db-clinical-perf)
-- ============================================================================
    -- Hàng 1: KPI + Gauge
    ('w-cl-surgeries',      'db-clinical-perf', 'kpi-card',    'Ca phẫu thuật hôm nay',        '{"format":"number","decimals":0,"showTrend":true,"color":"#7c3aed"}',                                                                                                'ds-clinical', '{"metric":"surgery_count","period":"today"}',              60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-cl-avg-los',        'db-clinical-perf', 'metric-card', 'Thời gian nằm viện TB (ngày)', '{"decimals":1,"suffix":" ngày","showTrend":true,"trendDirection":"inverse"}',                                                                                        'ds-clinical', '{"metric":"avg_length_of_stay","period":"current_month"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-cl-mortality',      'db-clinical-perf', 'metric-card', 'Tỷ lệ tử vong (%)',            '{"decimals":2,"suffix":"%","showTrend":true,"trendDirection":"inverse","color":"#dc2626"}',                                                                          'ds-clinical', '{"metric":"mortality_rate","period":"current_month"}',     300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-cl-readmission',    'db-clinical-perf', 'gauge',       'Tỷ lệ tái nhập viện (%)',      '{"min":0,"max":20,"showValue":true,"suffix":"%","decimals":1,"thresholds":[{"value":5,"color":"#16a34a"},{"value":10,"color":"#f59e0b"},{"value":15,"color":"#dc2626"}]}', 'ds-clinical', '{"metric":"readmission_rate","period":"current_month"}',  120, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-cl-icu-occ',        'db-clinical-perf', 'gauge',       'Công suất ICU (%)',             '{"min":0,"max":100,"showValue":true,"suffix":"%","decimals":0,"thresholds":[{"value":60,"color":"#16a34a"},{"value":80,"color":"#f59e0b"},{"value":90,"color":"#dc2626"}]}', 'ds-clinical', '{"metric":"icu_occupancy_rate","period":"today"}',         60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    -- Hàng 2: Xu hướng + Biểu đồ
    ('w-cl-surgery-trend',  'db-clinical-perf', 'line-chart',  'Xu hướng phẫu thuật (90 ngày)','{"smooth":true,"showPoints":false,"showLegend":true,"colors":["#7c3aed","#0891b2"]}',                                                                               'ds-clinical', '{"metrics":["surgery_count","icu_occupancy_rate"],"period":"90_days","granularity":"day"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-cl-surgery-type',   'db-clinical-perf', 'bar-chart',   'Ca phẫu thuật theo loại',      '{"horizontal":false,"stacked":false,"showValues":true,"colors":["#7c3aed","#2563eb","#0891b2","#16a34a","#f59e0b"]}',                                               'ds-clinical', '{"dimension":"surgery_type","metric":"surgery_count","period":"current_month"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-cl-dept-perf',      'db-clinical-perf', 'data-table',  'Hiệu suất theo khoa',          '{"pageSize":8,"sortable":true,"filterable":false,"striped":true,"columns":[{"key":"name","label":"Khoa"},{"key":"value","label":"Số ca"},{"key":"trend","label":"Tăng trưởng (%)","format":"percentage"}]}', 'ds-clinical', '{"dataset":"dept_performance","limit":8,"sort":"value_desc"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- ============================================================================
-- Dashboard Widgets - Quản lý Dược phẩm (db-pharmacy-mgmt)
-- ============================================================================
    -- Hàng 1: KPI + Gauge
    ('w-ph-prescriptions',  'db-pharmacy-mgmt', 'kpi-card',    'Đơn thuốc / ngày',             '{"format":"number","decimals":0,"showTrend":true,"color":"#0891b2"}',                                                                                               'ds-pharmacy', '{"metric":"prescription_count","period":"today"}',      60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ph-inventory-val',  'db-pharmacy-mgmt', 'metric-card', 'Giá trị tồn kho (tr.đ)',       '{"decimals":1,"suffix":" tr.đ","showTrend":true}',                                                                                                                  'ds-pharmacy', '{"metric":"drug_inventory_value","period":"today"}',     300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ph-dispensed',      'db-pharmacy-mgmt', 'kpi-card',    'Thuốc đã cấp phát hôm nay',    '{"format":"number","decimals":0,"showTrend":true,"color":"#16a34a"}',                                                                                               'ds-pharmacy', '{"metric":"dispensed_items","period":"today"}',          60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ph-inventory-rate', 'db-pharmacy-mgmt', 'gauge',       'Tồn kho an toàn (%)',           '{"min":0,"max":100,"showValue":true,"suffix":"%","thresholds":[{"value":30,"color":"#dc2626"},{"value":50,"color":"#f59e0b"},{"value":70,"color":"#16a34a"}]}',      'ds-pharmacy', '{"metric":"inventory_safety_rate","period":"today"}',    120, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    -- Hàng 2: Xu hướng + Phân bổ
    ('w-ph-rx-trend',       'db-pharmacy-mgmt', 'line-chart',  'Xu hướng kê đơn (90 ngày)',    '{"smooth":true,"showPoints":false,"showLegend":true,"colors":["#0891b2","#16a34a"]}',                                                                               'ds-pharmacy', '{"metrics":["prescription_count","dispensed_items"],"period":"90_days","granularity":"day"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ph-drug-category',  'db-pharmacy-mgmt', 'pie-chart',   'Kê đơn theo nhóm thuốc',       '{"showLegend":true,"donut":false,"showPercentage":true,"colors":["#0891b2","#16a34a","#f59e0b","#dc2626","#7c3aed","#2563eb"]}',                                    'ds-pharmacy', '{"dimension":"drug_category","metric":"prescription_count","period":"current_month"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    -- Hàng 3: Danh sách + Bảng
    ('w-ph-drug-alerts',    'db-pharmacy-mgmt', 'list',        'Cảnh báo tồn kho',             '{"showIcons":true,"compact":false,"showValues":true}',                                                                                                              'ds-pharmacy', '{"dataset":"drug_alerts","limit":8}',                   120, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ph-top-drugs',      'db-pharmacy-mgmt', 'data-table',  'Thuốc sử dụng nhiều nhất',     '{"pageSize":10,"sortable":true,"filterable":false,"striped":true,"columns":[{"key":"name","label":"Tên thuốc"},{"key":"value","label":"Số lượng"},{"key":"trend","label":"Thay đổi (%)","format":"percentage"}]}', 'ds-pharmacy', '{"dataset":"top_drugs","limit":10,"sort":"value_desc"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- ============================================================================
-- Dashboard Widgets - Vận hành Bệnh viện (db-hospital-ops)
-- ============================================================================
    -- Hàng 1: Gauges + KPI
    ('w-ho-wait-time',      'db-hospital-ops', 'metric-card', 'Thời gian chờ cấp cứu (phút)', '{"decimals":0,"suffix":" phút","showTrend":true,"trendDirection":"inverse","color":"#dc2626"}',                                                                     'ds-hospital-ops', '{"metric":"emergency_wait_time","period":"today"}',         60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ho-satisfaction',   'db-hospital-ops', 'gauge',       'Mức độ hài lòng BN (%)',        '{"min":0,"max":100,"showValue":true,"suffix":"%","thresholds":[{"value":70,"color":"#dc2626"},{"value":85,"color":"#f59e0b"},{"value":92,"color":"#16a34a"}]}',      'ds-hospital-ops', '{"metric":"patient_satisfaction","period":"current_month"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ho-staff-util',     'db-hospital-ops', 'gauge',       'Tỷ lệ sử dụng nhân lực (%)',    '{"min":0,"max":100,"showValue":true,"suffix":"%","thresholds":[{"value":60,"color":"#dc2626"},{"value":80,"color":"#f59e0b"},{"value":95,"color":"#16a34a"}]}',      'ds-hospital-ops', '{"metric":"staff_utilization","period":"today"}',           60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ho-revenue-kpi',    'db-hospital-ops', 'kpi-card',    'Doanh thu hôm nay (tr.đ)',      '{"format":"number","decimals":1,"showTrend":true,"color":"#16a34a","suffix":" tr.đ"}',                                                                              'ds-hospital-ops', '{"metric":"total_revenue","period":"today"}',               60,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    -- Hàng 2: Gauge thu hồi + Area chart
    ('w-ho-collection-rate','db-hospital-ops', 'gauge',       'Tỷ lệ thu hồi viện phí (%)',   '{"min":0,"max":100,"showValue":true,"suffix":"%","thresholds":[{"value":70,"color":"#dc2626"},{"value":82,"color":"#f59e0b"},{"value":90,"color":"#16a34a"}]}',      'ds-hospital-ops', '{"metric":"collection_rate","period":"current_month"}',     300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ho-revenue-trend',  'db-hospital-ops', 'area-chart',  'Doanh thu & Chi phí (tr.đ)',    '{"stacked":false,"fillOpacity":0.3,"smooth":true,"showLegend":true,"colors":["#16a34a","#dc2626"]}',                                                                'ds-hospital-ops', '{"metrics":["total_revenue","operating_cost"],"period":"90_days","granularity":"day"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    -- Hàng 3: Xu hướng vận hành + Tình trạng khoa
    ('w-ho-ops-trend',      'db-hospital-ops', 'line-chart',  'Xu hướng vận hành (30 ngày)',   '{"smooth":true,"showPoints":false,"showLegend":true,"colors":["#16a34a","#f59e0b","#dc2626"]}',                                                                     'ds-hospital-ops', '{"metrics":["patient_satisfaction","staff_utilization","emergency_wait_time"],"period":"30_days","granularity":"day"}', 300, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('w-ho-dept-status',    'db-hospital-ops', 'list',        'Tình trạng khoa/phòng',         '{"showIcons":true,"compact":false,"showValues":true}',                                                                                                              'ds-hospital-ops', '{"dataset":"dept_status","limit":10}',                      120, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET
    dashboard_id         = EXCLUDED.dashboard_id,
    widget_type_code     = EXCLUDED.widget_type_code,
    title                = EXCLUDED.title,
    props_json           = EXCLUDED.props_json,
    data_source_id       = EXCLUDED.data_source_id,
    query_config_json    = EXCLUDED.query_config_json,
    refresh_interval_sec = EXCLUDED.refresh_interval_sec,
    updated_at           = CURRENT_TIMESTAMP;

-- ============================================================================
-- Widget Layouts - db-patient-mgmt (Responsive Grid)
-- ============================================================================
INSERT INTO widget_layouts (id, dashboard_id, widget_id, breakpoint, x, y, w, h, is_static)
VALUES
    -- Large screens (lg) — 12 cột
    ('lay-pt-inp-lg',   'db-patient-mgmt', 'w-pt-inpatients',     'lg',  0,  0,  3, 3, FALSE),
    ('lay-pt-adm-lg',   'db-patient-mgmt', 'w-pt-new-admissions', 'lg',  3,  0,  3, 3, FALSE),
    ('lay-pt-dis-lg',   'db-patient-mgmt', 'w-pt-discharges',     'lg',  6,  0,  3, 3, FALSE),
    ('lay-pt-otp-lg',   'db-patient-mgmt', 'w-pt-outpatient',     'lg',  9,  0,  3, 3, FALSE),
    ('lay-pt-bed-lg',   'db-patient-mgmt', 'w-pt-bed-occ',        'lg',  0,  3,  3, 4, FALSE),
    ('lay-pt-adt-lg',   'db-patient-mgmt', 'w-pt-admission-trend','lg',  3,  3,  9, 4, FALSE),
    ('lay-pt-dpt-lg',   'db-patient-mgmt', 'w-pt-dept-bar',       'lg',  0,  7,  5, 5, FALSE),
    ('lay-pt-ins-lg',   'db-patient-mgmt', 'w-pt-insurance-pie',  'lg',  5,  7,  3, 5, FALSE),
    ('lay-pt-dxg-lg',   'db-patient-mgmt', 'w-pt-top-diagnoses',  'lg',  8,  7,  4, 5, FALSE),
    -- Medium screens (md) — 6 cột
    ('lay-pt-inp-md',   'db-patient-mgmt', 'w-pt-inpatients',     'md',  0,  0,  3, 3, FALSE),
    ('lay-pt-adm-md',   'db-patient-mgmt', 'w-pt-new-admissions', 'md',  3,  0,  3, 3, FALSE),
    ('lay-pt-dis-md',   'db-patient-mgmt', 'w-pt-discharges',     'md',  0,  3,  3, 3, FALSE),
    ('lay-pt-otp-md',   'db-patient-mgmt', 'w-pt-outpatient',     'md',  3,  3,  3, 3, FALSE),
    ('lay-pt-bed-md',   'db-patient-mgmt', 'w-pt-bed-occ',        'md',  0,  6,  3, 4, FALSE),
    ('lay-pt-adt-md',   'db-patient-mgmt', 'w-pt-admission-trend','md',  3,  6,  3, 4, FALSE),
    ('lay-pt-dpt-md',   'db-patient-mgmt', 'w-pt-dept-bar',       'md',  0, 10,  6, 5, FALSE),
    ('lay-pt-ins-md',   'db-patient-mgmt', 'w-pt-insurance-pie',  'md',  0, 15,  3, 5, FALSE),
    ('lay-pt-dxg-md',   'db-patient-mgmt', 'w-pt-top-diagnoses',  'md',  3, 15,  3, 5, FALSE),

-- ============================================================================
-- Widget Layouts - db-clinical-perf
-- ============================================================================
    -- Large (lg)
    ('lay-cl-surg-lg',  'db-clinical-perf', 'w-cl-surgeries',    'lg',  0,  0,  3, 3, FALSE),
    ('lay-cl-los-lg',   'db-clinical-perf', 'w-cl-avg-los',      'lg',  3,  0,  3, 3, FALSE),
    ('lay-cl-mort-lg',  'db-clinical-perf', 'w-cl-mortality',    'lg',  6,  0,  3, 3, FALSE),
    ('lay-cl-readm-lg', 'db-clinical-perf', 'w-cl-readmission',  'lg',  9,  0,  3, 3, FALSE),
    ('lay-cl-icu-lg',   'db-clinical-perf', 'w-cl-icu-occ',      'lg',  0,  3,  3, 4, FALSE),
    ('lay-cl-strnd-lg', 'db-clinical-perf', 'w-cl-surgery-trend','lg',  3,  3,  9, 4, FALSE),
    ('lay-cl-stype-lg', 'db-clinical-perf', 'w-cl-surgery-type', 'lg',  0,  7,  5, 5, FALSE),
    ('lay-cl-dperf-lg', 'db-clinical-perf', 'w-cl-dept-perf',   'lg',  5,  7,  7, 5, FALSE),
    -- Medium (md)
    ('lay-cl-surg-md',  'db-clinical-perf', 'w-cl-surgeries',    'md',  0,  0,  3, 3, FALSE),
    ('lay-cl-los-md',   'db-clinical-perf', 'w-cl-avg-los',      'md',  3,  0,  3, 3, FALSE),
    ('lay-cl-mort-md',  'db-clinical-perf', 'w-cl-mortality',    'md',  0,  3,  3, 3, FALSE),
    ('lay-cl-readm-md', 'db-clinical-perf', 'w-cl-readmission',  'md',  3,  3,  3, 3, FALSE),
    ('lay-cl-icu-md',   'db-clinical-perf', 'w-cl-icu-occ',      'md',  0,  6,  3, 4, FALSE),
    ('lay-cl-strnd-md', 'db-clinical-perf', 'w-cl-surgery-trend','md',  3,  6,  3, 4, FALSE),
    ('lay-cl-stype-md', 'db-clinical-perf', 'w-cl-surgery-type', 'md',  0, 10,  6, 5, FALSE),
    ('lay-cl-dperf-md', 'db-clinical-perf', 'w-cl-dept-perf',   'md',  0, 15,  6, 6, FALSE),

-- ============================================================================
-- Widget Layouts - db-pharmacy-mgmt
-- ============================================================================
    -- Large (lg)
    ('lay-ph-rx-lg',    'db-pharmacy-mgmt', 'w-ph-prescriptions', 'lg',  0,  0,  3, 3, FALSE),
    ('lay-ph-inv-lg',   'db-pharmacy-mgmt', 'w-ph-inventory-val', 'lg',  3,  0,  3, 3, FALSE),
    ('lay-ph-dis-lg',   'db-pharmacy-mgmt', 'w-ph-dispensed',     'lg',  6,  0,  3, 3, FALSE),
    ('lay-ph-invr-lg',  'db-pharmacy-mgmt', 'w-ph-inventory-rate','lg',  9,  0,  3, 3, FALSE),
    ('lay-ph-rxr-lg',   'db-pharmacy-mgmt', 'w-ph-rx-trend',      'lg',  0,  3,  8, 5, FALSE),
    ('lay-ph-cat-lg',   'db-pharmacy-mgmt', 'w-ph-drug-category', 'lg',  8,  3,  4, 5, FALSE),
    ('lay-ph-alt-lg',   'db-pharmacy-mgmt', 'w-ph-drug-alerts',   'lg',  0,  8,  4, 5, FALSE),
    ('lay-ph-top-lg',   'db-pharmacy-mgmt', 'w-ph-top-drugs',     'lg',  4,  8,  8, 5, FALSE),
    -- Medium (md)
    ('lay-ph-rx-md',    'db-pharmacy-mgmt', 'w-ph-prescriptions', 'md',  0,  0,  3, 3, FALSE),
    ('lay-ph-inv-md',   'db-pharmacy-mgmt', 'w-ph-inventory-val', 'md',  3,  0,  3, 3, FALSE),
    ('lay-ph-dis-md',   'db-pharmacy-mgmt', 'w-ph-dispensed',     'md',  0,  3,  3, 3, FALSE),
    ('lay-ph-invr-md',  'db-pharmacy-mgmt', 'w-ph-inventory-rate','md',  3,  3,  3, 3, FALSE),
    ('lay-ph-rxr-md',   'db-pharmacy-mgmt', 'w-ph-rx-trend',      'md',  0,  6,  6, 5, FALSE),
    ('lay-ph-cat-md',   'db-pharmacy-mgmt', 'w-ph-drug-category', 'md',  0, 11,  6, 5, FALSE),
    ('lay-ph-alt-md',   'db-pharmacy-mgmt', 'w-ph-drug-alerts',   'md',  0, 16,  6, 5, FALSE),
    ('lay-ph-top-md',   'db-pharmacy-mgmt', 'w-ph-top-drugs',     'md',  0, 21,  6, 6, FALSE),

-- ============================================================================
-- Widget Layouts - db-hospital-ops
-- ============================================================================
    -- Large (lg)
    ('lay-ho-wait-lg',  'db-hospital-ops', 'w-ho-wait-time',      'lg',  0,  0,  3, 3, FALSE),
    ('lay-ho-sat-lg',   'db-hospital-ops', 'w-ho-satisfaction',   'lg',  3,  0,  3, 3, FALSE),
    ('lay-ho-staff-lg', 'db-hospital-ops', 'w-ho-staff-util',     'lg',  6,  0,  3, 3, FALSE),
    ('lay-ho-rev-lg',   'db-hospital-ops', 'w-ho-revenue-kpi',    'lg',  9,  0,  3, 3, FALSE),
    ('lay-ho-col-lg',   'db-hospital-ops', 'w-ho-collection-rate','lg',  0,  3,  3, 4, FALSE),
    ('lay-ho-rtrnd-lg', 'db-hospital-ops', 'w-ho-revenue-trend',  'lg',  3,  3,  9, 4, FALSE),
    ('lay-ho-otrnd-lg', 'db-hospital-ops', 'w-ho-ops-trend',      'lg',  0,  7,  8, 5, FALSE),
    ('lay-ho-dstd-lg',  'db-hospital-ops', 'w-ho-dept-status',    'lg',  8,  7,  4, 5, FALSE),
    -- Medium (md)
    ('lay-ho-wait-md',  'db-hospital-ops', 'w-ho-wait-time',      'md',  0,  0,  3, 3, FALSE),
    ('lay-ho-sat-md',   'db-hospital-ops', 'w-ho-satisfaction',   'md',  3,  0,  3, 3, FALSE),
    ('lay-ho-staff-md', 'db-hospital-ops', 'w-ho-staff-util',     'md',  0,  3,  3, 3, FALSE),
    ('lay-ho-rev-md',   'db-hospital-ops', 'w-ho-revenue-kpi',    'md',  3,  3,  3, 3, FALSE),
    ('lay-ho-col-md',   'db-hospital-ops', 'w-ho-collection-rate','md',  0,  6,  3, 4, FALSE),
    ('lay-ho-rtrnd-md', 'db-hospital-ops', 'w-ho-revenue-trend',  'md',  3,  6,  3, 4, FALSE),
    ('lay-ho-otrnd-md', 'db-hospital-ops', 'w-ho-ops-trend',      'md',  0, 10,  6, 5, FALSE),
    ('lay-ho-dstd-md',  'db-hospital-ops', 'w-ho-dept-status',    'md',  0, 15,  6, 5, FALSE)
ON CONFLICT (id) DO UPDATE SET
    dashboard_id = EXCLUDED.dashboard_id,
    widget_id = EXCLUDED.widget_id,
    breakpoint = EXCLUDED.breakpoint,
    x = EXCLUDED.x,
    y = EXCLUDED.y,
    w = EXCLUDED.w,
    h = EXCLUDED.h,
    is_static = EXCLUDED.is_static;

COMMIT;

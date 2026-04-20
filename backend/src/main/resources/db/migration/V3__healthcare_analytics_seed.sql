-- V3: Chuyển đổi dữ liệu sang domain Y tế / Healthcare
-- Flyway migration: chạy một lần tự động khi backend khởi động

-- ============================================================================
-- Cập nhật Data Sources sang Healthcare
-- ============================================================================
INSERT INTO data_sources (id, name, type, status, jdbc_url, username, password, field_mapping_json, created_at, updated_at)
VALUES
    ('ds-patients',     'Hệ thống Thông tin Bệnh nhân', 'postgresql', 'active', NULL, NULL, NULL,
     '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ds-clinical',     'Phân tích Lâm sàng',            'postgresql', 'active', NULL, NULL, NULL,
     '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ds-pharmacy',     'Hệ thống Dược phẩm',            'postgresql', 'active', NULL, NULL, NULL,
     '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ds-hospital-ops', 'Vận hành Bệnh viện',            'postgresql', 'active', NULL, NULL, NULL,
     '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET
    name               = EXCLUDED.name,
    type               = EXCLUDED.type,
    status             = EXCLUDED.status,
    field_mapping_json = EXCLUDED.field_mapping_json,
    updated_at         = CURRENT_TIMESTAMP;

-- Xoá data sources cũ (sales/marketing domain)
DELETE FROM data_sources WHERE id IN ('ds-sales', 'ds-finance', 'ds-crm', 'ds-marketing', 'ds-monitoring');

-- ============================================================================
-- Xoá dữ liệu analytics cũ và seed lại domain Y tế
-- ============================================================================
DELETE FROM analytics_metric_points;
DELETE FROM analytics_category_values;
DELETE FROM analytics_table_rows;
DELETE FROM analytics_list_items;

-- ============================================================================
-- Metric Points — Chuỗi thời gian 90 ngày
-- ============================================================================

-- ds-patients: chỉ số bệnh nhân hàng ngày
INSERT INTO analytics_metric_points (data_source_id, metric_code, point_date, value, target_value)
SELECT
    'ds-patients',
    metric_code,
    point_date,
    ROUND((base + variation * RANDOM())::numeric, 2),
    ROUND((target_base + variation * 0.4 * RANDOM())::numeric, 2)
FROM (VALUES
    ('new_admissions',     45.0,  30.0,  50.0),
    ('discharge_count',    42.0,  28.0,  48.0),
    ('total_inpatients',  380.0,  40.0, 400.0),
    ('bed_occupancy_rate', 82.0,   8.0,  85.0),
    ('outpatient_visits', 310.0, 100.0, 330.0)
) AS m(metric_code, base, variation, target_base)
CROSS JOIN (
    SELECT GENERATE_SERIES(CURRENT_DATE - INTERVAL '89 day', CURRENT_DATE, INTERVAL '1 day')::date AS point_date
) d;

-- ds-clinical: chỉ số lâm sàng hàng ngày
INSERT INTO analytics_metric_points (data_source_id, metric_code, point_date, value, target_value)
SELECT
    'ds-clinical',
    metric_code,
    point_date,
    ROUND((base + variation * RANDOM())::numeric, 2),
    ROUND((target_base + variation * 0.4 * RANDOM())::numeric, 2)
FROM (VALUES
    ('surgery_count',       22.0, 10.0, 25.0),
    ('avg_length_of_stay',   5.2,  1.6,  5.0),
    ('readmission_rate',     5.8,  2.4,  5.0),
    ('icu_occupancy_rate',  76.0, 14.0, 75.0),
    ('mortality_rate',       1.2,  0.6,  1.0)
) AS m(metric_code, base, variation, target_base)
CROSS JOIN (
    SELECT GENERATE_SERIES(CURRENT_DATE - INTERVAL '89 day', CURRENT_DATE, INTERVAL '1 day')::date AS point_date
) d;

-- ds-pharmacy: chỉ số dược phẩm hàng ngày
INSERT INTO analytics_metric_points (data_source_id, metric_code, point_date, value, target_value)
SELECT
    'ds-pharmacy',
    metric_code,
    point_date,
    ROUND((base + variation * RANDOM())::numeric, 2),
    ROUND((target_base + variation * 0.4 * RANDOM())::numeric, 2)
FROM (VALUES
    ('prescription_count',  340.0,  80.0, 360.0),
    ('dispensed_items',     290.0,  70.0, 320.0),
    ('drug_inventory_value',1050.0,150.0,1000.0),
    ('inventory_safety_rate', 72.0, 18.0,  80.0)
) AS m(metric_code, base, variation, target_base)
CROSS JOIN (
    SELECT GENERATE_SERIES(CURRENT_DATE - INTERVAL '89 day', CURRENT_DATE, INTERVAL '1 day')::date AS point_date
) d;

-- ds-hospital-ops: chỉ số vận hành bệnh viện hàng ngày
INSERT INTO analytics_metric_points (data_source_id, metric_code, point_date, value, target_value)
SELECT
    'ds-hospital-ops',
    metric_code,
    point_date,
    ROUND((base + variation * RANDOM())::numeric, 2),
    ROUND((target_base + variation * 0.4 * RANDOM())::numeric, 2)
FROM (VALUES
    ('emergency_wait_time',   28.0, 14.0,  25.0),
    ('patient_satisfaction',  87.0,  8.0,  90.0),
    ('staff_utilization',     78.0, 10.0,  80.0),
    ('collection_rate',       84.0,  8.0,  88.0),
    ('total_revenue',       2400.0,600.0,2500.0),
    ('operating_cost',      1800.0,400.0,1900.0)
) AS m(metric_code, base, variation, target_base)
CROSS JOIN (
    SELECT GENERATE_SERIES(CURRENT_DATE - INTERVAL '89 day', CURRENT_DATE, INTERVAL '1 day')::date AS point_date
) d;

-- ============================================================================
-- Category Values — Dữ liệu biểu đồ cột/tròn
-- ============================================================================
INSERT INTO analytics_category_values (data_source_id, metric_code, dimension_key, dimension_label, value)
VALUES
    -- Bệnh nhân nhập viện theo khoa (tháng hiện tại)
    ('ds-patients', 'new_admissions', 'noi-khoa',     'Nội khoa',       420),
    ('ds-patients', 'new_admissions', 'ngoai-khoa',   'Ngoại khoa',     310),
    ('ds-patients', 'new_admissions', 'san-phu-khoa', 'Sản phụ khoa',   270),
    ('ds-patients', 'new_admissions', 'nhi-khoa',     'Nhi khoa',       240),
    ('ds-patients', 'new_admissions', 'cap-cuu',      'Cấp cứu',        380),
    ('ds-patients', 'new_admissions', 'tim-mach',     'Tim mạch',       195),
    ('ds-patients', 'new_admissions', 'ung-buou',     'Ung bướu',       165),

    -- Phân loại bảo hiểm bệnh nhân nội trú
    ('ds-patients', 'total_inpatients', 'bhyt',       'BHYT Nhà nước',  620),
    ('ds-patients', 'total_inpatients', 'bh-tu-nhan', 'Bảo hiểm TN',   180),
    ('ds-patients', 'total_inpatients', 'vien-phi',   'Viện phí',        95),

    -- Ca phẫu thuật theo loại
    ('ds-clinical', 'surgery_count', 'tong-quat',    'Tổng quát',       145),
    ('ds-clinical', 'surgery_count', 'noi-soi',      'Nội soi',         210),
    ('ds-clinical', 'surgery_count', 'tim-mach',     'Tim mạch',         62),
    ('ds-clinical', 'surgery_count', 'than-kinh',    'Thần kinh',        38),
    ('ds-clinical', 'surgery_count', 'chinh-hinh',   'Chỉnh hình',       95),

    -- Kê đơn theo nhóm thuốc
    ('ds-pharmacy', 'prescription_count', 'khang-sinh', 'Kháng sinh',  1420),
    ('ds-pharmacy', 'prescription_count', 'tim-mach',   'Tim mạch',     980),
    ('ds-pharmacy', 'prescription_count', 'noi-tiet',   'Nội tiết',     860),
    ('ds-pharmacy', 'prescription_count', 'than-kinh',  'Thần kinh',    640),
    ('ds-pharmacy', 'prescription_count', 'ho-hap',     'Hô hấp',       720),
    ('ds-pharmacy', 'prescription_count', 'tieu-hoa',   'Tiêu hóa',     580);

-- ============================================================================
-- Table Rows — Dữ liệu bảng chi tiết
-- ============================================================================
INSERT INTO analytics_table_rows (data_source_id, dataset_code, row_key, name, value, trend, owner, updated_at)
VALUES
    -- Chẩn đoán hàng đầu (ICD-10)
    ('ds-patients', 'top_diagnoses', 'dx-01', 'Tăng huyết áp (I10)',              312,  4.20, 'Nội khoa',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-patients', 'top_diagnoses', 'dx-02', 'Đái tháo đường type 2 (E11)',      284,  6.50, 'Nội khoa',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-patients', 'top_diagnoses', 'dx-03', 'Viêm phổi (J18.9)',                196, -2.10, 'Hô hấp',     CURRENT_TIMESTAMP - INTERVAL '2 day'),
    ('ds-patients', 'top_diagnoses', 'dx-04', 'Nhồi máu cơ tim (I21)',            148,  1.80, 'Tim mạch',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-patients', 'top_diagnoses', 'dx-05', 'Viêm ruột thừa (K37)',             124, -3.40, 'Ngoại khoa', CURRENT_TIMESTAMP - INTERVAL '3 day'),
    ('ds-patients', 'top_diagnoses', 'dx-06', 'Tai biến mạch máu não (I64)',      112,  2.60, 'Thần kinh',  CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-patients', 'top_diagnoses', 'dx-07', 'Ung thư phổi (C34)',                98,  5.20, 'Ung bướu',   CURRENT_TIMESTAMP - INTERVAL '2 day'),
    ('ds-patients', 'top_diagnoses', 'dx-08', 'Sỏi thận (N20)',                    86, -1.20, 'Niệu khoa',  CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-patients', 'top_diagnoses', 'dx-09', 'Gãy xương đùi (S72)',               74,  0.80, 'Chỉnh hình', CURRENT_TIMESTAMP - INTERVAL '2 day'),
    ('ds-patients', 'top_diagnoses', 'dx-10', 'Trầm cảm nặng (F33)',               68,  8.30, 'Tâm thần',   CURRENT_TIMESTAMP - INTERVAL '1 day'),

    -- Hiệu suất phẫu thuật theo khoa
    ('ds-clinical', 'dept_performance', 'dp-01', 'Khoa Ngoại tổng quát',  210,  3.50, 'BS. Nguyễn Văn An',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-clinical', 'dept_performance', 'dp-02', 'Khoa Tim mạch',         175,  5.20, 'BS. Trần Thị Bình',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-clinical', 'dept_performance', 'dp-03', 'Khoa Nội soi',          168,  2.80, 'BS. Lê Minh Cường',   CURRENT_TIMESTAMP - INTERVAL '2 day'),
    ('ds-clinical', 'dept_performance', 'dp-04', 'Khoa Chỉnh hình',       142,  1.40, 'BS. Phạm Thị Duyên',  CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-clinical', 'dept_performance', 'dp-05', 'Khoa Thần kinh',        118,  4.60, 'BS. Hoàng Văn Đức',   CURRENT_TIMESTAMP - INTERVAL '3 day'),
    ('ds-clinical', 'dept_performance', 'dp-06', 'Khoa Sản',               96,  2.10, 'BS. Vũ Thị Hương',    CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-clinical', 'dept_performance', 'dp-07', 'Khoa Nhi',               84, -1.20, 'BS. Đặng Quốc Minh',  CURRENT_TIMESTAMP - INTERVAL '2 day'),
    ('ds-clinical', 'dept_performance', 'dp-08', 'Khoa Ung bướu',          72,  6.80, 'BS. Bùi Thị Ngọc',    CURRENT_TIMESTAMP - INTERVAL '1 day'),

    -- Thuốc sử dụng nhiều nhất
    ('ds-pharmacy', 'top_drugs', 'drug-01', 'Amoxicillin 500mg',       2840,  6.20, 'Kháng sinh', CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-pharmacy', 'top_drugs', 'drug-02', 'Metformin 850mg',         2210,  8.40, 'Nội tiết',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-pharmacy', 'top_drugs', 'drug-03', 'Amlodipine 5mg',          1980,  4.10, 'Tim mạch',   CURRENT_TIMESTAMP - INTERVAL '2 day'),
    ('ds-pharmacy', 'top_drugs', 'drug-04', 'Omeprazole 20mg',         1760,  2.60, 'Tiêu hóa',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-pharmacy', 'top_drugs', 'drug-05', 'Paracetamol 500mg',       1640, -1.30, 'Giảm đau',   CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-pharmacy', 'top_drugs', 'drug-06', 'Atorvastatin 20mg',       1420,  5.80, 'Tim mạch',   CURRENT_TIMESTAMP - INTERVAL '2 day'),
    ('ds-pharmacy', 'top_drugs', 'drug-07', 'Ceftriaxone 1g (tiêm)',   1280,  3.40, 'Kháng sinh', CURRENT_TIMESTAMP - INTERVAL '1 day'),
    ('ds-pharmacy', 'top_drugs', 'drug-08', 'Insulin Glargine 100U/ml',  960,  7.20, 'Nội tiết',  CURRENT_TIMESTAMP - INTERVAL '3 day');

-- ============================================================================
-- List Items — Danh sách trạng thái
-- ============================================================================
INSERT INTO analytics_list_items (data_source_id, dataset_code, label, value, status, sort_order)
VALUES
    -- Cảnh báo tồn kho thuốc cần nhập thêm (value = số đơn vị còn lại)
    ('ds-pharmacy', 'drug_alerts', 'Vancomycin 500mg',             12, 'warning',  1),
    ('ds-pharmacy', 'drug_alerts', 'Piperacillin/Tazobactam 4.5g',  8, 'critical', 2),
    ('ds-pharmacy', 'drug_alerts', 'Midazolam 5mg/1ml',            15, 'warning',  3),
    ('ds-pharmacy', 'drug_alerts', 'Dopamine 200mg',                6, 'critical', 4),
    ('ds-pharmacy', 'drug_alerts', 'Heparin 5000IU/1ml',           18, 'warning',  5),
    ('ds-pharmacy', 'drug_alerts', 'Albumin 20% 100ml',             9, 'critical', 6),
    ('ds-pharmacy', 'drug_alerts', 'Norepinephrine 4mg/4ml',       11, 'warning',  7),
    ('ds-pharmacy', 'drug_alerts', 'Propofol 200mg/20ml',          14, 'warning',  8),

    -- Tình trạng khoa/phòng (value = % công suất giường)
    ('ds-hospital-ops', 'dept_status', 'Khoa Nội khoa A',       85, 'healthy',  1),
    ('ds-hospital-ops', 'dept_status', 'Khoa Nội khoa B',       92, 'warning',  2),
    ('ds-hospital-ops', 'dept_status', 'Khoa Ngoại tổng quát',  78, 'healthy',  3),
    ('ds-hospital-ops', 'dept_status', 'Khoa ICU',              94, 'critical', 4),
    ('ds-hospital-ops', 'dept_status', 'Khoa Cấp cứu',          88, 'warning',  5),
    ('ds-hospital-ops', 'dept_status', 'Khoa Sản',              72, 'healthy',  6),
    ('ds-hospital-ops', 'dept_status', 'Khoa Nhi',              66, 'healthy',  7),
    ('ds-hospital-ops', 'dept_status', 'Khoa Tim mạch',         90, 'warning',  8),
    ('ds-hospital-ops', 'dept_status', 'Khoa Ung bướu',         75, 'healthy',  9),
    ('ds-hospital-ops', 'dept_status', 'Khoa Thần kinh',        82, 'healthy', 10);

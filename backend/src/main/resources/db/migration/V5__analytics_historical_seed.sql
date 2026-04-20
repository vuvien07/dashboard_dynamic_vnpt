-- V5: Bổ sung dữ liệu lịch sử 2024-2025 để hỗ trợ filter theo năm/tháng
-- Mục tiêu: Đảm bảo mọi widget hiển thị dữ liệu khi người dùng lọc theo năm 2024, 2025
--           hoặc bất kỳ tháng nào trong khoảng thời gian đó.

-- ============================================================================
-- 1. analytics_metric_points — Dữ liệu hàng ngày từ 2024-01-01 đến 2025-12-10
--    (V3 đã seed 90 ngày cuối: ~2025-12-11 → hôm nay)
-- ============================================================================

INSERT INTO analytics_metric_points
    (data_source_id, metric_code, point_date, value, target_value,
     department_code, site_code, status_code)
SELECT
    m.data_source_id,
    m.metric_code,
    d.point_date,
    -- Giá trị có xu hướng mùa vụ (SIN) + tăng trưởng nhẹ theo năm
    GREATEST(0.01, ROUND((
        m.base
        + m.variation * 0.5
        + m.variation * 0.3 * SIN(2 * PI() * EXTRACT(DOY FROM d.point_date) / 365.0)
        + m.variation * 0.15 * (EXTRACT(YEAR FROM d.point_date) - 2024)
    )::numeric, 2)) AS value,
    ROUND((m.target_base + m.variation * 0.2)::numeric, 2) AS target_value,
    -- Phân bổ khoa theo ngày trong năm (cycling)
    (ARRAY['noi-khoa','ngoai-khoa','cap-cuu','icu'])
        [(EXTRACT(DOY FROM d.point_date)::int % 4) + 1] AS department_code,
    -- Phân bổ cơ sở theo tháng (cycling)
    (ARRAY['co-so-a','co-so-b','co-so-c'])
        [(EXTRACT(MONTH FROM d.point_date)::int % 3) + 1] AS site_code,
    -- Phân bổ trạng thái: phần lớn healthy, một số warning/critical
    CASE (EXTRACT(DOY FROM d.point_date)::int % 6)
        WHEN 5 THEN 'critical'
        WHEN 3 THEN 'warning'
        WHEN 1 THEN 'warning'
        ELSE 'healthy'
    END AS status_code
FROM (VALUES
    -- ds-patients
    ('ds-patients', 'new_admissions',       45.0,  30.0,  50.0),
    ('ds-patients', 'discharge_count',      42.0,  28.0,  48.0),
    ('ds-patients', 'total_inpatients',    380.0,  40.0, 400.0),
    ('ds-patients', 'bed_occupancy_rate',   82.0,   8.0,  85.0),
    ('ds-patients', 'outpatient_visits',   310.0, 100.0, 330.0),
    -- ds-clinical
    ('ds-clinical', 'surgery_count',        22.0,  10.0,  25.0),
    ('ds-clinical', 'avg_length_of_stay',    5.2,   1.6,   5.0),
    ('ds-clinical', 'readmission_rate',      5.8,   2.4,   5.0),
    ('ds-clinical', 'icu_occupancy_rate',   76.0,  14.0,  75.0),
    ('ds-clinical', 'mortality_rate',        1.2,   0.6,   1.0),
    -- ds-pharmacy
    ('ds-pharmacy', 'prescription_count',  340.0,  80.0, 360.0),
    ('ds-pharmacy', 'dispensed_items',     290.0,  70.0, 320.0),
    ('ds-pharmacy', 'drug_inventory_value',1050.0, 150.0,1000.0),
    ('ds-pharmacy', 'inventory_safety_rate', 72.0, 18.0,  80.0),
    -- ds-hospital-ops
    ('ds-hospital-ops', 'emergency_wait_time',   28.0,  14.0,  25.0),
    ('ds-hospital-ops', 'patient_satisfaction',  87.0,   8.0,  90.0),
    ('ds-hospital-ops', 'staff_utilization',     78.0,  10.0,  80.0),
    ('ds-hospital-ops', 'collection_rate',       84.0,   8.0,  88.0),
    ('ds-hospital-ops', 'total_revenue',       2400.0, 600.0,2500.0),
    ('ds-hospital-ops', 'operating_cost',      1800.0, 400.0,1900.0)
) AS m(data_source_id, metric_code, base, variation, target_base)
CROSS JOIN (
    SELECT GENERATE_SERIES('2024-01-01'::date, '2025-12-10'::date, INTERVAL '1 day')::date AS point_date
) d;

-- ============================================================================
-- 2. analytics_category_values — Snapshot hàng tháng 2024-01 đến 2026-02
--    Mỗi chiều dữ liệu có 1 bản ghi cho mỗi tháng với point_date ở giữa tháng
-- ============================================================================

INSERT INTO analytics_category_values
    (data_source_id, metric_code, dimension_key, dimension_label, value,
     point_date, department_code, site_code, status_code)
SELECT
    cat.data_source_id,
    cat.metric_code,
    cat.dimension_key,
    cat.dimension_label,
    -- Giá trị biến động nhẹ theo tháng + tăng trưởng theo năm
    GREATEST(1, ROUND((
        cat.base_value
        * (0.82 + 0.36 * ((EXTRACT(MONTH FROM mo.month_start)::int % 7) / 7.0))
        + cat.base_value * 0.06 * (EXTRACT(YEAR FROM mo.month_start) - 2024)
    )::numeric, 2)) AS value,
    -- Đặt point_date vào ngày 15 của tháng
    (mo.month_start + INTERVAL '14 day')::date AS point_date,
    -- Phân bổ khoa theo tháng (cycling)
    (ARRAY['noi-khoa','ngoai-khoa','cap-cuu','icu'])
        [(EXTRACT(MONTH FROM mo.month_start)::int % 4) + 1] AS department_code,
    -- Phân bổ cơ sở theo quý
    (ARRAY['co-so-a','co-so-b','co-so-c'])
        [(EXTRACT(QUARTER FROM mo.month_start)::int % 3) + 1] AS site_code,
    CASE (EXTRACT(MONTH FROM mo.month_start)::int % 4)
        WHEN 0 THEN 'warning'
        ELSE 'healthy'
    END AS status_code
FROM (VALUES
    -- Bệnh nhân nhập viện theo khoa
    ('ds-patients','new_admissions','noi-khoa',     'Nội khoa',       420.0),
    ('ds-patients','new_admissions','ngoai-khoa',   'Ngoại khoa',     310.0),
    ('ds-patients','new_admissions','san-phu-khoa', 'Sản phụ khoa',   270.0),
    ('ds-patients','new_admissions','nhi-khoa',     'Nhi khoa',       240.0),
    ('ds-patients','new_admissions','cap-cuu',       'Cấp cứu',       380.0),
    ('ds-patients','new_admissions','tim-mach',      'Tim mạch',      195.0),
    ('ds-patients','new_admissions','ung-buou',      'Ung bướu',      165.0),
    -- Phân loại bảo hiểm bệnh nhân nội trú
    ('ds-patients','total_inpatients','bhyt',        'BHYT Nhà nước', 620.0),
    ('ds-patients','total_inpatients','bh-tu-nhan',  'Bảo hiểm TN',  180.0),
    ('ds-patients','total_inpatients','vien-phi',    'Viện phí',       95.0),
    -- Ca phẫu thuật theo loại
    ('ds-clinical','surgery_count','tong-quat',  'Tổng quát',  145.0),
    ('ds-clinical','surgery_count','noi-soi',    'Nội soi',    210.0),
    ('ds-clinical','surgery_count','tim-mach',   'Tim mạch',    62.0),
    ('ds-clinical','surgery_count','than-kinh',  'Thần kinh',   38.0),
    ('ds-clinical','surgery_count','chinh-hinh', 'Chỉnh hình',  95.0),
    -- Kê đơn theo nhóm thuốc
    ('ds-pharmacy','prescription_count','khang-sinh', 'Kháng sinh', 1420.0),
    ('ds-pharmacy','prescription_count','tim-mach',   'Tim mạch',    980.0),
    ('ds-pharmacy','prescription_count','noi-tiet',   'Nội tiết',    860.0),
    ('ds-pharmacy','prescription_count','than-kinh',  'Thần kinh',   640.0),
    ('ds-pharmacy','prescription_count','ho-hap',     'Hô hấp',      720.0),
    ('ds-pharmacy','prescription_count','tieu-hoa',   'Tiêu hóa',    580.0)
) AS cat(data_source_id, metric_code, dimension_key, dimension_label, base_value)
CROSS JOIN (
    SELECT GENERATE_SERIES('2024-01-01'::date, '2026-02-01'::date, INTERVAL '1 month')::date AS month_start
) mo;

-- ============================================================================
-- 3. analytics_table_rows — Snapshot hàng tháng 2024-01 đến 2026-02
--    updated_at đặt vào ngày 15 của mỗi tháng để filter YEAR/MONTH hoạt động
-- ============================================================================

INSERT INTO analytics_table_rows
    (data_source_id, dataset_code, row_key, name, value, trend, owner, updated_at,
     department_code, site_code, status_code)
SELECT
    r.data_source_id,
    r.dataset_code,
    r.row_key,
    r.name,
    -- Giá trị biến động theo tháng + tăng nhẹ theo năm
    GREATEST(0.01, ROUND((
        r.base_value
        * (0.82 + 0.36 * ((EXTRACT(MONTH FROM mo.month_start)::int % 7) / 7.0))
        + r.base_value * 0.05 * (EXTRACT(YEAR FROM mo.month_start) - 2024)
    )::numeric, 2)) AS value,
    -- Trend thay đổi theo quý
    ROUND((r.base_trend + 1.5 * ((EXTRACT(QUARTER FROM mo.month_start)::int % 3) - 1))::numeric, 2) AS trend,
    r.owner,
    -- updated_at vào ngày 15 của tháng
    (mo.month_start + INTERVAL '14 day')::timestamp WITH TIME ZONE AS updated_at,
    r.dept_code AS department_code,
    (ARRAY['co-so-a','co-so-b','co-so-c'])
        [(EXTRACT(MONTH FROM mo.month_start)::int % 3) + 1] AS site_code,
    CASE (EXTRACT(MONTH FROM mo.month_start)::int % 4)
        WHEN 0 THEN 'warning'
        ELSE 'healthy'
    END AS status_code
FROM (VALUES
    -- Chẩn đoán hàng đầu (ds-patients)
    ('ds-patients','top_diagnoses','dx-01','Tăng huyết áp (I10)',          312.0,  4.20,'Nội khoa',   'noi-khoa'),
    ('ds-patients','top_diagnoses','dx-02','Đái tháo đường type 2 (E11)',   284.0,  6.50,'Nội khoa',   'noi-khoa'),
    ('ds-patients','top_diagnoses','dx-03','Viêm phổi (J18.9)',             196.0, -2.10,'Hô hấp',     'noi-khoa'),
    ('ds-patients','top_diagnoses','dx-04','Nhồi máu cơ tim (I21)',         148.0,  1.80,'Tim mạch',   'noi-khoa'),
    ('ds-patients','top_diagnoses','dx-05','Viêm ruột thừa (K37)',          124.0, -3.40,'Ngoại khoa', 'ngoai-khoa'),
    ('ds-patients','top_diagnoses','dx-06','Tai biến mạch máu não (I64)',   112.0,  2.60,'Thần kinh',  'noi-khoa'),
    ('ds-patients','top_diagnoses','dx-07','Ung thư phổi (C34)',             98.0,  5.20,'Ung bướu',   'ngoai-khoa'),
    ('ds-patients','top_diagnoses','dx-08','Sỏi thận (N20)',                 86.0, -1.20,'Niệu khoa',  'ngoai-khoa'),
    ('ds-patients','top_diagnoses','dx-09','Gãy xương đùi (S72)',            74.0,  0.80,'Chỉnh hình', 'ngoai-khoa'),
    ('ds-patients','top_diagnoses','dx-10','Trầm cảm nặng (F33)',            68.0,  8.30,'Tâm thần',   'noi-khoa'),
    -- Hiệu suất phẫu thuật theo khoa (ds-clinical)
    ('ds-clinical','dept_performance','dp-01','Khoa Ngoại tổng quát',  210.0,  3.50,'BS. Nguyễn Văn An', 'ngoai-khoa'),
    ('ds-clinical','dept_performance','dp-02','Khoa Tim mạch',         175.0,  5.20,'BS. Trần Thị Bình', 'noi-khoa'),
    ('ds-clinical','dept_performance','dp-03','Khoa Nội soi',          168.0,  2.80,'BS. Lê Minh Cường', 'ngoai-khoa'),
    ('ds-clinical','dept_performance','dp-04','Khoa Chỉnh hình',       142.0,  1.40,'BS. Phạm Thị Duyên','ngoai-khoa'),
    ('ds-clinical','dept_performance','dp-05','Khoa Thần kinh',        118.0,  4.60,'BS. Hoàng Văn Đức', 'noi-khoa'),
    ('ds-clinical','dept_performance','dp-06','Khoa Sản',               96.0,  2.10,'BS. Vũ Thị Hương',  'ngoai-khoa'),
    ('ds-clinical','dept_performance','dp-07','Khoa Nhi',               84.0, -1.20,'BS. Đặng Quốc Minh','noi-khoa'),
    ('ds-clinical','dept_performance','dp-08','Khoa Ung bướu',          72.0,  6.80,'BS. Bùi Thị Ngọc',  'ngoai-khoa'),
    -- Thuốc sử dụng nhiều nhất (ds-pharmacy)
    ('ds-pharmacy','top_drugs','drug-01','Amoxicillin 500mg',        2840.0,  6.20,'Kháng sinh','noi-khoa'),
    ('ds-pharmacy','top_drugs','drug-02','Metformin 850mg',          2210.0,  8.40,'Nội tiết',  'noi-khoa'),
    ('ds-pharmacy','top_drugs','drug-03','Amlodipine 5mg',           1980.0,  4.10,'Tim mạch',  'noi-khoa'),
    ('ds-pharmacy','top_drugs','drug-04','Omeprazole 20mg',          1760.0,  2.60,'Tiêu hóa',  'noi-khoa'),
    ('ds-pharmacy','top_drugs','drug-05','Paracetamol 500mg',        1640.0, -1.30,'Giảm đau',  'noi-khoa'),
    ('ds-pharmacy','top_drugs','drug-06','Atorvastatin 20mg',        1420.0,  5.80,'Tim mạch',  'noi-khoa'),
    ('ds-pharmacy','top_drugs','drug-07','Ceftriaxone 1g (tiêm)',    1280.0,  3.40,'Kháng sinh','ngoai-khoa'),
    ('ds-pharmacy','top_drugs','drug-08','Insulin Glargine 100U/ml',  960.0,  7.20,'Nội tiết',  'noi-khoa')
) AS r(data_source_id, dataset_code, row_key, name, base_value, base_trend, owner, dept_code)
CROSS JOIN (
    SELECT GENERATE_SERIES('2024-01-01'::date, '2026-02-01'::date, INTERVAL '1 month')::date AS month_start
) mo;

-- ============================================================================
-- 4. analytics_list_items — Snapshot hàng tháng 2024-01 đến 2026-02
--    point_date đặt vào ngày 10 của mỗi tháng
-- ============================================================================

INSERT INTO analytics_list_items
    (data_source_id, dataset_code, label, value, status, sort_order,
     point_date, department_code, site_code)
SELECT
    li.data_source_id,
    li.dataset_code,
    li.label,
    -- Giá trị tồn kho / công suất thay đổi theo tháng
    GREATEST(1, ROUND((
        li.base_value
        * (0.6 + 0.8 * ((EXTRACT(MONTH FROM mo.month_start)::int % 5) / 5.0))
    )::numeric, 0)) AS value,
    -- Trạng thái có thể thay đổi theo mùa
    CASE
        WHEN li.base_status = 'critical' THEN 'critical'
        WHEN li.base_status = 'warning' AND (EXTRACT(MONTH FROM mo.month_start)::int % 3) = 0 THEN 'critical'
        WHEN (EXTRACT(MONTH FROM mo.month_start)::int % 5) = 0 THEN 'warning'
        ELSE li.base_status
    END AS status,
    li.sort_order,
    -- point_date vào ngày 10 của tháng
    (mo.month_start + INTERVAL '9 day')::date AS point_date,
    (ARRAY['noi-khoa','ngoai-khoa','cap-cuu','icu'])
        [(EXTRACT(MONTH FROM mo.month_start)::int % 4) + 1] AS department_code,
    (ARRAY['co-so-a','co-so-b','co-so-c'])
        [(EXTRACT(MONTH FROM mo.month_start)::int % 3) + 1] AS site_code
FROM (VALUES
    -- Cảnh báo tồn kho thuốc
    ('ds-pharmacy','drug_alerts','Vancomycin 500mg',              12.0,'warning',  1),
    ('ds-pharmacy','drug_alerts','Piperacillin/Tazobactam 4.5g',   8.0,'critical', 2),
    ('ds-pharmacy','drug_alerts','Midazolam 5mg/1ml',             15.0,'warning',  3),
    ('ds-pharmacy','drug_alerts','Dopamine 200mg',                 6.0,'critical', 4),
    ('ds-pharmacy','drug_alerts','Heparin 5000IU/1ml',            18.0,'warning',  5),
    ('ds-pharmacy','drug_alerts','Albumin 20% 100ml',              9.0,'critical', 6),
    ('ds-pharmacy','drug_alerts','Norepinephrine 4mg/4ml',        11.0,'warning',  7),
    ('ds-pharmacy','drug_alerts','Propofol 200mg/20ml',           14.0,'warning',  8),
    -- Tình trạng khoa/phòng (% công suất giường)
    ('ds-hospital-ops','dept_status','Khoa Nội khoa A',      85.0,'healthy',  1),
    ('ds-hospital-ops','dept_status','Khoa Nội khoa B',      92.0,'warning',  2),
    ('ds-hospital-ops','dept_status','Khoa Ngoại tổng quát', 78.0,'healthy',  3),
    ('ds-hospital-ops','dept_status','Khoa ICU',             94.0,'critical', 4),
    ('ds-hospital-ops','dept_status','Khoa Cấp cứu',         88.0,'warning',  5),
    ('ds-hospital-ops','dept_status','Khoa Sản',             72.0,'healthy',  6),
    ('ds-hospital-ops','dept_status','Khoa Nhi',             66.0,'healthy',  7),
    ('ds-hospital-ops','dept_status','Khoa Tim mạch',        90.0,'warning',  8),
    ('ds-hospital-ops','dept_status','Khoa Ung bướu',        75.0,'healthy',  9),
    ('ds-hospital-ops','dept_status','Khoa Thần kinh',       82.0,'healthy', 10)
) AS li(data_source_id, dataset_code, label, base_value, base_status, sort_order)
CROSS JOIN (
    SELECT GENERATE_SERIES('2024-01-01'::date, '2026-02-01'::date, INTERVAL '1 month')::date AS month_start
) mo;

-- ============================================================================
-- Thêm index bổ sung cho category_values.point_date để cải thiện hiệu suất
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_category_values_global_filters
    ON analytics_category_values(data_source_id, metric_code, point_date, department_code, site_code, status_code);

CREATE INDEX IF NOT EXISTS idx_table_rows_global_filters
    ON analytics_table_rows(data_source_id, dataset_code, updated_at, department_code, site_code, status_code);

CREATE INDEX IF NOT EXISTS idx_list_items_global_filters
    ON analytics_list_items(data_source_id, dataset_code, point_date, department_code, site_code);

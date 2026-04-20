ALTER TABLE analytics_metric_points
    ADD COLUMN IF NOT EXISTS department_code VARCHAR(40),
    ADD COLUMN IF NOT EXISTS site_code VARCHAR(40),
    ADD COLUMN IF NOT EXISTS status_code VARCHAR(20);

ALTER TABLE analytics_category_values
    ADD COLUMN IF NOT EXISTS point_date DATE,
    ADD COLUMN IF NOT EXISTS department_code VARCHAR(40),
    ADD COLUMN IF NOT EXISTS site_code VARCHAR(40),
    ADD COLUMN IF NOT EXISTS status_code VARCHAR(20);

ALTER TABLE analytics_table_rows
    ADD COLUMN IF NOT EXISTS department_code VARCHAR(40),
    ADD COLUMN IF NOT EXISTS site_code VARCHAR(40),
    ADD COLUMN IF NOT EXISTS status_code VARCHAR(20);

ALTER TABLE analytics_list_items
    ADD COLUMN IF NOT EXISTS point_date DATE,
    ADD COLUMN IF NOT EXISTS department_code VARCHAR(40),
    ADD COLUMN IF NOT EXISTS site_code VARCHAR(40);

UPDATE analytics_metric_points
SET
    department_code = CASE FLOOR(RANDOM() * 4)::int
        WHEN 0 THEN 'noi-khoa'
        WHEN 1 THEN 'ngoai-khoa'
        WHEN 2 THEN 'cap-cuu'
        ELSE 'icu'
    END,
    site_code = CASE FLOOR(RANDOM() * 3)::int
        WHEN 0 THEN 'co-so-a'
        WHEN 1 THEN 'co-so-b'
        ELSE 'co-so-c'
    END,
    status_code = CASE FLOOR(RANDOM() * 3)::int
        WHEN 0 THEN 'healthy'
        WHEN 1 THEN 'warning'
        ELSE 'critical'
    END
WHERE department_code IS NULL OR site_code IS NULL OR status_code IS NULL;

UPDATE analytics_category_values
SET
    point_date = COALESCE(point_date, (CURRENT_DATE - (FLOOR(RANDOM() * 270)::int))),
    department_code = COALESCE(department_code, CASE FLOOR(RANDOM() * 4)::int
        WHEN 0 THEN 'noi-khoa'
        WHEN 1 THEN 'ngoai-khoa'
        WHEN 2 THEN 'cap-cuu'
        ELSE 'icu'
    END),
    site_code = COALESCE(site_code, CASE FLOOR(RANDOM() * 3)::int
        WHEN 0 THEN 'co-so-a'
        WHEN 1 THEN 'co-so-b'
        ELSE 'co-so-c'
    END),
    status_code = COALESCE(status_code, CASE FLOOR(RANDOM() * 3)::int
        WHEN 0 THEN 'healthy'
        WHEN 1 THEN 'warning'
        ELSE 'critical'
    END)
WHERE point_date IS NULL OR department_code IS NULL OR site_code IS NULL OR status_code IS NULL;

UPDATE analytics_table_rows
SET
    department_code = COALESCE(department_code, CASE FLOOR(RANDOM() * 4)::int
        WHEN 0 THEN 'noi-khoa'
        WHEN 1 THEN 'ngoai-khoa'
        WHEN 2 THEN 'cap-cuu'
        ELSE 'icu'
    END),
    site_code = COALESCE(site_code, CASE FLOOR(RANDOM() * 3)::int
        WHEN 0 THEN 'co-so-a'
        WHEN 1 THEN 'co-so-b'
        ELSE 'co-so-c'
    END),
    status_code = COALESCE(status_code, CASE FLOOR(RANDOM() * 3)::int
        WHEN 0 THEN 'healthy'
        WHEN 1 THEN 'warning'
        ELSE 'critical'
    END)
WHERE department_code IS NULL OR site_code IS NULL OR status_code IS NULL;

UPDATE analytics_list_items
SET
    point_date = COALESCE(point_date, (CURRENT_DATE - (FLOOR(RANDOM() * 270)::int))),
    department_code = COALESCE(department_code, CASE FLOOR(RANDOM() * 4)::int
        WHEN 0 THEN 'noi-khoa'
        WHEN 1 THEN 'ngoai-khoa'
        WHEN 2 THEN 'cap-cuu'
        ELSE 'icu'
    END),
    site_code = COALESCE(site_code, CASE FLOOR(RANDOM() * 3)::int
        WHEN 0 THEN 'co-so-a'
        WHEN 1 THEN 'co-so-b'
        ELSE 'co-so-c'
    END)
WHERE point_date IS NULL OR department_code IS NULL OR site_code IS NULL;

CREATE INDEX IF NOT EXISTS idx_metric_points_global_filters
    ON analytics_metric_points(data_source_id, metric_code, point_date, department_code, site_code, status_code);

CREATE INDEX IF NOT EXISTS idx_category_values_global_filters
    ON analytics_category_values(data_source_id, metric_code, point_date, department_code, site_code, status_code);

CREATE INDEX IF NOT EXISTS idx_table_rows_global_filters
    ON analytics_table_rows(data_source_id, dataset_code, updated_at, department_code, site_code, status_code);

CREATE INDEX IF NOT EXISTS idx_list_items_global_filters
    ON analytics_list_items(data_source_id, dataset_code, point_date, department_code, site_code, status);
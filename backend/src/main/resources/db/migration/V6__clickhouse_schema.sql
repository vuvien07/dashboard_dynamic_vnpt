-- V6: Chuyển đổi schema các bảng analytics_metric_points, analytics_table_rows, analytics_list_items
--     sang ClickHouse nhằm tăng tốc độ truy vấn, phân tích với dữ liệu lớn


CREATE TABLE IF NOT EXISTS analytics_metric_points
(
    id UInt64,
    data_source_id String NOT NULL,
    metric_code String NOT NULL,
    point_date Date NOT NULL,
    value Decimal(18,2) NOT NULL,
    target_value Decimal(18,2) NOT NULL
)
    ENGINE = MergeTree
ORDER BY (point_date, data_source_id, metric_code, id);

CREATE TABLE IF NOT EXISTS analytics_category_values
(
    id UInt64,
    data_source_id String NOT NULL,
    metric_code String NOT NULL,
    dimension_key String NOT NULL,
    dimension_label String NOT NULL,
    value Decimal(18,2) NOT NULL
)
    ENGINE = MergeTree
ORDER BY (data_source_id, metric_code, dimension_key, id);

CREATE TABLE IF NOT EXISTS analytics_table_rows
(
    id UInt64,
    data_source_id String,
    dataset_code String,
    row_key String,
    name String,
    value Decimal(18,2),
    trend Decimal(10,2),
    owner String,
    updated_at DateTime
)
    ENGINE = MergeTree
ORDER BY (data_source_id, dataset_code, row_key, updated_at DESC)
SETTINGS allow_experimental_reverse_key = 1;

CREATE TABLE IF NOT EXISTS analytics_list_items
(
    id UInt64,
    data_source_id String NOT NULL,
    dataset_code String NOT NULL,
    label String NOT NULL,
    value Decimal(18,2) NOT NULL,
    status String NOT NULL,
    sort_order Int32 NOT NULL
)
    ENGINE = MergeTree
ORDER BY (data_source_id, dataset_code, sort_order, id);

ALTER TABLE analytics_metric_points
    ADD COLUMN IF NOT EXISTS department_code String,
ADD COLUMN IF NOT EXISTS site_code String,
ADD COLUMN IF NOT EXISTS status_code String;

ALTER TABLE analytics_category_values
ADD COLUMN IF NOT EXISTS point_date Date,
ADD COLUMN IF NOT EXISTS department_code String,
ADD COLUMN IF NOT EXISTS site_code String,
ADD COLUMN IF NOT EXISTS status_code String;

ALTER TABLE analytics_table_rows
    ADD COLUMN IF NOT EXISTS department_code String,
ADD COLUMN IF NOT EXISTS site_code String,
ADD COLUMN IF NOT EXISTS status_code String;

ALTER TABLE analytics_list_items
    ADD COLUMN IF NOT EXISTS point_date Date,
ADD COLUMN IF NOT EXISTS department_code String,
ADD COLUMN IF NOT EXISTS site_code String;


ALTER TABLE analytics_metric_points
    ADD INDEX idx_metric_points_global_filters
(data_source_id, metric_code, point_date, department_code, site_code, status_code)
TYPE minmax GRANULARITY 1;

ALTER TABLE analytics_metric_points
    ADD INDEX idx_dept_site_status (department_code, site_code, status_code) TYPE set(1000) GRANULARITY 1,
ADD INDEX idx_point_date (point_date) TYPE minmax GRANULARITY 1;
CREATE TABLE IF NOT EXISTS data_sources (
    id VARCHAR(80) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    type VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL,
    jdbc_url VARCHAR(255),
    username VARCHAR(120),
    password VARCHAR(255),
    field_mapping_json TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics_metric_points (
    id BIGSERIAL PRIMARY KEY,
    data_source_id VARCHAR(80) NOT NULL,
    metric_code VARCHAR(80) NOT NULL,
    point_date DATE NOT NULL,
    value NUMERIC(18, 2) NOT NULL,
    target_value NUMERIC(18, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics_category_values (
    id BIGSERIAL PRIMARY KEY,
    data_source_id VARCHAR(80) NOT NULL,
    metric_code VARCHAR(80) NOT NULL,
    dimension_key VARCHAR(80) NOT NULL,
    dimension_label VARCHAR(120) NOT NULL,
    value NUMERIC(18, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics_table_rows (
    id BIGSERIAL PRIMARY KEY,
    data_source_id VARCHAR(80) NOT NULL,
    dataset_code VARCHAR(80) NOT NULL,
    row_key VARCHAR(80) NOT NULL,
    name VARCHAR(120) NOT NULL,
    value NUMERIC(18, 2) NOT NULL,
    trend NUMERIC(10, 2) NOT NULL,
    owner VARCHAR(80),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics_list_items (
    id BIGSERIAL PRIMARY KEY,
    data_source_id VARCHAR(80) NOT NULL,
    dataset_code VARCHAR(80) NOT NULL,
    label VARCHAR(120) NOT NULL,
    value NUMERIC(18, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    sort_order INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_data_sources_name ON data_sources(name);
CREATE INDEX IF NOT EXISTS idx_metric_points_source_metric_date ON analytics_metric_points(data_source_id, metric_code, point_date);
CREATE INDEX IF NOT EXISTS idx_category_values_source_metric ON analytics_category_values(data_source_id, metric_code);
CREATE INDEX IF NOT EXISTS idx_table_rows_source_dataset ON analytics_table_rows(data_source_id, dataset_code);
CREATE INDEX IF NOT EXISTS idx_list_items_source_dataset ON analytics_list_items(data_source_id, dataset_code);

INSERT INTO data_sources (id, name, type, status, jdbc_url, username, password, field_mapping_json, created_at, updated_at)
VALUES
('ds-sales', 'Sales Warehouse', 'postgresql', 'active', NULL, NULL, NULL, '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('ds-finance', 'Finance Mart', 'postgresql', 'active', NULL, NULL, NULL, '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('ds-crm', 'CRM Analytics', 'postgresql', 'active', NULL, NULL, NULL, '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('ds-marketing', 'Marketing Insights', 'postgresql', 'active', NULL, NULL, NULL, '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('ds-monitoring', 'Operational Metrics', 'postgresql', 'active', NULL, NULL, NULL, '{"metricField":"metric_code","dateField":"point_date","valueField":"value"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    status = EXCLUDED.status,
    field_mapping_json = EXCLUDED.field_mapping_json,
    updated_at = CURRENT_TIMESTAMP;

DELETE FROM analytics_metric_points;
DELETE FROM analytics_category_values;
DELETE FROM analytics_table_rows;
DELETE FROM analytics_list_items;

WITH ds AS (
    SELECT UNNEST(ARRAY['ds-sales', 'ds-finance', 'ds-crm', 'ds-marketing', 'ds-monitoring']) AS data_source_id
),
metrics AS (
    SELECT UNNEST(ARRAY[
        'total_revenue', 'order_count', 'avg_order_value', 'conversion_rate',
        'revenue', 'target', 'profit_margin', 'active_customers',
        'impressions', 'ctr', 'cpa', 'roi',
        'uptime', 'response_time_avg', 'requests_per_minute', 'error_rate',
        'memory_usage_percent'
    ]) AS metric_code
),
days AS (
    SELECT GENERATE_SERIES(CURRENT_DATE - INTERVAL '13 day', CURRENT_DATE, INTERVAL '1 day')::date AS point_date
)
INSERT INTO analytics_metric_points (data_source_id, metric_code, point_date, value, target_value)
SELECT
    ds.data_source_id,
    metrics.metric_code,
    days.point_date,
    ROUND((60 + RANDOM() * 1200)::numeric, 2),
    ROUND((65 + RANDOM() * 1180)::numeric, 2)
FROM ds
CROSS JOIN metrics
CROSS JOIN days;

INSERT INTO analytics_category_values (data_source_id, metric_code, dimension_key, dimension_label, value)
VALUES
('ds-sales', 'revenue', 'north', 'North', 420.50),
('ds-sales', 'revenue', 'south', 'South', 390.90),
('ds-sales', 'revenue', 'east', 'East', 365.40),
('ds-sales', 'revenue', 'west', 'West', 355.10),
('ds-sales', 'revenue', 'online', 'Online', 520.70),
('ds-marketing', 'roi', 'search', 'Search', 142.20),
('ds-marketing', 'roi', 'social', 'Social', 118.50),
('ds-marketing', 'roi', 'email', 'Email', 128.40),
('ds-marketing', 'roi', 'affiliate', 'Affiliate', 112.60),
('ds-finance', 'revenue', 'enterprise', 'Enterprise', 680.00),
('ds-finance', 'revenue', 'smb', 'SMB', 420.00),
('ds-finance', 'revenue', 'consumer', 'Consumer', 300.00),
('ds-monitoring', 'error_rate', 'api', 'API', 1.80),
('ds-monitoring', 'error_rate', 'web', 'Web', 1.20),
('ds-monitoring', 'error_rate', 'worker', 'Worker', 0.70);

INSERT INTO analytics_table_rows (data_source_id, dataset_code, row_key, name, value, trend, owner, updated_at)
VALUES
('ds-sales', 'top_products', 'prd-1', 'Pro Plan', 1250.00, 8.40, 'Team 1', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('ds-sales', 'top_products', 'prd-2', 'Business Pack', 980.00, 6.10, 'Team 2', CURRENT_TIMESTAMP - INTERVAL '2 day'),
('ds-sales', 'top_products', 'prd-3', 'Starter Plan', 730.00, 4.20, 'Team 1', CURRENT_TIMESTAMP - INTERVAL '3 day'),
('ds-sales', 'top_products', 'prd-4', 'Premium Add-on', 620.00, 3.70, 'Team 3', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('ds-marketing', 'campaigns', 'cmp-1', 'Summer Growth', 340.00, 5.80, 'Team 1', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('ds-marketing', 'campaigns', 'cmp-2', 'Search Boost', 290.00, 3.10, 'Team 2', CURRENT_TIMESTAMP - INTERVAL '2 day'),
('ds-marketing', 'campaigns', 'cmp-3', 'Email Nurture', 250.00, 2.80, 'Team 2', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('ds-crm', 'top_customers', 'cus-1', 'Aster Corp', 510.00, 7.20, 'Team 1', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('ds-crm', 'top_customers', 'cus-2', 'Nova Retail', 470.00, 4.90, 'Team 3', CURRENT_TIMESTAMP - INTERVAL '2 day');

INSERT INTO analytics_list_items (data_source_id, dataset_code, label, value, status, sort_order)
VALUES
('ds-monitoring', 'services', 'api-gateway', 99.80, 'healthy', 1),
('ds-monitoring', 'services', 'payments', 99.10, 'healthy', 2),
('ds-monitoring', 'services', 'notification', 96.40, 'warning', 3),
('ds-monitoring', 'services', 'reporting', 98.70, 'healthy', 4),
('ds-crm', 'top_customers', 'Aster Corp', 510.00, 'healthy', 1),
('ds-crm', 'top_customers', 'Nova Retail', 470.00, 'healthy', 2),
('ds-crm', 'top_customers', 'Sunrise Group', 430.00, 'warning', 3);

CREATE TABLE IF NOT EXISTS dashboards (
    id VARCHAR(80) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    visibility VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    current_version_no INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS widget_types (
    id VARCHAR(80) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    category VARCHAR(50) NOT NULL,
    icon VARCHAR(80),
    props_schema_json TEXT NOT NULL,
    default_props_json TEXT NOT NULL,
    is_active BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS dashboard_widgets (
    id VARCHAR(80) PRIMARY KEY,
    dashboard_id VARCHAR(80) NOT NULL,
    widget_type_code VARCHAR(50) NOT NULL,
    title VARCHAR(150),
    props_json TEXT NOT NULL,
    data_source_id VARCHAR(80),
    query_config_json TEXT,
    refresh_interval_sec INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_dashboard_widgets_dashboard FOREIGN KEY (dashboard_id) REFERENCES dashboards(id)
);

CREATE TABLE IF NOT EXISTS widget_layouts (
    id VARCHAR(80) PRIMARY KEY,
    dashboard_id VARCHAR(80) NOT NULL,
    widget_id VARCHAR(80) NOT NULL,
    breakpoint VARCHAR(20) NOT NULL,
    x INTEGER NOT NULL,
    y INTEGER NOT NULL,
    w INTEGER NOT NULL,
    h INTEGER NOT NULL,
    is_static BOOLEAN NOT NULL,
    CONSTRAINT fk_widget_layouts_dashboard FOREIGN KEY (dashboard_id) REFERENCES dashboards(id),
    CONSTRAINT fk_widget_layouts_widget FOREIGN KEY (widget_id) REFERENCES dashboard_widgets(id)
);

CREATE TABLE IF NOT EXISTS filter_options (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL
);

CREATE INDEX idx_type_global_filters ON filter_options(type);

CREATE INDEX IF NOT EXISTS idx_dashboards_updated_at ON dashboards(updated_at);
CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_dashboard_id ON dashboard_widgets(dashboard_id);
CREATE INDEX IF NOT EXISTS idx_widget_layouts_dashboard_id ON widget_layouts(dashboard_id);

INSERT INTO widget_types (id, code, name, category, icon, props_schema_json, default_props_json, is_active)
VALUES
('wt-kpi-card', 'kpi-card', 'KPI Card', 'metrics', 'chart-bar', '{"type":"object"}', '{"format":"currency"}', TRUE),
('wt-line-chart', 'line-chart', 'Line Chart', 'chart', 'chart-line', '{"type":"object"}', '{"range":"30d"}', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO dashboards (id, name, description, visibility, status, current_version_no, created_at, updated_at)
VALUES ('db-sales-main', 'Sales Dashboard', 'Seed dashboard for local bootstrap', 'private', 'draft', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

INSERT INTO dashboard_widgets (id, dashboard_id, widget_type_code, title, props_json, data_source_id, query_config_json, refresh_interval_sec, created_at, updated_at)
VALUES ('w-kpi-1', 'db-sales-main', 'kpi-card', 'Revenue Today', '{"format":"currency","color":"green"}', 'ds-sales', '{"metric":"revenue_daily"}', 60, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

INSERT INTO widget_layouts (id, dashboard_id, widget_id, breakpoint, x, y, w, h, is_static)
VALUES
('lay-seed-lg', 'db-sales-main', 'w-kpi-1', 'lg', 0, 0, 4, 3, FALSE),
('lay-seed-md', 'db-sales-main', 'w-kpi-1', 'md', 0, 0, 6, 3, FALSE)
ON CONFLICT (id) DO NOTHING;

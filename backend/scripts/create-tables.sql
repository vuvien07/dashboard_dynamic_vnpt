-- Create schema for dashboard-dynmic (PostgreSQL)
-- Safe to run multiple times (idempotent via IF NOT EXISTS)

BEGIN;

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
    CONSTRAINT fk_dashboard_widgets_dashboard
        FOREIGN KEY (dashboard_id) REFERENCES dashboards(id)
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
    CONSTRAINT fk_widget_layouts_dashboard
        FOREIGN KEY (dashboard_id) REFERENCES dashboards(id),
    CONSTRAINT fk_widget_layouts_widget
        FOREIGN KEY (widget_id) REFERENCES dashboard_widgets(id)
);

CREATE INDEX IF NOT EXISTS idx_dashboards_updated_at
    ON dashboards(updated_at);

CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_dashboard_id
    ON dashboard_widgets(dashboard_id);

CREATE INDEX IF NOT EXISTS idx_widget_layouts_dashboard_id
    ON widget_layouts(dashboard_id);

COMMIT;

export interface DashboardListItem {
  id: string;
  name: string;
  visibility: string;
  status: string;
  updatedAt: string;
}

export interface DashboardMeta {
  id: string;
  name: string;
  versionNo: number;
}

export interface CreateDashboardRequest {
  name: string;
  description?: string;
  visibility?: string;
}

export interface WidgetConfigItem {
  id: string;
  widgetTypeCode: string;
  title?: string;
  props: Record<string, unknown>;
  dataSourceId?: string;
  queryConfig?: Record<string, unknown>;
  refreshIntervalSec?: number;
}

export interface FilterConfigItem {
  id: string;
  label: string;
  placeholder: string;
  type: string;
  targetTable: string;
  targetField: string;
  fieldType: string;
  aggregateFunction: string;
  value: any;
  dashboardWidgetIds: string[];
}

export interface LayoutItem {
  widgetId: string;
  x: number;
  y: number;
  w: number;
  h: number;
  static: boolean;
}

export interface DashboardConfigResponse {
  dashboard: DashboardMeta;
  widgets: WidgetConfigItem[];
  layouts: Record<string, LayoutItem[]>;
  filterLayouts: Record<string, LayoutItem[]>;
  filters: FilterConfigItem[];
}

export interface SaveDashboardConfigRequest {
  expectedVersionNo: number;
  widgets: WidgetConfigItem[];
  filters: FilterConfigItem[];
  layouts: Record<string, LayoutItem[]>;
  filterLayouts: Record<string, LayoutItem[]>;
  filterIds: string[];
  changeNote?: string;
}

export interface SaveDashboardConfigResponse {
  versionNo: number;
  updatedAt: string;
}

export interface DataSourceItem {
  id: string;
  name: string;
  type: string;
  status: string;
}

export interface DataSourceDetail {
  id: string;
  name: string;
  type: string;
  status: string;
  jdbcUrl?: string;
  username?: string;
  fieldMapping: Record<string, unknown>;
}

export interface DataSourceUpsertRequest {
  id: string;
  name: string;
  type: string;
  status: string;
  jdbcUrl?: string;
  username?: string;
  password?: string;
  fieldMapping?: Record<string, unknown>;
}

export interface DataSourceTestConnectionResponse {
  dataSourceId: string;
  success: boolean;
  message: string;
}

export interface DataSourceQueryRequest {
  widgetId: string;
  dataSourceId: string;
  widgetTypeCode?: string;
  queryConfig?: Record<string, unknown>;
  filters: FilterConfigItem[];
}

export interface DataSourceQueryResponse {
  dataSourceId: string;
  shape: 'single' | 'timeseries' | 'category' | 'table' | 'list';
  payload: Record<string, unknown>;
}

export interface OptionItem {
  value: string;
  label: string;
}

export interface SelectOption {
  value: any;
  label: string;
}

export class AnalyticTableSchema {
  constructor(
    public table: string,
    public columns: {
      field: string;
      type: string;
    }[]
  ) {}
}

export type FilterType =
  | 'equals'
  | 'in'
  | 'range'
  | 'less-than'
  | 'less-than-equals'
  | 'greater-than'
  | 'greater-than-equals';
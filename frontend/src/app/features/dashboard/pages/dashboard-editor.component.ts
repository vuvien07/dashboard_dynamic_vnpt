import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { DashboardApiService } from '../../../core/services/dashboard-api.service';
import { AnalyticTableSchema, DashboardConfigResponse, DataSourceItem, FilterConfigItem, FilterType, LayoutItem, OptionItem, SelectOption, WidgetConfigItem } from '../../../core/models/dashboard.models';
import { MultiselectComponent } from '../components/multiselect.component';

@Component({
  selector: 'app-dashboard-editor',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, MultiselectComponent],
  templateUrl: './dashboard-editor.component.html',
  styleUrl: './dashboard-editor.component.scss'
})
export class DashboardEditorComponent {
  private readonly defaultBreakpoints = ['lg', 'md', 'sm'];
  private readonly messageDurationMs = 4000;
  readonly customHtmlPresetOptions = [
    { value: 'single', label: 'Single KPI' },
    { value: 'timeseries', label: 'Timeseries Chart' },
    { value: 'category', label: 'Category Bars' },
    { value: 'table', label: 'Data Table' },
    { value: 'list', label: 'Status List' }
  ];
  private readonly route = inject(ActivatedRoute);
  private readonly api = inject(DashboardApiService);
  private readonly gridRowHeight = 64;
  private draggingWidgetId: string | null = null;
  private draggingFilterId: string | null = null;
  private messageTimerId: number | null = null;
  private messageText = '';
  widgets: SelectOption[] = [];
  selectedWidgets: any[] = [];
  analyticTableAndColumn: AnalyticTableSchema[] = [];
  analyticColumns = signal<string[]>([]);
  filterTypes = signal<OptionItem[]>([]);
  private filterIds: string[] = [];


  config: DashboardConfigResponse | null = null;
  dataSourceOptions: DataSourceItem[] = [];
  selectedBreakpoint = 'lg';
  selectedCustomHtmlPreset = 'single';
  newWidget: {
    id: string;
    title: string;
    widgetTypeCode: string;
    dataSourceId: string;
    x: number;
    y: number;
    width: number;
    height: number;
    applyToAllBreakpoints: boolean;
  } = {
      id: '',
      title: '',
      widgetTypeCode: 'kpi-card',
      dataSourceId: '',
      x: 0,
      y: 0,
      width: 4,
      height: 3,
      applyToAllBreakpoints: true
    };
  newWidgetQueryConfigText = this.customHtmlPreset('single').queryConfig;
  newWidgetHtmlTemplate = this.customHtmlPreset('single').html;
  newWidgetCssTemplate = this.customHtmlPreset('single').css;

  readonly customHtmlEditorOpen = new Set<string>();
  customHtmlEditorState: Record<string, { html: string; css: string }> = {};

  readonly ALL_FILTER_TYPES: Record<FilterType, SelectOption> = {
    'equals': { value: 'equals', label: 'equals' },
    'in': { value: 'in', label: 'in' },
    'range': { value: 'range', label: 'range' },
    'less-than': { value: 'less-than', label: 'less-than' },
    'less-than-equals': { value: 'less-than-equals', label: 'less-than-equals' },
    'greater-than': { value: 'greater-than', label: 'greater-than' },
    'greater-than-equals': { value: 'greater-than-equals', label: 'greater-than-equals' },
  };

  newFilter: {
    id: string;
    title: string;
    placeholder: string;
    type: string;
    targetTable: string;
    targetField: string;
    fieldType: string;
    aggregateFunction: string;
    x: number;
    y: number;
    width: number;
    applyToAllBreakpoints: boolean;
  } = {
      id: '',
      title: '',
      placeholder: '',
      type: '',
      targetTable: '',
      targetField: '',
      fieldType: '',
      aggregateFunction: '',
      x: 0,
      y: 0,
      width: 4,
      applyToAllBreakpoints: true
    };

  get message(): string {
    return this.messageText;
  }

  set message(value: string) {
    this.messageText = value;

    if (this.messageTimerId !== null) {
      window.clearTimeout(this.messageTimerId);
      this.messageTimerId = null;
    }

    if (!value) {
      return;
    }

    this.messageTimerId = window.setTimeout(() => {
      this.messageText = '';
      this.messageTimerId = null;
    }, this.messageDurationMs);
  }

  isCustomHtml(typeCode: string): boolean {
    return typeCode === 'custom.html';
  }

  closeMessage(): void {
    this.message = '';
  }

  openCustomHtmlEditor(widget: WidgetConfigItem): void {
    this.customHtmlEditorOpen.add(widget.id);
    this.customHtmlEditorState[widget.id] = {
      html: String((widget.props['htmlTemplate'] as string) ?? ''),
      css: String((widget.props['cssTemplate'] as string) ?? '')
    };
  }

  closeCustomHtmlEditor(widgetId: string): void {
    this.customHtmlEditorOpen.delete(widgetId);
    delete this.customHtmlEditorState[widgetId];
  }

  applyCustomHtmlPreset(): void {
    const preset = this.customHtmlPreset(this.selectedCustomHtmlPreset);
    this.newWidgetQueryConfigText = preset.queryConfig;
    this.newWidgetHtmlTemplate = preset.html;
    this.newWidgetCssTemplate = preset.css;
    if (!this.newWidget.title.trim()) {
      this.newWidget.title = preset.title;
    }
    this.message = `Đã áp dụng mẫu custom.html: ${preset.title}.`;
  }

  applyCustomHtmlEdit(widget: WidgetConfigItem): void {
    const state = this.customHtmlEditorState[widget.id];
    if (!state) {
      return;
    }
    widget.props = { ...widget.props, htmlTemplate: state.html, cssTemplate: state.css };
    this.closeCustomHtmlEditor(widget.id);
    this.message = `Đã cập nhật HTML/CSS cho widget ${widget.id}. Nhấn Save layout để lưu.`;
  }

  constructor() {
    this.loadDataSourceOptions();

    const dashboardId = this.route.snapshot.paramMap.get('dashboardId');
    if (!dashboardId) {
      this.message = 'Không tìm thấy dashboardId trên URL.';
      return;
    }

    this.api.getDashboardConfig(dashboardId).subscribe((response) => {
      this.config = response;
      this.ensureDefaultBreakpoints();
      this.selectedBreakpoint = 'lg';
      this.widgets = response.widgets.map((widget) => ({ label: widget.title!, value: widget.id }));
      this.filterIds = response.filters.map((filter) => filter.id);
      console.log(this.filterIds);
    });

    this.api.listAnalyticTablesAndColumns().subscribe((response) => {
      this.analyticTableAndColumn = Object.keys(response).map((key) => new AnalyticTableSchema(key, response[key]));
    });
  }

  private loadDataSourceOptions(): void {
    this.api.listDataSources().subscribe({
      next: (response) => {
        this.dataSourceOptions = response.items;
      },
      error: () => {
        this.dataSourceOptions = [];
      }
    });
  }

  availableBreakpoints(): string[] {
    if (!this.config) {
      return [...this.defaultBreakpoints];
    }

    this.ensureDefaultBreakpoints();
    const keys = Object.keys(this.config.layouts);
    if (keys.length === 0) {
      return [...this.defaultBreakpoints];
    }

    return [...keys].sort((a, b) => {
      const indexA = this.defaultBreakpoints.indexOf(a);
      const indexB = this.defaultBreakpoints.indexOf(b);

      if (indexA !== -1 || indexB !== -1) {
        if (indexA === -1) {
          return 1;
        }
        if (indexB === -1) {
          return -1;
        }
        return indexA - indexB;
      }

      return a.localeCompare(b);
    });
  }

  currentLayouts(): LayoutItem[] {
    if (!this.config) {
      return [];
    }

    return this.config.layouts[this.selectedBreakpoint] ?? [];
  }

  currentFilterLayouts(): LayoutItem[] {
    if (!this.config) {
      return [];
    }

    return this.config.filterLayouts[this.selectedBreakpoint] ?? [];
  }

  orderedWidgets(): WidgetConfigItem[] {
    if (!this.config) {
      return [];
    }

    const map = this.currentLayoutMap();
    return [...this.config.widgets].sort((a, b) => {
      const la = map.get(a.id);
      const lb = map.get(b.id);
      if (!la && !lb) {
        return 0;
      }
      if (!la) {
        return 1;
      }
      if (!lb) {
        return -1;
      }

      if (la.y !== lb.y) {
        return la.y - lb.y;
      }
      return la.x - lb.x;
    });
  }

  orderedFilters(): FilterConfigItem[] {
    if (!this.config) {
      return [];
    }

    const map = this.currentFilterLayoutMap();
    return [...this.config.filters].sort((a, b) => {
      const la = map.get(a.id);
      const lb = map.get(b.id);
      if (!la && !lb) {
        return 0;
      }
      if (!la) {
        return 1;
      }
      if (!lb) {
        return -1;
      }

      if (la.y !== lb.y) {
        return la.y - lb.y;
      }
      return la.x - lb.x;
    });
  }

  trackByWidgetId(_index: number, widget: WidgetConfigItem): string {
    return widget.id;
  }

  trackByFilterId(_index: number, widget: FilterConfigItem): string {
    return widget.id;
  }

  onBreakpointChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.selectedBreakpoint = target.value;
  }

  onDatasetChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const findTable = this.analyticTableAndColumn.find((table) => table.table === target.value);
    if (!findTable) {
      this.analyticColumns.set([]);
      return;
    }
    this.analyticColumns.set(findTable.columns.map((column) => column.field));
  }

  onColumnWithDatasetChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    if (target.value === '') {
      this.newFilter.fieldType = '';
      this.filterTypes.set([]);
      return;
    }
    const findColumn = this.analyticTableAndColumn.find((table) =>
      table.table === this.newFilter.targetTable)?.columns
      .find((column) => column.field === target.value);
    if (!findColumn) {
      this.newFilter.fieldType = '';
      return;
    }
    this.newFilter.fieldType = findColumn.type;
    this.filterTypes.set(this.resolveAvailableFilterTypes(findColumn.type));
  }

  gridTemplateColumns(): string {
    const columns = this.columnsFor(this.selectedBreakpoint);
    return `repeat(${columns}, minmax(0, 1fr))`;
  }

  widgetGridColumn(widgetId: string): string {
    const item = this.layoutByWidgetId(widgetId);
    if (!item) {
      return 'auto';
    }

    return `${item.x + 1} / span ${item.w}`;
  }

  widgetGridRow(widgetId: string): string {
    const item = this.layoutByWidgetId(widgetId);
    if (!item) {
      return 'auto';
    }

    return `${item.y + 1} / span ${item.h}`;
  }

  filterGridColumn(filterId: string): string {
    const item = this.layoutByFilterId(filterId);
    if (!item) {
      return 'auto';
    }

    return `${item.x + 1} / span ${item.w}`;
  }

  filterGridRow(filterId: string): string {
    const item = this.layoutByFilterId(filterId);
    if (!item) {
      return 'auto';
    }

    return `${item.y + 1} / span ${item.h}`;
  }

  layoutByWidgetId(widgetId: string): LayoutItem | undefined {
    return this.currentLayoutMap().get(widgetId);
  }

  layoutByFilterId(filterId: string): LayoutItem | undefined {
    return this.currentFilterLayoutMap().get(filterId);
  }

  onWidgetDragStart(widgetId: string): void {
    this.draggingWidgetId = widgetId;
    this.message = '';
  }

  onWidgetDragEnd(): void {
    this.draggingWidgetId = null;
  }

  onFilterDragStart(filterId: string): void {
    this.draggingFilterId = filterId;
    this.message = '';
  }

  onFilterDragEnd(): void {
    this.draggingFilterId = null;
  }

  onGridDragOver(event: DragEvent): void {
    event.preventDefault();
  }

  onGridDrop(event: DragEvent): void {
    event.preventDefault();
    if (!this.draggingWidgetId) {
      return;
    }

    const target = event.currentTarget as HTMLElement | null;
    if (!target) {
      return;
    }

    const layout = this.layoutByWidgetId(this.draggingWidgetId);
    if (!layout) {
      return;
    }

    const rect = target.getBoundingClientRect();
    const columns = this.columnsFor(this.selectedBreakpoint);
    const columnWidth = rect.width / columns;
    const rawX = Math.floor((event.clientX - rect.left) / columnWidth);
    const rawY = Math.floor((event.clientY - rect.top) / this.gridRowHeight);

    layout.x = this.clamp(rawX, 0, Math.max(0, columns - layout.w));
    layout.y = Math.max(0, rawY);
    this.message = `Đã cập nhật vị trí widget ${this.draggingWidgetId}. Nhấn Save layout để lưu.`;
  }

  onFilterGridDrop(event: DragEvent): void {
    event.preventDefault();
    if (!this.draggingFilterId) {
      return;
    }

    const target = event.currentTarget as HTMLElement | null;
    if (!target) {
      return;
    }

    const layout = this.layoutByFilterId(this.draggingFilterId);
    if (!layout) {
      return;
    }

    const rect = target.getBoundingClientRect();
    const columns = this.columnsFor(this.selectedBreakpoint);
    const columnWidth = rect.width / columns;
    const rawX = Math.floor((event.clientX - rect.left) / columnWidth);
    const rawY = Math.floor((event.clientY - rect.top) / this.gridRowHeight);

    layout.x = this.clamp(rawX, 0, Math.max(0, columns - layout.w));
    layout.y = Math.max(0, rawY);
    this.message = `Đã cập nhật vị trí filter ${this.draggingWidgetId}. Nhấn Save layout để lưu.`;
  }

  resizeWidget(widgetId: string, deltaW: number, deltaH: number): void {
    const layout = this.layoutByWidgetId(widgetId);
    if (!layout) {
      return;
    }

    const columns = this.columnsFor(this.selectedBreakpoint);
    const nextW = this.clamp(layout.w + deltaW, 1, columns - layout.x);
    const nextH = this.clamp(layout.h + deltaH, 1, 20);
    layout.w = nextW;
    layout.h = nextH;
    this.message = `Đã cập nhật kích thước widget ${widgetId} thành ${layout.w}x${layout.h}.`;
  }

  resizeFilter(filterId: string, deltaW: number, deltaH: number): void {
    const layout = this.layoutByFilterId(filterId);
    if (!layout) {
      return;
    }

    const columns = this.columnsFor(this.selectedBreakpoint);
    const nextW = this.clamp(layout.w + deltaW, 1, columns - layout.x);
    const nextH = this.clamp(layout.h + deltaH, 1, 20);
    layout.w = nextW;
    layout.h = nextH;
    this.message = `Đã cập nhật kích thước filter ${filterId} thành ${layout.w}x${layout.h}.`;
  }

  moveWidget(widgetId: string, deltaX: number, deltaY: number): void {
    const layout = this.layoutByWidgetId(widgetId);
    if (!layout) {
      return;
    }

    const columns = this.columnsFor(this.selectedBreakpoint);
    const nextX = this.clamp(layout.x + deltaX, 0, Math.max(0, columns - layout.w));
    const nextY = Math.max(0, layout.y + deltaY);

    layout.x = nextX;
    layout.y = nextY;
    this.message = `Đã di chuyển widget ${widgetId} tới x=${layout.x}, y=${layout.y}.`;
  }

  moveFilter(filterId: string, deltaX: number, deltaY: number): void {
    const layout = this.layoutByFilterId(filterId);
    if (!layout) {
      return;
    }

    const columns = this.columnsFor(this.selectedBreakpoint);
    const nextX = this.clamp(layout.x + deltaX, 0, Math.max(0, columns - layout.w));
    const nextY = Math.max(0, layout.y + deltaY);

    layout.x = nextX;
    layout.y = nextY;
    this.message = `Đã di chuyển filter ${filterId} tới x=${layout.x}, y=${layout.y}.`;
  }

  onWidgetKeyMove(event: KeyboardEvent, widgetId: string): void {
    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        this.moveWidget(widgetId, -1, 0);
        break;
      case 'ArrowRight':
        event.preventDefault();
        this.moveWidget(widgetId, 1, 0);
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.moveWidget(widgetId, 0, -1);
        break;
      case 'ArrowDown':
        event.preventDefault();
        this.moveWidget(widgetId, 0, 1);
        break;
      default:
        break;
    }
  }

  onFilterKeyMove(event: KeyboardEvent, filterId: string): void {
    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        this.moveFilter(filterId, -1, 0);
        break;
      case 'ArrowRight':
        event.preventDefault();
        this.moveFilter(filterId, 1, 0);
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.moveFilter(filterId, 0, -1);
        break;
      case 'ArrowDown':
        event.preventDefault();
        this.moveFilter(filterId, 0, 1);
        break;
      default:
        break;
    }
  }

  addWidget(): void {
    if (!this.config) {
      return;
    }

    const id = this.newWidget.id.trim();
    if (!id) {
      this.message = 'Widget ID là bắt buộc.';
      return;
    }

    if (this.config.widgets.some((item) => item.id === id)) {
      this.message = `Widget ID ${id} đã tồn tại.`;
      return;
    }

    let queryConfig: Record<string, unknown> | undefined;
    try {
      queryConfig = this.newWidgetQueryConfigText.trim()
        ? (JSON.parse(this.newWidgetQueryConfigText) as Record<string, unknown>)
        : undefined;
    } catch {
      this.message = 'Query config JSON không hợp lệ.';
      return;
    }

    const isCustomHtml = (this.newWidget.widgetTypeCode.trim() || 'kpi-card') === 'custom.html';
    const widget: WidgetConfigItem = {
      id,
      title: this.newWidget.title.trim() || id,
      widgetTypeCode: this.newWidget.widgetTypeCode.trim() || 'kpi-card',
      props: isCustomHtml
        ? { htmlTemplate: this.newWidgetHtmlTemplate, cssTemplate: this.newWidgetCssTemplate }
        : {},
      dataSourceId: this.newWidget.dataSourceId.trim() || undefined,
      queryConfig,
      refreshIntervalSec: 60
    };

    this.config.widgets = [...this.config.widgets, widget];
    const inputX = this.toInt(this.newWidget.x, 0);
    const inputY = this.toInt(this.newWidget.y, 0);
    const inputW = this.toInt(this.newWidget.width, 4);
    const inputH = this.toInt(this.newWidget.height, 3);

    const targetBreakpoints = this.newWidget.applyToAllBreakpoints
      ? this.availableBreakpoints()
      : [this.selectedBreakpoint];

    for (const breakpoint of targetBreakpoints) {
      const layouts = this.config.layouts[breakpoint] ?? [];
      const columns = this.columnsFor(breakpoint);
      const clampedX = this.clamp(inputX, 0, Math.max(0, columns - 1));
      const clampedW = this.clamp(inputW, 1, Math.max(1, columns - clampedX));
      const clampedH = this.clamp(inputH, 1, 20);
      const clampedY = Math.max(0, inputY);
      layouts.push({
        widgetId: id,
        x: clampedX,
        y: clampedY,
        w: clampedW,
        h: clampedH,
        static: false
      });
      this.config.layouts[breakpoint] = layouts;
    }

    const targetNote = this.newWidget.applyToAllBreakpoints
      ? 'tất cả breakpoint'
      : `breakpoint ${this.selectedBreakpoint.toUpperCase()}`;
    this.message = `Đã thêm widget ${id} tại (${inputX},${inputY}) kích thước ${inputW}x${inputH} cho ${targetNote}. Nhấn Save layout để lưu.`;
    this.resetNewWidgetForm();
  }

  removeWidget(widgetId: string): void {
    if (!this.config) {
      return;
    }

    this.config.widgets = this.config.widgets.filter((item) => item.id !== widgetId);
    this.widgets = this.widgets.filter((item) => item.value !== widgetId);
    this.selectedWidgets = this.selectedWidgets.filter((item) => item !== widgetId);

    for (const breakpoint of this.availableBreakpoints()) {
      const layouts = this.config.layouts[breakpoint] ?? [];
      this.config.layouts[breakpoint] = layouts.filter((item) => item.widgetId !== widgetId);
    }

    this.config.filters = this.config.filters.filter((item) => !item.dashboardWidgetIds.includes(widgetId));

    this.message = `Đã xóa widget ${widgetId}. Nhấn Save layout để lưu.`;
  }

  removeFilter(filterId: string): void {
    if (!this.config) {
      return;
    }

    this.config.filters = this.config.filters.filter((item) => item.id !== filterId);

    for (const breakpoint of this.availableBreakpoints()) {
      const layouts = this.config.filterLayouts[breakpoint] ?? [];
      this.config.filterLayouts[breakpoint] = layouts.filter((item) => item.widgetId !== filterId);
    }

    this.message = `Đã xóa filter ${filterId}. Nhấn Save layout để lưu.`;
  }

  saveLayout(): void {
    if (!this.config) {
      return;
    }

    const dashboardId = this.config.dashboard.id;
    const widgets = this.config.widgets;
    const layouts = this.config.layouts;
    const filters = this.config.filters;
    const filterLayouts = this.config.filterLayouts;
    const filterIds = this.filterIds;

    this.saveLayoutWithVersion(dashboardId, this.config.dashboard.versionNo, widgets, filters, layouts, filterLayouts, filterIds, false);
  }

  private saveLayoutWithVersion(
    dashboardId: string,
    expectedVersionNo: number,
    widgets: WidgetConfigItem[],
    filters: FilterConfigItem[],
    layouts: Record<string, LayoutItem[]>,
    filterLayouts: Record<string, LayoutItem[]>,
    filterIds: string[],
    hasRetried: boolean
  ): void {
    const payload = {
      expectedVersionNo,
      widgets,
      layouts,
      filters,
      filterLayouts,
      filterIds,
      changeNote: 'Save from Angular visual customize'
    };

    this.api.saveDashboardConfig(dashboardId, payload).subscribe({
      next: (response) => {
        this.message = `Đã lưu thành công, version mới: ${response.versionNo}`;
        if (this.config) {
          this.config.dashboard.versionNo = response.versionNo;
        }
      },
      error: (error: HttpErrorResponse) => {
        const backendMessage = error?.error?.message;
        const isConflict = error.status === 409 || backendMessage === 'VERSION_CONFLICT';

        if (isConflict && !hasRetried) {
          this.message = 'Phát hiện xung đột phiên bản. Đang đồng bộ version mới nhất và thử lưu lại...';
          this.api.getDashboardConfig(dashboardId).subscribe({
            next: (latest) => {
              this.saveLayoutWithVersion(dashboardId, latest.dashboard.versionNo, widgets, filters, layouts, filterLayouts, filterIds, true);
            },
            error: () => {
              this.message =
                'Xung đột phiên bản và không thể đồng bộ version mới. Vui lòng tải lại trang rồi thử lại.';
            }
          });
          return;
        }

        if (isConflict) {
          this.message =
            'Không thể lưu do xung đột phiên bản sau khi thử lại. Vui lòng tải lại trang để lấy cấu hình mới nhất.';
          return;
        }

        this.message = `Lưu thất bại: ${backendMessage || 'Vui lòng thử lại.'}`;
      }
    });
  }

  private currentLayoutMap(): Map<string, LayoutItem> {
    return new Map(this.currentLayouts().map((item) => [item.widgetId, item]));
  }

  private currentFilterLayoutMap(): Map<string, LayoutItem> {
    return new Map(this.currentFilterLayouts().map((item) => [item.widgetId, item]));
  }

  private ensureDefaultBreakpoints(): void {
    if (!this.config) {
      return;
    }

    for (const breakpoint of this.defaultBreakpoints) {
      if (!Array.isArray(this.config.layouts[breakpoint])) {
        this.config.layouts[breakpoint] = [];
      }
    }
  }

  addFilter(): void {
    const errorMessage = this.validateAddFilterForm();
    if (!this.config || errorMessage) {
      this.message = errorMessage!;
      return;
    }


    const id = this.newFilter.id.trim();
    const filter: FilterConfigItem = {
      id,
      label: this.newFilter.title.trim(),
      placeholder: this.newFilter.placeholder.trim(),
      fieldType: this.newFilter.fieldType,
      targetTable: this.newFilter.targetTable,
      targetField: this.newFilter.targetField,
      type: this.newFilter.type,
      aggregateFunction: this.newFilter.aggregateFunction,
      value: undefined,
      dashboardWidgetIds: this.selectedWidgets
    };

    this.config.filters = [...this.config.filters, filter];
    const inputX = this.toInt(this.newFilter.x, 0);
    const inputY = this.toInt(this.newFilter.y, 0);
    const inputW = this.toInt(this.newFilter.width, 4);
    const inputH = 2;

    const targetBreakpoints = this.newFilter.applyToAllBreakpoints
      ? this.availableBreakpoints()
      : [this.selectedBreakpoint];

    for (const breakpoint of targetBreakpoints) {
      const layouts = this.config.filterLayouts[breakpoint] ?? [];
      const columns = this.columnsFor(breakpoint);
      const clampedX = this.clamp(inputX, 0, Math.max(0, columns - 1));
      const clampedW = this.clamp(inputW, 1, Math.max(1, columns - clampedX));
      const clampedH = this.clamp(inputH, 1, 20);
      const clampedY = Math.max(0, inputY);
      layouts.push({
        widgetId: id,
        x: clampedX,
        y: clampedY,
        w: clampedW,
        h: clampedH,
        static: false
      });
      this.config.filterLayouts[breakpoint] = layouts;
    }

    const targetNote = this.newFilter.applyToAllBreakpoints
      ? 'tất cả breakpoint'
      : `breakpoint ${this.selectedBreakpoint.toUpperCase()}`;
    this.message = `Đã thêm filter ${id} tại (${inputX},${inputY}) kích thước ${inputW}x${inputH} cho ${targetNote}. Nhấn Save layout để lưu.`;
    this.resetNewFilterForm();
  }

  private validateAddFilterForm(): string | null {
    if (this.newFilter.id.trim().length === 0) {
      return 'Vui lòng nhập ID cho filter.';
    }
    if (this.newFilter.title.trim().length === 0) {
      return 'Vui lòng nhập tiêu đề cho filter.';
    }
    if (this.newFilter.type.length === 0) {
      return 'Vui lòng nhập thể loại filter.';
    }
    if (this.newFilter.targetTable.length === 0) {
      return 'Vui lòng chọn dataset cho filter.';
    }
    if (this.newFilter.targetField.length === 0) {
      return `Vui lòng chọn cột cho dataset ${this.newFilter.targetTable}.`;
    }
    if (this.selectedWidgets.length === 0) {
      return `Vui lòng chọn widget cho filter.`;
    }
    return null;
  }

  private columnsFor(breakpoint: string): number {
    if (breakpoint === 'lg') {
      return 12;
    }
    if (breakpoint === 'md') {
      return 6;
    }
    return 1;
  }

  private nextLayoutY(layouts: LayoutItem[]): number {
    if (layouts.length === 0) {
      return 0;
    }

    let max = 0;
    for (const row of layouts) {
      max = Math.max(max, row.y + row.h);
    }

    return max;
  }

  private resetNewWidgetForm(): void {
    this.selectedCustomHtmlPreset = 'single';
    this.newWidget = {
      id: '',
      title: '',
      widgetTypeCode: 'kpi-card',
      dataSourceId: '',
      x: 0,
      y: 0,
      width: 4,
      height: 3,
      applyToAllBreakpoints: true
    };
    const preset = this.customHtmlPreset(this.selectedCustomHtmlPreset);
    this.newWidgetQueryConfigText = preset.queryConfig;
    this.newWidgetHtmlTemplate = preset.html;
    this.newWidgetCssTemplate = preset.css;
  }

  private resetNewFilterForm(): void {
    this.newFilter = {
      id: '',
      title: '',
      placeholder: '',
      type: '',
      targetTable: '',
      targetField: '',
      fieldType: '',
      aggregateFunction: '',
      x: 0,
      y: 0,
      width: 4,
      applyToAllBreakpoints: true
    };
  }

  private customHtmlPreset(presetKey: string): { title: string; queryConfig: string; html: string; css: string } {
    switch (presetKey) {
      case 'timeseries':
        return {
          title: 'Timeseries Chart',
          queryConfig: '{\n  "shape": "timeseries",\n  "metrics": ["revenue", "cost"]\n}',
          html: `<div class="ts-card">
  <div class="ts-head">
    <div>
      <div class="ts-kicker">TIMESERIES</div>
      <h3 class="ts-title">{{shape}}</h3>
    </div>
    <div class="ts-count" id="ts-count"></div>
  </div>
  <svg id="ts-chart" class="ts-chart" viewBox="0 0 320 160" preserveAspectRatio="none"></svg>
  <div id="ts-legend" class="ts-legend"></div>
</div>
<script>
(() => {
  const widgetData = window.WIDGET_DATA || {};
  const payload = widgetData.payload || {};
  const labels = Array.isArray(payload.labels) ? payload.labels : [];
  const series = Array.isArray(payload.series) ? payload.series : [];
  const colors = ['#38bdf8', '#f97316', '#22c55e', '#a78bfa'];
  const width = 320;
  const height = 160;
  const padding = 12;
  const svg = document.getElementById('ts-chart');
  const legend = document.getElementById('ts-legend');
  const count = document.getElementById('ts-count');
  const allValues = [];

  for (const item of series) {
    const values = Array.isArray(item?.data) ? item.data : [];
    for (const value of values) {
      allValues.push(Number(value || 0));
    }
  }

  const max = Math.max(1, ...allValues);
  const step = labels.length > 1 ? (width - padding * 2) / (labels.length - 1) : width - padding * 2;
  const paths = series.map((item, index) => {
    const values = Array.isArray(item?.data) ? item.data : [];
    const color = colors[index % colors.length];
    const points = values.map((value, pointIndex) => {
      const x = padding + step * pointIndex;
      const y = height - padding - (Number(value || 0) / max) * (height - padding * 2);
      return x + ',' + y;
    }).join(' ');
    return '<polyline fill="none" stroke="' + color + '" stroke-width="3" points="' + points + '"></polyline>';
  }).join('');

  svg.innerHTML = '<line x1="12" y1="148" x2="308" y2="148" stroke="rgba(148,163,184,0.25)" />' + paths;
  legend.innerHTML = series.map((item, index) => '<span class="ts-pill"><i style="background:' + colors[index % colors.length] + '"></i>' + (item?.name || 'Series') + '</span>').join('');
  count.textContent = labels.length + ' điểm';
})();
</script>`,
          css: `.ts-card{height:100%;display:flex;flex-direction:column;gap:12px;padding:16px;background:linear-gradient(180deg,#0f172a,#111827);color:#e5eefb;border-radius:14px;font-family:Arial,sans-serif}.ts-head{display:flex;justify-content:space-between;align-items:flex-start;gap:12px}.ts-kicker{font-size:11px;letter-spacing:.12em;color:#7dd3fc;font-weight:700}.ts-title{margin:4px 0 0;font-size:18px;font-weight:700}.ts-count{font-size:12px;color:#93c5fd;background:rgba(59,130,246,.15);border:1px solid rgba(96,165,250,.25);padding:6px 10px;border-radius:999px}.ts-chart{width:100%;height:160px;display:block}.ts-legend{display:flex;flex-wrap:wrap;gap:8px}.ts-pill{display:inline-flex;align-items:center;gap:6px;padding:5px 9px;border-radius:999px;background:rgba(148,163,184,.12);font-size:12px;color:#cbd5e1}.ts-pill i{width:10px;height:10px;border-radius:999px;display:inline-block}`
        };
      case 'category':
        return {
          title: 'Category Bars',
          queryConfig: '{\n  "shape": "category",\n  "metric": "revenue"\n}',
          html: `<div class="cg-card">
  <div class="cg-head">
    <div class="cg-kicker">CATEGORY</div>
    <div class="cg-title">{{shape}}</div>
  </div>
  <div id="cg-bars" class="cg-bars"></div>
</div>
<script>
(() => {
  const payload = (window.WIDGET_DATA || {}).payload || {};
  const labels = Array.isArray(payload.labels) ? payload.labels : [];
  const values = Array.isArray(payload.values) ? payload.values : [];
  const root = document.getElementById('cg-bars');
  const max = Math.max(1, ...values.map(value => Number(value || 0)));
  root.innerHTML = labels.map((label, index) => {
    const value = Number(values[index] || 0);
    const width = Math.max(6, Math.round((value / max) * 100));
    return '<div class="cg-row"><div class="cg-meta"><span class="cg-label">' + label + '</span><span class="cg-value">' + value + '</span></div><div class="cg-track"><div class="cg-fill" style="width:' + width + '%"></div></div></div>';
  }).join('');
})();
</script>`,
          css: `.cg-card{height:100%;display:flex;flex-direction:column;gap:14px;padding:16px;border-radius:14px;background:linear-gradient(180deg,#172554,#1d4ed8);color:#eff6ff;font-family:Arial,sans-serif}.cg-head{display:flex;justify-content:space-between;align-items:center}.cg-kicker{font-size:11px;letter-spacing:.14em;font-weight:700;color:#bfdbfe}.cg-title{font-size:14px;color:#dbeafe}.cg-bars{display:flex;flex-direction:column;gap:10px}.cg-row{display:flex;flex-direction:column;gap:6px}.cg-meta{display:flex;justify-content:space-between;gap:12px;font-size:12px}.cg-label{font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.cg-value{color:#bfdbfe}.cg-track{height:10px;border-radius:999px;background:rgba(255,255,255,.16);overflow:hidden}.cg-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,#fde68a,#f97316)}`
        };
      case 'table':
        return {
          title: 'Data Table',
          queryConfig: '{\n  "shape": "table",\n  "dataset": "top_products"\n}',
          html: `<div class="tb-card">
  <div class="tb-head">
    <div class="tb-kicker">TABLE</div>
    <div class="tb-title">{{shape}}</div>
  </div>
  <div class="tb-scroll">
    <table class="tb-table">
      <thead id="tb-head"></thead>
      <tbody id="tb-body"></tbody>
    </table>
  </div>
</div>
<script>
(() => {
  const payload = (window.WIDGET_DATA || {}).payload || {};
  const columns = Array.isArray(payload.columns) ? payload.columns : [];
  const rows = Array.isArray(payload.rows) ? payload.rows : [];
  document.getElementById('tb-head').innerHTML = '<tr>' + columns.map(col => '<th>' + col + '</th>').join('') + '</tr>';
  document.getElementById('tb-body').innerHTML = rows.map(row => '<tr>' + columns.map(col => '<td>' + (row?.[col] ?? '') + '</td>').join('') + '</tr>').join('');
})();
</script>`,
          css: `.tb-card{height:100%;display:flex;flex-direction:column;gap:12px;padding:16px;border-radius:14px;background:#0f172a;color:#e2e8f0;font-family:Arial,sans-serif}.tb-head{display:flex;justify-content:space-between;align-items:center}.tb-kicker{font-size:11px;letter-spacing:.14em;font-weight:700;color:#5eead4}.tb-title{font-size:14px;color:#99f6e4}.tb-scroll{overflow:auto;border:1px solid rgba(148,163,184,.18);border-radius:10px}.tb-table{width:100%;border-collapse:collapse;font-size:12px}.tb-table th,.tb-table td{padding:10px 12px;text-align:left;border-bottom:1px solid rgba(148,163,184,.12)}.tb-table th{position:sticky;top:0;background:#111827;color:#f8fafc;text-transform:uppercase;font-size:11px;letter-spacing:.08em}.tb-table tr:last-child td{border-bottom:none}`
        };
      case 'list':
        return {
          title: 'Status List',
          queryConfig: '{\n  "shape": "list",\n  "dataset": "services"\n}',
          html: `<div class="ls-card">
  <div class="ls-head">
    <div class="ls-kicker">LIST</div>
    <div class="ls-title">{{shape}}</div>
  </div>
  <ul id="ls-items" class="ls-items"></ul>
</div>
<script>
(() => {
  const payload = (window.WIDGET_DATA || {}).payload || {};
  const items = Array.isArray(payload.items) ? payload.items : [];
  const root = document.getElementById('ls-items');
  const statusClass = (status) => {
    const s = String(status || '').toLowerCase();
    if (s === 'critical' || s === 'down') return 'is-bad';
    if (s === 'warning' || s === 'degraded') return 'is-warn';
    return 'is-good';
  };
  root.innerHTML = items.map((item) => {
    const label = item?.label ?? 'Unknown';
    const value = item?.value ?? 0;
    const status = item?.status ?? 'healthy';
    return '<li class="ls-row"><span class="ls-dot ' + statusClass(status) + '"></span><span class="ls-label">' + label + '</span><span class="ls-value">' + value + '</span><span class="ls-status">' + status + '</span></li>';
  }).join('');
})();
</script>`,
          css: `.ls-card{height:100%;display:flex;flex-direction:column;gap:12px;padding:16px;border-radius:14px;background:linear-gradient(180deg,#111827,#1f2937);color:#f3f4f6;font-family:Arial,sans-serif}.ls-head{display:flex;justify-content:space-between;align-items:center}.ls-kicker{font-size:11px;letter-spacing:.14em;font-weight:700;color:#a5b4fc}.ls-title{font-size:14px;color:#c7d2fe}.ls-items{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:8px;overflow:auto}.ls-row{display:grid;grid-template-columns:auto 1fr auto auto;align-items:center;gap:10px;padding:8px 10px;border:1px solid rgba(148,163,184,.18);border-radius:10px;background:rgba(15,23,42,.55)}.ls-dot{width:9px;height:9px;border-radius:999px}.ls-dot.is-good{background:#22c55e}.ls-dot.is-warn{background:#f59e0b}.ls-dot.is-bad{background:#ef4444}.ls-label{font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.ls-value{font-weight:700;color:#e5e7eb}.ls-status{font-size:12px;color:#cbd5e1;text-transform:capitalize}`
        };
      case 'single':
      default:
        return {
          title: 'Single KPI',
          queryConfig: '{\n  "shape": "single",\n  "metric": "new_admissions"\n}',
          html: `<div class="sg-card">
  <div class="sg-kicker">KPI</div>
  <div class="sg-title">{{title}}</div>
  <div class="sg-value">{{value}}</div>
  <div class="sg-meta">Previous: {{previous}} {{unit}}</div>
  <div class="sg-foot">Shape: {{shape}}</div>
</div>`,
          css: `.sg-card{height:100%;display:flex;flex-direction:column;justify-content:center;padding:18px;border-radius:14px;background:linear-gradient(135deg,#111827,#1f2937);color:#f9fafb;font-family:Arial,sans-serif}.sg-kicker{font-size:11px;letter-spacing:.16em;font-weight:700;color:#fbbf24}.sg-title{margin-top:8px;font-size:15px;color:#d1d5db;text-transform:uppercase}.sg-value{margin-top:10px;font-size:42px;line-height:1;font-weight:800}.sg-meta{margin-top:12px;font-size:14px;color:#cbd5e1}.sg-foot{margin-top:8px;font-size:12px;color:#94a3b8}`
        };
    }
  }

  private clamp(value: number, min: number, max: number): number {
    const safeValue = Number.isFinite(value) ? value : min;
    const safeMax = Number.isFinite(max) ? Math.max(min, max) : min;
    return Math.max(min, Math.min(safeMax, safeValue));
  }

  private toInt(value: unknown, fallback: number): number {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) {
      return fallback;
    }
    return Math.floor(parsed);
  }

  private pick(...types: FilterType[]): SelectOption[] {
    return types.map(t => this.ALL_FILTER_TYPES[t]);
  }

  resolveAvailableFilterTypes(pgFieldType: string): SelectOption[] {
    const ft = pgFieldType.toLowerCase().trim();
    if (['character varying', 'varchar', 'text', 'char', 'bpchar', 'name', 'citext'].includes(ft)) {
      return this.pick('equals', 'in');
    }

    if (ft === 'uuid') {
      return this.pick('equals', 'in');
    }

    if ([
      'integer', 'int', 'int4', 'int2', 'int8',
      'bigint', 'smallint', 'serial', 'bigserial',
      'numeric', 'decimal',
      'real', 'float4', 'float8', 'double precision', 'money',
    ].includes(ft)) {
      return this.pick('equals', 'in', 'range', 'less-than', 'less-than-equals', 'greater-than', 'greater-than-equals');
    }

    if (ft === 'date') {
      return this.pick('equals', 'range', 'less-than', 'less-than-equals', 'greater-than', 'greater-than-equals');
    }

    if ([
      'timestamp', 'timestamp without time zone',
      'timestamp with time zone', 'timestamptz',
    ].includes(ft)) {
      return this.pick('equals', 'range', 'less-than', 'less-than-equals', 'greater-than', 'greater-than-equals');
    }

    if (['time', 'time without time zone', 'time with time zone', 'timetz'].includes(ft)) {
      return this.pick('equals', 'range', 'less-than', 'less-than-equals', 'greater-than', 'greater-than-equals');
    }

    if (ft === 'interval') {
      return this.pick('equals', 'less-than', 'less-than-equals', 'greater-than', 'greater-than-equals');
    }

    if (ft === 'boolean' || ft === 'bool') {
      return this.pick('equals');
    }

    if (['json', 'jsonb'].includes(ft)) {
      return this.pick('equals');
    }

    return this.pick('equals', 'in');
  }
}

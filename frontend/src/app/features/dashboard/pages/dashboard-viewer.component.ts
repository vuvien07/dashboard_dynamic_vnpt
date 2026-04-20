import { CommonModule } from '@angular/common';
import { AfterViewInit, Component, HostListener, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import {
  Chart,
  ChartConfiguration,
  ChartData,
  ChartOptions,
  TooltipItem,
  registerables
} from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';
import { firstValueFrom, map, Observable } from 'rxjs';
import { DashboardApiService } from '../../../core/services/dashboard-api.service';
import {
  DashboardConfigResponse,
  DataSourceQueryResponse,
  FilterConfigItem,
  LayoutItem,
  OptionItem,
  SelectOption,
  WidgetConfigItem
} from '../../../core/models/dashboard.models';
import { MultiselectComponent } from '../components/multiselect.component';
import { RangeInputComponent, RangeValue } from '../components/range-input.component';
import { InputValue, VanillaInputComponent } from '../components/vanilla-input.component';

@Component({
  selector: 'app-dashboard-viewer',
  standalone: true,
  imports: [CommonModule, RouterLink, BaseChartDirective,
    MultiselectComponent, RangeInputComponent, VanillaInputComponent],
  templateUrl: './dashboard-viewer.component.html',
  styleUrl: './dashboard-viewer.component.scss'
})
export class DashboardViewerComponent {
  private readonly route = inject(ActivatedRoute);
  private readonly api = inject(DashboardApiService);
  private readonly sanitizer = inject(DomSanitizer);
  private static chartRegistered = false;

  readonly config = signal<DashboardConfigResponse | null>(null);
  readonly selectedBreakpoint = signal('lg');
  readonly widgetDataMap = signal<Record<string, DataSourceQueryResponse>>({});
  readonly isFullscreen = signal(false);
  readonly selectedYear = signal(String(new Date().getFullYear()));
  readonly selectedMonth = signal<number | null>(null);
  readonly selectedDepartmentCode = signal('');
  readonly selectedSiteCode = signal('');
  readonly selectedStatusCode = signal('');
  readonly monthOptions = [
    { value: 1, label: 'Tháng 1' },
    { value: 2, label: 'Tháng 2' },
    { value: 3, label: 'Tháng 3' },
    { value: 4, label: 'Tháng 4' },
    { value: 5, label: 'Tháng 5' },
    { value: 6, label: 'Tháng 6' },
    { value: 7, label: 'Tháng 7' },
    { value: 8, label: 'Tháng 8' },
    { value: 9, label: 'Tháng 9' },
    { value: 10, label: 'Tháng 10' },
    { value: 11, label: 'Tháng 11' },
    { value: 12, label: 'Tháng 12' }
  ] as const;
  readonly departmentOptions = signal<OptionItem[]>([]);
  readonly siteOptions = signal<OptionItem[]>([]);
  readonly statusOptions = signal<OptionItem[]>([]);
  filters: FilterConfigItem[] = [];
  optionsMap: Record<string, SelectOption[]> = {};

  readonly yearOptions = computed(() => {
    const current = new Date().getFullYear();
    return [current - 2, current - 1, current, current + 1].map(String);
  });

  readonly breakpoints = computed(() => {
    const cfg = this.config();
    return cfg ? this.sortedBreakpoints(Object.keys(cfg.layouts)) : [];
  });

  readonly layoutMap = computed(() => {
    const cfg = this.config();
    if (!cfg) {
      return new Map<string, LayoutItem>();
    }

    const rows = cfg.layouts[this.selectedBreakpoint()] ?? [];
    return new Map(rows.map((row) => [row.widgetId, row]));
  });

  readonly filterLayoutMap = computed(() => {
    const cfg = this.config();
    if (!cfg) {
      return new Map<string, LayoutItem>();
    }

    const rows = cfg.filterLayouts[this.selectedBreakpoint()] ?? [];
    return new Map(rows.map((row) => [row.widgetId, row]));
  });

  readonly orderedWidgets = computed(() => {
    const cfg = this.config();
    if (!cfg) {
      return [] as WidgetConfigItem[];
    }

    return [...cfg.widgets].sort((a, b) => {
      const la = this.layoutMap().get(a.id);
      const lb = this.layoutMap().get(b.id);
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
  });


  readonly orderedFilters = computed(() => {
    const cfg = this.config();
    if (!cfg) {
      return [] as FilterConfigItem[];
    }

    return [...cfg.filters].sort((a, b) => {
      const la = this.filterLayoutMap().get(a.id);
      const lb = this.filterLayoutMap().get(b.id);
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
  });

  constructor() {
    if (!DashboardViewerComponent.chartRegistered) {
      Chart.register(...registerables);
      DashboardViewerComponent.chartRegistered = true;
    }

    const dashboardId = this.route.snapshot.paramMap.get('dashboardId');
    if (!dashboardId) {
      return;
    }

    this.api.getDashboardConfig(dashboardId).subscribe((response) => {
      this.config.set(response);
      this.filters = response.filters;
      const sorted = this.sortedBreakpoints(Object.keys(response.layouts));
      if (sorted.length > 0) {
        this.selectedBreakpoint.set(sorted[0]);
      }
      this.loadWidgetData(response.widgets);
      this.loadFilterOptions();
    });
  }

  private loadFilterOptions(): void {
    this.filters.forEach(filter => {
      if (['equals', 'in', 'less-than', 'less-than-equals', 
        'greater-than', 'greater-than-equals'].includes(filter.type)) {
        this.api
          .listDistinctValueFromDb(filter.targetTable, filter.targetField)
          .subscribe(response => {
            this.optionsMap[filter.id] = response;
          });
      }
    });
  }




  private sortedBreakpoints(values: string[]): string[] {
    return [...values].sort((a, b) => {
      if (a === 'lg') {
        return -1;
      }
      if (b === 'lg') {
        return 1;
      }
      return a.localeCompare(b);
    });
  }

  onBreakpointChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.selectedBreakpoint.set(target.value);
  }

  onYearChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    this.selectedYear.set(value || String(new Date().getFullYear()));
    this.reloadWidgetDataByFilter();
  }

  onMonthChange(event: Event): void {
    const raw = (event.target as HTMLSelectElement).value;
    this.selectedMonth.set(raw ? Number(raw) : null);
    this.reloadWidgetDataByFilter();
  }

  onDepartmentChange(event: Event): void {
    const raw = (event.target as HTMLSelectElement).value;
    this.selectedDepartmentCode.set(raw);
    this.reloadWidgetDataByFilter();
  }

  onSiteChange(event: Event): void {
    const raw = (event.target as HTMLSelectElement).value;
    this.selectedSiteCode.set(raw);
    this.reloadWidgetDataByFilter();
  }

  onStatusChange(event: Event): void {
    const raw = (event.target as HTMLSelectElement).value;
    this.selectedStatusCode.set(raw);
    this.reloadWidgetDataByFilter();
  }

  toggleFullscreen(): void {
    this.isFullscreen.update(v => !v);
    if (this.isFullscreen()) {
      document.documentElement.requestFullscreen?.().catch(() => { });
    } else {
      if (document.fullscreenElement) {
        document.exitFullscreen?.().catch(() => { });
      }
    }
  }

  @HostListener('document:fullscreenchange')
  onFullscreenChange(): void {
    if (!document.fullscreenElement && this.isFullscreen()) {
      this.isFullscreen.set(false);
    }
  }

  gridTemplateColumns(): string {
    const bp = this.selectedBreakpoint();
    if (bp === 'lg') {
      return 'repeat(12, minmax(0, 1fr))';
    }
    if (bp === 'md') {
      return 'repeat(6, minmax(0, 1fr))';
    }
    return 'repeat(1, minmax(0, 1fr))';
  }

  widgetGridColumn(widgetId: string): string {
    const item = this.layoutMap().get(widgetId);
    return item ? `${item.x + 1} / span ${item.w}` : 'auto';
  }

  widgetGridRow(widgetId: string): string {
    const item = this.layoutMap().get(widgetId);
    return item ? `${item.y + 1} / span ${item.h}` : 'auto';
  }

  filterGridColumn(widgetId: string): string {
    const item = this.filterLayoutMap().get(widgetId);
    return item ? `${item.x + 1} / span ${item.w}` : 'auto';
  }

  filterGridRow(widgetId: string): string {
    const item = this.filterLayoutMap().get(widgetId);
    return item ? `${item.y + 1} / span ${item.h}` : 'auto';
  }

  widgetData(widgetId: string): DataSourceQueryResponse | null {
    return this.widgetDataMap()[widgetId] ?? null;
  }

  singleUnit(data: DataSourceQueryResponse): string {
    return (data.payload['unit'] as string) || 'count';
  }

  formatValue(raw: unknown, unit: string): string {
    const value = Number(raw ?? 0);
    if (unit === 'currency') {
      return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(
        value
      );
    }
    if (unit === '%') {
      return `${value.toFixed(2)}%`;
    }
    return new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 }).format(value);
  }

  private readonly seriesPalette = [
    { border: '#1f6feb', bg: 'rgba(31,111,235,0.15)' },
    { border: '#2da44e', bg: 'rgba(45,164,78,0.15)' },
    { border: '#f59e0b', bg: 'rgba(245,158,11,0.12)' },
    { border: '#dc2626', bg: 'rgba(220,38,38,0.12)' },
    { border: '#7c3aed', bg: 'rgba(124,58,237,0.12)' },
    { border: '#0891b2', bg: 'rgba(8,145,178,0.12)' }
  ];

  lineChartData(data: DataSourceQueryResponse): ChartData<'line'> {
    const labels = (data.payload['labels'] as string[]) ?? [];
    const series = (data.payload['series'] as Array<Record<string, unknown>>) ?? [];
    const datasets = series.map((item, index) => {
      const color = this.seriesPalette[index % this.seriesPalette.length];
      return {
        label: String(item['name'] ?? `series-${index + 1}`),
        data: ((item['data'] as number[]) ?? []).map((v) => Number(v)),
        borderColor: color.border,
        backgroundColor: color.bg,
        fill: index === 0,
        tension: 0.35,
        pointRadius: 2
      };
    });

    return {
      labels,
      datasets
    };
  }

  lineChartOptions(data: DataSourceQueryResponse): ChartOptions<'line'> {
    const unit = String(data.payload['yUnit'] ?? 'count');
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: true, position: 'bottom' },
        tooltip: {
          callbacks: {
            label: (ctx: TooltipItem<'line'>) => `${ctx.dataset.label}: ${this.formatValue(ctx.parsed.y, unit)}`
          }
        }
      },
      scales: {
        x: { display: true, ticks: { maxTicksLimit: 6 } },
        y: {
          display: true,
          ticks: {
            callback: (value) => this.formatValue(value, unit)
          }
        }
      }
    };
  }

  categoryBarChartData(data: DataSourceQueryResponse): ChartData<'bar'> {
    const labels = (data.payload['labels'] as string[]) ?? [];
    const values = ((data.payload['values'] as number[]) ?? []).map((v) => Number(v));
    return {
      labels,
      datasets: [
        {
          label: 'Value',
          data: values,
          backgroundColor: ['#1f6feb', '#2da44e', '#f59e0b', '#ef4444', '#8b5cf6', '#14b8a6']
        }
      ]
    };
  }

  categoryBarOptions(data: DataSourceQueryResponse): ChartOptions<'bar'> {
    const unit = String(data.payload['unit'] ?? 'count');
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx: TooltipItem<'bar'>) => this.formatValue(ctx.parsed.y, unit)
          }
        }
      },
      scales: {
        x: { display: true },
        y: {
          display: true,
          ticks: {
            callback: (value) => this.formatValue(value, unit)
          }
        }
      }
    };
  }

  categoryPieChartData(data: DataSourceQueryResponse): ChartData<'pie'> {
    const labels = (data.payload['labels'] as string[]) ?? [];
    const values = ((data.payload['values'] as number[]) ?? []).map((v) => Number(v));
    return {
      labels,
      datasets: [
        {
          label: 'Share',
          data: values,
          backgroundColor: ['#1f6feb', '#2da44e', '#f59e0b', '#ef4444', '#8b5cf6', '#14b8a6']
        }
      ]
    };
  }

  categoryPieOptions(data: DataSourceQueryResponse): ChartOptions<'pie'> {
    const unit = String(data.payload['unit'] ?? 'count');
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: true, position: 'bottom' },
        tooltip: {
          callbacks: {
            label: (ctx: TooltipItem<'pie'>) => {
              const value = Number(ctx.raw ?? 0);
              return `${ctx.label}: ${this.formatValue(value, unit)}`;
            }
          }
        }
      }
    };
  }

  tableColumns(data: DataSourceQueryResponse): string[] {
    return (data.payload['columns'] as string[]) ?? [];
  }

  tableRows(data: DataSourceQueryResponse): Array<Record<string, unknown>> {
    return (data.payload['rows'] as Array<Record<string, unknown>>) ?? [];
  }

  listItems(data: DataSourceQueryResponse): Array<Record<string, unknown>> {
    return (data.payload['items'] as Array<Record<string, unknown>>) ?? [];
  }

  customWidgetSrcdoc(widget: WidgetConfigItem, data: DataSourceQueryResponse | null): SafeHtml {
    const html = String((widget.props['htmlTemplate'] as string) ?? '');
    const css = String((widget.props['cssTemplate'] as string) ?? '');
    const resolvedHtml = this.resolveTemplate(html, data);
    const safeJson = data
      ? JSON.stringify({ shape: data.shape, payload: data.payload })
        .replace(/</g, '\\u003c').replace(/>/g, '\\u003e').replace(/&/g, '\\u0026')
      : 'null';
    const dataScript = `<script>window.WIDGET_DATA=${safeJson};<\/script>`;
    const content = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<style>*,*::before,*::after{box-sizing:border-box}body{margin:0;padding:0;font-family:system-ui,-apple-system,sans-serif;height:100%;overflow:hidden;background:transparent}${css}</style>
${dataScript}
</head><body>${resolvedHtml}</body></html>`;
    return this.sanitizer.bypassSecurityTrustHtml(content);
  }

  private resolveTemplate(html: string, data: DataSourceQueryResponse | null): string {
    if (!data) {
      return html;
    }
    const payload = data.payload;
    return html.replace(/\{\{([\w.]+)\}\}/g, (_, key: string) => {
      if (key === 'shape') {
        return data.shape;
      }
      const parts = key.split('.');
      let val: unknown = payload[parts[0]];
      for (let i = 1; i < parts.length; i++) {
        if (val !== null && typeof val === 'object') {
          val = (val as Record<string, unknown>)[parts[i]];
        } else {
          val = undefined;
          break;
        }
      }
      return val !== undefined && val !== null ? String(val) : '';
    });
  }

  private reloadWidgetDataByFilter(): void {
    const cfg = this.config();
    if (!cfg) {
      return;
    }
    this.loadWidgetData(cfg.widgets);
  }

  private async loadWidgetData(widgets: WidgetConfigItem[]): Promise<void> {
    const requests = widgets
      .filter((widget) => !!widget.dataSourceId)
      .map(async (widget) => {
        try {
          const data = await firstValueFrom(
            this.api.queryDataSource({
              widgetId: widget.id,
              dataSourceId: widget.dataSourceId as string,
              widgetTypeCode: widget.widgetTypeCode,
              queryConfig: widget.queryConfig,
              filters: this.filters
            })
          );
          return { widgetId: widget.id, data };
        } catch {
          return {
            widgetId: widget.id,
            data: {
              dataSourceId: widget.dataSourceId as string,
              shape: 'single',
              payload: { value: 0, unit: 'count' }
            } as DataSourceQueryResponse
          };
        }
      });

    const resolved = await Promise.all(requests);
    const next = { ...this.widgetDataMap() };
    for (const item of resolved) {
      next[item.widgetId] = item.data;
    }
    this.widgetDataMap.set(next);
  }

  handleChangeVanillaInput(value: InputValue, filterId: string): void {
    const findFilter = this.filters.find((f) => f.id === filterId);
    if (findFilter) {
      findFilter.value = value.value;
    }
  }

  handleChangeRangeInput(value: RangeValue, filterId: string): void {
    const findFilter = this.filters.find((f) => f.id === filterId);
    if (findFilter) {
      findFilter.value = {
        min: value.from,
        max: value.to
      };
    }
  }

  handleApplyFilter(): void {
    this.reloadWidgetDataByFilter();
  }
}

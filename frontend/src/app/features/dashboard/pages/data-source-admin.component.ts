import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DashboardApiService } from '../../../core/services/dashboard-api.service';
import { DataSourceItem, DataSourceUpsertRequest } from '../../../core/models/dashboard.models';

@Component({
  selector: 'app-data-source-admin',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './data-source-admin.component.html',
  styleUrl: './data-source-admin.component.scss'
})
export class DataSourceAdminComponent {
  private readonly api = inject(DashboardApiService);

  items: DataSourceItem[] = [];
  message = '';
  editingId: string | null = null;
  previewMessage = '';
  previewResultText = '';
  isPreviewing = false;

  form: DataSourceUpsertRequest = {
    id: '',
    name: '',
    type: 'postgresql',
    status: 'active',
    jdbcUrl: '',
    username: '',
    password: '',
    fieldMapping: {}
  };

  apiConfig = {
    method: 'GET',
    headersText: '{\n  "Accept": "application/json"\n}',
    dataPath: 'items'
  };

  previewConfig = {
    widgetTypeCode: 'line-chart',
    queryConfigText: '{\n  "metric": "revenue"\n}'
  };

  fieldMappingText = '{\n  "metricField": "metric_code",\n  "dateField": "point_date",\n  "valueField": "value"\n}';

  constructor() {
    this.reload();
  }

  reload(): void {
    this.api.listDataSources().subscribe((response) => {
      this.items = response.items;
    });
  }

  edit(id: string): void {
    this.api.getDataSource(id).subscribe((detail) => {
      const mapping = detail.fieldMapping ?? {};
      const apiHeaders =
        mapping && typeof mapping === 'object' && 'apiHeaders' in mapping
          ? (mapping as Record<string, unknown>)['apiHeaders']
          : undefined;

      this.editingId = detail.id;
      this.form = {
        id: detail.id,
        name: detail.name,
        type: detail.type,
        status: detail.status,
        jdbcUrl: detail.jdbcUrl,
        username: detail.username,
        password: '',
        fieldMapping: mapping
      };
      this.fieldMappingText = JSON.stringify(mapping, null, 2);

      this.apiConfig = {
        method:
          (mapping && typeof mapping === 'object' && 'apiMethod' in mapping
            ? String((mapping as Record<string, unknown>)['apiMethod'] || 'GET')
            : 'GET') || 'GET',
        headersText: JSON.stringify(
          apiHeaders && typeof apiHeaders === 'object' ? apiHeaders : { Accept: 'application/json' },
          null,
          2
        ),
        dataPath:
          (mapping && typeof mapping === 'object' && 'apiDataPath' in mapping
            ? String((mapping as Record<string, unknown>)['apiDataPath'] || 'items')
            : 'items') || 'items'
      };
    });
  }

  onTypeChange(): void {
    if (this.form.type !== 'api') {
      return;
    }

    if (!this.form.jdbcUrl) {
      this.form.jdbcUrl = 'https://api.example.com/v1/metrics';
    }

    if (!this.fieldMappingText.trim() || this.fieldMappingText.trim() === '{}') {
      this.fieldMappingText =
        '{\n  "apiMethod": "GET",\n  "apiDataPath": "items",\n  "metricField": "metric",\n  "dateField": "date",\n  "valueField": "value"\n}';
    }
  }

  save(): void {
    this.message = '';
    if (!this.form.id || !this.form.name) {
      this.message = 'ID và Name là bắt buộc.';
      return;
    }

    try {
      const parsedMapping = JSON.parse(this.fieldMappingText || '{}') as Record<string, unknown>;

      if (this.form.type === 'api') {
        if (!this.form.jdbcUrl || !this.form.jdbcUrl.trim()) {
          this.message = 'API URL là bắt buộc cho datasource type=api.';
          return;
        }

        let apiHeaders: Record<string, unknown> = {};
        try {
          apiHeaders = JSON.parse(this.apiConfig.headersText || '{}') as Record<string, unknown>;
        } catch {
          this.message = 'API Headers JSON không hợp lệ.';
          return;
        }

        parsedMapping['apiMethod'] = (this.apiConfig.method || 'GET').toUpperCase();
        parsedMapping['apiHeaders'] = apiHeaders;
        parsedMapping['apiDataPath'] = this.apiConfig.dataPath || 'items';

        this.form.username = '';
        this.form.password = '';
      }

      this.form.fieldMapping = parsedMapping;
    } catch {
      this.message = 'Field mapping JSON không hợp lệ.';
      return;
    }

    if (this.editingId) {
      this.api.updateDataSource(this.editingId, this.form).subscribe(() => {
        this.message = `Đã cập nhật datasource ${this.editingId}.`;
        this.resetForm();
        this.reload();
      });
      return;
    }

    this.api.createDataSource(this.form).subscribe(() => {
      this.message = `Đã tạo datasource ${this.form.id}.`;
      this.resetForm();
      this.reload();
    });
  }

  testConnection(id: string): void {
    this.api.testDataSourceConnection(id).subscribe((response) => {
      this.message = response.success
        ? `Test connection ${id}: success.`
        : `Test connection ${id}: ${response.message}`;
    });
  }

  remove(id: string): void {
    this.api.deleteDataSource(id).subscribe(() => {
      this.message = `Đã xóa datasource ${id}.`;
      if (this.editingId === id) {
        this.resetForm();
      }
      this.reload();
    });
  }

  resetForm(): void {
    this.editingId = null;
    this.form = {
      id: '',
      name: '',
      type: 'postgresql',
      status: 'active',
      jdbcUrl: '',
      username: '',
      password: '',
      fieldMapping: {}
    };
    this.fieldMappingText = '{\n  "metricField": "metric_code",\n  "dateField": "point_date",\n  "valueField": "value"\n}';
    this.apiConfig = {
      method: 'GET',
      headersText: '{\n  "Accept": "application/json"\n}',
      dataPath: 'items'
    };
    this.previewMessage = '';
    this.previewResultText = '';
    this.previewConfig = {
      widgetTypeCode: 'line-chart',
      queryConfigText: '{\n  "metric": "revenue"\n}'
    };
  }

  previewSampleResponse(): void {
    this.previewMessage = '';
    this.previewResultText = '';

    if (this.form.type !== 'api') {
      this.previewMessage = 'Preview chỉ áp dụng cho datasource type=api.';
      return;
    }

    const dataSourceId = (this.editingId || this.form.id || '').trim();
    if (!dataSourceId) {
      this.previewMessage = 'Vui lòng nhập ID datasource và lưu datasource trước khi preview.';
      return;
    }

    let queryConfig: Record<string, unknown> = {};
    try {
      queryConfig = JSON.parse(this.previewConfig.queryConfigText || '{}') as Record<string, unknown>;
    } catch {
      this.previewMessage = 'Preview query config JSON không hợp lệ.';
      return;
    }

    this.isPreviewing = true;

    this.api
      .queryDataSource({
        widgetId: 'preview',
        dataSourceId,
        widgetTypeCode: this.previewConfig.widgetTypeCode,
        queryConfig,
        filters: []
      })
      .subscribe({
        next: (response) => {
          this.isPreviewing = false;
          this.previewMessage = `Preview thành công. Shape: ${response.shape}`;
          this.previewResultText = JSON.stringify(response.payload, null, 2);
        },
        error: (error) => {
          this.isPreviewing = false;
          const backendMessage = error?.error?.message || error?.message || 'Không thể preview dữ liệu API.';
          this.previewMessage = `Preview thất bại: ${backendMessage}`;
        }
      });
  }
}

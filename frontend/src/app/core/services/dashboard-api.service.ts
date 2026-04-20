import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  CreateDashboardRequest,
  DataSourceDetail,
  DataSourceItem,
  DataSourceQueryRequest,
  DataSourceQueryResponse,
  DataSourceTestConnectionResponse,
  DataSourceUpsertRequest,
  DashboardConfigResponse,
  DashboardListItem,
  DashboardMeta,
  SaveDashboardConfigRequest,
  SaveDashboardConfigResponse,
  OptionItem,
  SelectOption
} from '../models/dashboard.models';

interface ListResponse<T> {
  items: T[];
}

@Injectable({ providedIn: 'root' })
export class DashboardApiService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = environment.apiBaseUrl;

  listDashboards(): Observable<ListResponse<DashboardListItem>> {
    return this.http.get<ListResponse<DashboardListItem>>(`${this.baseUrl}/dashboards`);
  }

  createDashboard(payload: CreateDashboardRequest): Observable<DashboardMeta> {
    return this.http.post<DashboardMeta>(`${this.baseUrl}/dashboards`, payload);
  }

  deleteDashboard(dashboardId: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/dashboards/${dashboardId}`);
  }

  getDashboardConfig(dashboardId: string): Observable<DashboardConfigResponse> {
    return this.http.get<DashboardConfigResponse>(`${this.baseUrl}/dashboards/${dashboardId}/config`);
  }

  listDataSources(): Observable<ListResponse<DataSourceItem>> {
    return this.http.get<ListResponse<DataSourceItem>>(`${this.baseUrl}/data-sources`);
  }

  getDataSource(id: string): Observable<DataSourceDetail> {
    return this.http.get<DataSourceDetail>(`${this.baseUrl}/data-sources/${id}`);
  }

  createDataSource(payload: DataSourceUpsertRequest): Observable<DataSourceDetail> {
    return this.http.post<DataSourceDetail>(`${this.baseUrl}/data-sources`, payload);
  }

  updateDataSource(id: string, payload: DataSourceUpsertRequest): Observable<DataSourceDetail> {
    return this.http.put<DataSourceDetail>(`${this.baseUrl}/data-sources/${id}`, payload);
  }

  deleteDataSource(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/data-sources/${id}`);
  }

  testDataSourceConnection(id: string): Observable<DataSourceTestConnectionResponse> {
    return this.http.post<DataSourceTestConnectionResponse>(`${this.baseUrl}/data-sources/${id}/test-connection`, {});
  }

  queryDataSource(payload: DataSourceQueryRequest): Observable<DataSourceQueryResponse> {
    return this.http.post<DataSourceQueryResponse>(`${this.baseUrl}/data-sources/query`, payload);
  }

  saveDashboardConfig(
    dashboardId: string,
    payload: SaveDashboardConfigRequest
  ): Observable<SaveDashboardConfigResponse> {
    return this.http.put<SaveDashboardConfigResponse>(`${this.baseUrl}/dashboards/${dashboardId}/config`, payload);
  }

  listAnalyticTablesAndColumns(): Observable<Record<string, {
    field: string;
    type: string;
  }[]>> {
    return this.http.get<Record<string, {
      field: string;
      type: string;
    }[]>>(
      `${this.baseUrl}/dashboards/schema`
    );
  }

  listDistinctValueFromDb(targetTable: string, targetField: string): Observable<SelectOption[]> {
    return this.http.get<any[]>(
      `${this.baseUrl}/dashboards/${targetTable}/${targetField}/values`
    )
      .pipe(
        map(options => options.map(option => ({ label: option, value: option })))
      );
  }
}

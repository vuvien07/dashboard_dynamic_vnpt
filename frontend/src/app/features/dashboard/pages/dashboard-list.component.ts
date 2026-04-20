import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { DashboardApiService } from '../../../core/services/dashboard-api.service';
import { DashboardListItem } from '../../../core/models/dashboard.models';

@Component({
  selector: 'app-dashboard-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './dashboard-list.component.html',
  styleUrl: './dashboard-list.component.scss'
})
export class DashboardListComponent {
  private readonly api = inject(DashboardApiService);
  private readonly router = inject(Router);

  dashboards: DashboardListItem[] = [];
  createError = '';
  deleteError = '';
  isCreating = false;
  deletingDashboardId: string | null = null;
  newDashboard = {
    name: '',
    description: '',
    visibility: 'private'
  };

  constructor() {
    this.loadDashboards();
  }

  createDashboard(): void {
    const name = this.newDashboard.name.trim();
    if (!name) {
      this.createError = 'Vui lòng nhập tên dashboard.';
      return;
    }

    this.createError = '';
    this.isCreating = true;

    this.api
      .createDashboard({
        name,
        description: this.newDashboard.description.trim(),
        visibility: this.newDashboard.visibility
      })
      .subscribe({
        next: (created) => {
          this.isCreating = false;
          this.deleteError = '';
          this.newDashboard = {
            name: '',
            description: '',
            visibility: 'private'
          };
          this.loadDashboards();
          this.router.navigate(['/dashboards', created.id, 'edit']);
        },
        error: () => {
          this.isCreating = false;
          this.createError = 'Không thể tạo dashboard. Vui lòng thử lại.';
        }
      });
  }

  deleteDashboard(dashboard: DashboardListItem): void {
    const confirmed = window.confirm(`Bạn có chắc muốn xóa dashboard \"${dashboard.name}\" (${dashboard.id})?`);
    if (!confirmed) {
      return;
    }

    this.deleteError = '';
    this.deletingDashboardId = dashboard.id;

    this.api.deleteDashboard(dashboard.id).subscribe({
      next: () => {
        this.deletingDashboardId = null;
        this.dashboards = this.dashboards.filter((item) => item.id !== dashboard.id);
      },
      error: () => {
        this.deletingDashboardId = null;
        this.deleteError = 'Không thể xóa dashboard. Vui lòng thử lại.';
      }
    });
  }

  private loadDashboards(): void {
    this.api.listDashboards().subscribe((response) => {
      this.dashboards = response.items;
    });
  }
}

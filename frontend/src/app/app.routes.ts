import { Routes } from '@angular/router';

export const routes: Routes = [
	{
		path: '',
		redirectTo: 'dashboards',
		pathMatch: 'full'
	},
	{
		path: 'dashboards',
		loadComponent: () =>
			import('./features/dashboard/pages/dashboard-list.component').then((m) => m.DashboardListComponent)
	},
	{
		path: 'dashboards/:dashboardId/edit',
		loadComponent: () =>
			import('./features/dashboard/pages/dashboard-editor.component').then((m) => m.DashboardEditorComponent)
	},
	{
		path: 'dashboards/:dashboardId/view',
		loadComponent: () =>
			import('./features/dashboard/pages/dashboard-viewer.component').then((m) => m.DashboardViewerComponent)
	},
	{
		path: 'data-sources',
		loadComponent: () =>
			import('./features/dashboard/pages/data-source-admin.component').then((m) => m.DataSourceAdminComponent)
	},
	{
		path: 'guide',
		loadComponent: () =>
			import('./features/dashboard/pages/dashboard-guide.component').then((m) => m.DashboardGuideComponent)
	}
];

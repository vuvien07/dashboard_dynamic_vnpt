# Database Scripts

Scripts để thiết lập và import dữ liệu mẫu cho Dashboard Dynamic project.

## 📁 Files

| File | Mô tả |
|------|-------|
| `create-tables.sql` | DDL script tạo schema (4 bảng + indexes) |
| `import-sample-data.sql` | Import dữ liệu mẫu phức tạp (14 widget types, 4 dashboards, 30 widgets) |
| `setup-database.ps1` | **Script tổng hợp** - Chạy 1 lần để tạo schema + import data |
| `import-sample-data.ps1` | Script riêng để import data (nếu đã có schema) |

## 🚀 Quick Start

### Cách 1: Setup nhanh (Khuyến nghị)

Chạy 1 lệnh để tạo schema và import tất cả dữ liệu mẫu:

```powershell
cd backend\scripts
.\setup-database.ps1
```

Script sẽ tự động lấy cấu hình từ `application-postgres.properties`:
- Host: `localhost`
- Port: `6341`
- Database: `dashboarddb`
- Username: `postgres`
- Password: `E$r7kfym`

### Cách 2: Tùy chỉnh parameters

```powershell
.\setup-database.ps1 -Host "localhost" -Port 5432 -Database "mydb" -Username "admin" -Password "secret"
```

### Cách 3: Chạy từng bước thủ công

```powershell
# Bước 1: Tạo tables
psql -h localhost -p 6341 -U postgres -d dashboarddb -f create-tables.sql

# Bước 2: Import dữ liệu mẫu
psql -h localhost -p 6341 -U postgres -d dashboarddb -f import-sample-data.sql
```

## 📊 Dữ liệu mẫu được tạo

### Widget Types (14 loại)
- **Metrics**: KPI Card, Metric Card, Gauge, Progress Bar
- **Charts**: Line, Bar, Area, Pie, Scatter, Heatmap
- **Tables**: Data Table, List View
- **Other**: Timeline, Geographic Map

### Dashboards (4 dashboards)

#### 1. Sales Analytics Dashboard (9 widgets)
Dashboard phân tích doanh thu phức tạp với:
- 4 KPI cards (Revenue, Orders, Avg Order, Conversion Rate)
- Revenue trend line chart (90 days)
- Bar chart sales by category
- Pie chart revenue by region
- Data table top products
- Activity heatmap

#### 2. Executive Overview (6 widgets)
Dashboard tổng quan cho Ban lãnh đạo:
- Quarterly revenue & profit metrics
- Active customers KPI
- Revenue growth trend (12 months)
- Revenue by channel chart
- Top 10 customers list

#### 3. Marketing Performance (7 widgets)
Dashboard theo dõi hiệu quả marketing:
- Impressions, CTR, CPA, ROI metrics
- Conversion funnel
- Active campaigns table
- Budget distribution pie chart

#### 4. Operations Monitor (8 widgets)
Dashboard giám sát hệ thống real-time:
- System uptime gauge
- Response time & requests/min metrics
- Error rate tracking
- Request timeline
- CPU & memory usage charts
- Service health status

### Responsive Layouts
Mỗi dashboard có layouts cho 3 breakpoints:
- **lg** (large): 12-column grid
- **md** (medium): 6-column grid  
- **sm** (small): Single column mobile layout

## 🔄 Re-run Scripts

Tất cả scripts đều **idempotent** - có thể chạy nhiều lần an toàn:
- `CREATE TABLE IF NOT EXISTS` - không lỗi nếu table đã tồn tại
- `ON CONFLICT DO UPDATE` - update nếu data đã tồn tại

## ✅ Verify Data

Sau khi import, kiểm tra dữ liệu:

```sql
-- Widget types
SELECT COUNT(*) FROM widget_types;  -- Expected: 14

-- Dashboards
SELECT id, name, status, current_version_no FROM dashboards;  -- Expected: 4

-- Total widgets
SELECT dashboard_id, COUNT(*) 
FROM dashboard_widgets 
GROUP BY dashboard_id;

-- Layouts for each dashboard
SELECT dashboard_id, breakpoint, COUNT(*) 
FROM widget_layouts 
GROUP BY dashboard_id, breakpoint 
ORDER BY dashboard_id, breakpoint;
```

## 🎯 Next Steps

Sau khi import xong, start backend với PostgreSQL profile:

```powershell
cd ..\..  # Back to backend root
.\mvnw.cmd spring-boot:run "-Dspring-boot.run.profiles=postgres"
```

API endpoints sẽ có sẵn:
- `GET /api/v1/widget-types` - 14 widget types
- `GET /api/v1/dashboards` - 4 dashboards
- `GET /api/v1/dashboards/db-sales-analytics/config` - Chi tiết dashboard Sales Analytics

## 📝 Notes

- Cần cài đặt PostgreSQL client (`psql`) trong PATH
- Database `dashboarddb` phải được tạo trước khi chạy scripts
- Scripts sử dụng PostgreSQL syntax (TIMESTAMP WITH TIME ZONE, ON CONFLICT, etc.)

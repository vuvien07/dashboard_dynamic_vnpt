import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

interface GuideStep {
  id: number;
  title: string;
  objective: string;
  imageUrl: string;
  imageAlt: string;
  actions: Array<{ label: string; route: string }>;
  checklist: string[];
}

@Component({
  selector: 'app-dashboard-guide',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './dashboard-guide.component.html',
  styleUrl: './dashboard-guide.component.scss'
})
export class DashboardGuideComponent {
  steps: GuideStep[] = [
    {
      id: 1,
      title: 'Chuẩn bị nguồn dữ liệu',
      objective: 'Tạo và kiểm tra data source để tất cả widget có thể truy xuất dữ liệu.',
      imageUrl: '/guide/step-data-source.svg',
      imageAlt: 'Minh họa cấu hình data source',
      actions: [{ label: 'Mở trang Data Sources', route: '/data-sources' }],
      checklist: [
        'Tạo mới data source với tên dễ nhận biết theo nghiệp vụ.',
        'Khai báo mapping field đúng metric, date, value.',
        'Bấm test connection và chỉ sang bước tiếp theo khi trạng thái thành công.'
      ]
    },
    {
      id: 2,
      title: 'Tạo dashboard khung',
      objective: 'Khởi tạo dashboard với tên, mô tả và phạm vi truy cập rõ ràng.',
      imageUrl: '/guide/step-create-dashboard.svg',
      imageAlt: 'Minh họa tạo dashboard mới',
      actions: [{ label: 'Đi tới danh sách Dashboards', route: '/dashboards' }],
      checklist: [
        'Đặt tên dashboard theo đúng mục tiêu theo dõi.',
        'Thêm mô tả ngắn để người khác dễ hiểu bối cảnh.',
        'Chọn private/public phù hợp với người dùng cuối.'
      ]
    },
    {
      id: 3,
      title: 'Thiết kế layout & widget',
      objective: 'Sắp xếp widget theo mức ưu tiên thông tin để đọc nhanh và trực quan.',
      imageUrl: '/guide/step-layout.svg',
      imageAlt: 'Minh họa bố cục widget dashboard',
      actions: [{ label: 'Mở màn hình Editor', route: '/dashboards' }],
      checklist: [
        'Đặt KPI chính ở khu vực đầu màn hình.',
        'Nhóm biểu đồ cùng chủ đề trên cùng một hàng.',
        'Kiểm tra hiển thị theo breakpoint desktop/tablet/mobile.'
      ]
    },
    {
      id: 4,
      title: 'Gắn query và kiểm thử',
      objective: 'Liên kết từng widget với metric/dataset đúng và kiểm thử kết quả trả về.',
      imageUrl: '/guide/step-query.svg',
      imageAlt: 'Minh họa cấu hình query cho widget',
      actions: [
        { label: 'Kiểm tra Data Sources', route: '/data-sources' },
        { label: 'Quay lại Dashboards', route: '/dashboards' }
      ],
      checklist: [
        'Chọn đúng data source cho từng widget.',
        'Cấu hình metric hoặc dataset trong query config.',
        'Đảm bảo đúng shape dữ liệu: single, timeseries, category, table, list.'
      ]
    },
    {
      id: 5,
      title: 'Review và vận hành',
      objective: 'Đánh giá phiên bản hoàn chỉnh trước khi đưa vào sử dụng cho người dùng.',
      imageUrl: '/guide/step-review.svg',
      imageAlt: 'Minh họa bước review dashboard',
      actions: [{ label: 'Mở Dashboard Viewer', route: '/dashboards' }],
      checklist: [
        'Kiểm tra các bộ lọc năm/tháng/khoa/cơ sở/trạng thái.',
        'Xem ở chế độ Viewer như người dùng thực tế.',
        'Chốt phiên bản sau khi QA xong.'
      ]
    }
  ];

  activeStepId = 1;

  setActiveStep(stepId: number): void {
    this.activeStepId = stepId;
  }

  get activeStep(): GuideStep {
    return this.steps.find((step) => step.id === this.activeStepId) ?? this.steps[0];
  }
}

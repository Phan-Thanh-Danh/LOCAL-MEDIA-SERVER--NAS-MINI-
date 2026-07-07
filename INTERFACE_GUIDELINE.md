
# 🎨 Quy Tắc Thiết Kế Giao Diện (UI/UX Design Guidelines)
## Dự án: Local Media Server (NAS Mini) - Chuẩn Doanh Nghiệp

Tài liệu này quy định các tiêu chuẩn về Màu sắc, Phông chữ, Icon, Bố cục và Thành phần giao diện nhằm đồng bộ hóa trải nghiệm người dùng, hướng tới sự tinh giản, hiện đại và chuyên nghiệp theo xu hướng thiết kế Web hiện đại (Doanh nghiệp 5.0).

---

## 1. Bảng Màu Chủ Đạo (Color Palette - Light Mode)
Hệ thống chuyển sang tông màu sáng sạch sẽ, sử dụng các dải màu có độ tương phản cao để làm nổi bật nội dung media và giảm mỏi mắt khi sử dụng lâu.

| Thành phần | Mã màu (HEX) | Vai trò hiển thị |
| :--- | :--- | :--- |
| **Primary (Màu chính)** | `#2563EB` (Blue 600) | Các nút hành động chính, trạng thái đang chọn (Active), liên kết quan trọng. |
| **Secondary (Màu phụ)** | `#475569` (Slate 600) | Các nút phụ, icon điều hướng, trạng thái phụ ít nổi bật hơn. |
| **Background (Nền chính)** | `#F8FAFC` (Slate 50) | Nền toàn bộ ứng dụng (Mang lại cảm giác thoáng đãng, sang trọng). |
| **Surface (Nền phân khu)** | `#FFFFFF` (White) | Nền của bảng danh sách file, thanh công cụ, các popup thông báo. |
| **Text Primary (Chữ chính)**| `#0F172A` (Slate 900) | Tiêu đề lớn, tên thư mục, tên file (Độ tương phản cực tốt). |
| **Text Secondary (Chữ phụ)**| `#64748B` (Slate 500) | Ngày sửa đổi, định dạng file, dung lượng (Dữ liệu bổ trợ). |
| **Border (Đường viền)** | `#E2E8F0` (Slate 200) | Đường phân cách giữa các dòng trong bảng, viền thanh công cụ. |

---

## 2. Phông Chữ Hệ Thống (Typography)
Để hỗ trợ hiển thị Tiếng Việt hoàn hảo, không bị lỗi hiển thị các ký tự có dấu (như á, ớ, đ, dựa...), dự án thống nhất sử dụng phông chữ **Inter**.

* **Font Family chính:** `Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;`
* **Đường dẫn nhúng Google Fonts (Thêm vào file `index.html` của Vue):**
  ```html
  <link rel="preconnect" href="[https://fonts.googleapis.com](https://fonts.googleapis.com)">
  <link rel="preconnect" href="[https://fonts.gstatic.com](https://fonts.gstatic.com)" crossorigin>
  <link href="[https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap](https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap)" rel="stylesheet">

```

### Quy định phân cấp kích thước chữ (Font Hierarchy):

* **Tiêu đề lớn (Page Title):** Size `24px` | Weight `700 (Bold)` | Màu: `Text Primary`
* **Tiêu đề bảng / Cột (Header Table):** Size `13px` | Weight `600 (Medium)` | Màu: `Text Secondary` | Chữ in hoa
* **Tên File / Thư mục:** Size `14px` | Weight `500 (Medium)` | Màu: `Text Primary`
* **Thông tin bổ trợ (Size, Date):** Size `13px` | Weight `400 (Regular)` | Màu: `Text Secondary`

---

## 3. Thư Viện Icon Chuẩn Hóa (Icons)

**Tuyệt đối không sử dụng Emoji hệ thống (`📁`, `🎬`, `🖼️`, `📥`)** để đảm bảo tính nhất quán hiển thị trên mọi hệ điều hành (Windows, iOS, Android).

Dự án sử dụng thư viện **Lucide Icons** (gói cài đặt cho Vue 3: `lucide-vue-next`). Đây là bộ icon phẳng, đường nét mỏng tinh tế chuẩn doanh nghiệp.

### Bộ icon quy định cho từng đối tượng:

* **Thư mục (Folder):** Icon `Folder` (Màu sắc đồng bộ: `#EAB308` hoặc `#2563EB`).
* **File Video:** Icon `Video` hoặc `Clapperboard` (Màu sắc: `#475569`).
* **File Ảnh:** Icon `Image` (Màu sắc: `#475569`).
* **Nút Tải về (Download):** Icon `Download` (Màu sắc: `#2563EB`).
* **Nút Tạo thư mục mới:** Icon `FolderPlus`.
* **Nút Tải lên file:** Icon `UploadCloud`.
* **Nút Điều hướng:** Icon `ArrowLeft` (Quay lại) và `Home` (Trang chủ).

---

## 4. Tái Cấu Trúc Bố Cục (Layout & Wireframe 5.0)

Bố cục mới loại bỏ giao diện giả lập cửa sổ Windows cổ điển, chuyển sang dạng **Dashboard Đa nhiệm (Tập trung - Gọn gàng - Khoa học)**. Giao diện được chia thành 3 phần rõ rệt theo chiều dọc:

```text
+------------------------------------------------------------------------------------+
|  [LOGO / TÊN DỰ ÁN]                  [ Thanh tìm kiếm file/folder... ]  (Top Header)|
+------------------------------------------------------------------------------------+
|  [🏠 Home] [📁 Folder Cha] [> Con]            [➕ New Folder] [📤 Upload]  (ActionBar) |
+------------------------------------------------------------------------------------+
|  TABLE DANH SÁCH FILE & THƯ MỤC                                       (Main Content)|
|  --------------------------------------------------------------------------------  |
|  | [Icon] Tên File/Thư mục     | Ngày cập nhật   | Loại file | Dung lượng | [Tải về] |  |
|  | [Icon] Tên File/Thư mục     | Ngày cập nhật   | Loại file | Dung lượng | [Tải về] |  |
|  +-----------------------------+-----------------+-----------+------------+--------+  |
+------------------------------------------------------------------------------------+

```

### 4.1. Thanh Tiêu Đề Top (Header)

* Cấu hình cố định trên cùng màn hình (Sticky Header) khi cuộn chuột.
* Bên trái đặt Logo chữ đậm kết hợp icon tối giản.
* Bên phải tích hợp thanh Tìm kiếm nhanh (Search Bar) bo tròn góc, có icon kính lúp mờ bên trong để người dùng lọc file nhanh.

### 4.2. Thanh Thao Tác & Điều Hướng (Action & Breadcrumb Bar)

* Gộp chung thanh địa chỉ (Breadcrumb thể hiện cấu trúc thư mục hiện tại) và các nút bấm chức năng (`New Folder`, `Upload File`) trên cùng một hàng ngang để tiết kiệm diện tích hiển thị.
* Các nút bấm áp dụng cấu trúc: `[Icon Lucide] + [Chữ tiếng Anh/Việt]`, bo tròn góc `6px` hoặc `8px`. Khi di chuột vào (Hover) phải có hiệu ứng đổi màu nền mượt mà (Transition `0.2s`).

### 4.3. Khu Vực Bảng Dữ Liệu (Main Table Grid)

* Bảng dữ liệu được đặt trên khối nền trắng (`Surface`), áp dụng hiệu ứng đổ bóng nhẹ (`box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05)`) để tạo chiều sâu.
* Loại bỏ toàn bộ các đường viền dọc, chỉ giữ lại đường viền ngang siêu mảnh (`border-bottom: 1px solid #E2E8F0`) ngăn cách giữa các dòng.
* Tích hợp hiệu ứng Hover dòng: Khi di chuột qua dòng nào, dòng đó tự động đổi sang màu nền xám nhạt (`#F1F5F9`) giúp người dùng định vị chính xác.
* Nút **Tải về** ở cuối dòng thiết kế dưới dạng icon nhỏ tinh tế hoặc chỉ hiển thị lên khi người dùng thực hiện hover vào dòng đó (Hover Effect), giúp tổng thể bảng luôn sạch sẽ, không rối mắt.

---

## 5. Quy Định Trải Nghiệm Phát Media (Media Preview Modal)

* Khi người dùng mở video hoặc ảnh, hệ thống không chuyển hướng trang cũ để tránh mất trải nghiệm duyệt tệp tin.
* Sử dụng một màn hình phủ lớp mờ (Overlay Modal) hiện đè lên trên giao diện bảng.
* Khung phát video/ảnh phải bo góc `8px`, sử dụng nền đen sâu (`#000000`) bao quanh phần xem để người dùng tập trung tuyệt đối vào nội dung media.

```

```
# Hướng Dẫn Chạy Local Media Server Trên Mạng LAN

Tài liệu này hướng dẫn chi tiết cách chạy hệ thống Local Media Server và xử lý lỗi không thể kết nối tới Backend (đặc biệt là lỗi `ECONNREFUSED` từ Vite proxy).

## 1. Nguyên nhân lỗi ECONNREFUSED thường gặp

Khi chạy ứng dụng, bạn có thể gặp lỗi sau ở Frontend (trình duyệt hiện "Không thể kết nối tới Backend..." và terminal Vite báo `Error: connect ECONNREFUSED 192.168.x.x:5000` hoặc `127.0.0.1:5000`):

Nguyên nhân chính là do:
1. **Backend chưa khởi động hoặc bị sập:** Cửa sổ CMD của backend bị lỗi (ví dụ file csproj target phiên bản .NET không tương thích, hoặc lỗi mã nguồn) dẫn đến việc không có dịch vụ nào đang "lắng nghe" (listen) ở port 5000.
2. **Hard-code IP LAN trong Vite Proxy:** File `vite.config.js` từng bị hard-code trỏ proxy sang một IP tĩnh trên mạng LAN (ví dụ 192.168.2.10). Nếu backend thực chất đang chạy cùng trên một máy chủ với frontend, proxy nên được trỏ về `http://127.0.0.1:5000` thay vì IP LAN để tránh phụ thuộc vào router.
3. **Chạy Backend sai host:** Nếu backend chỉ listen ở `localhost` (chứ không phải `0.0.0.0`), các máy khác trong LAN sẽ bị từ chối kết nối.

Các nguyên nhân này đều đã được khắc phục trong bản cập nhật cấu hình mới nhất.

## 2. Cách chạy nhanh hệ thống

Để khởi động toàn bộ hệ thống (cả Backend và Frontend) một cách an toàn và đúng thứ tự, chỉ cần:
**Click đúp chuột vào file `run-local-media-server.bat`** nằm ở thư mục gốc của dự án.

Quá trình của file BAT:
- **Bước 1:** Kiểm tra máy đã cài `dotnet` và `node.js` chưa.
- **Bước 2:** Bật Backend lên ở địa chỉ `http://0.0.0.0:5000` (để nhận kết nối từ mọi máy LAN).
- **Bước 3:** Chờ và liên tục ping backend để đảm bảo backend đã sẵn sàng phục vụ.
- **Bước 4:** Bật Frontend lên ở địa chỉ `https://0.0.0.0:5173`.

## 3. Cách test thủ công sau khi chạy

Sau khi hệ thống thông báo đã khởi động thành công, bạn làm theo thứ tự sau để test:

- **Test Backend:** 
  Mở trình duyệt hoặc dùng CMD gõ: `curl http://127.0.0.1:5000/api/system/status` (nếu có API này) hoặc truy cập `http://127.0.0.1:5000/api/files` để xem có trả về dữ liệu (JSON) không.

- **Test Frontend (trên chính máy Server NAS):** 
  Truy cập `https://localhost:5173`. Giao diện Vue phải hiện lên và không báo lỗi.

- **Test từ máy khác trong LAN (VD: Điện thoại, Laptop khác):** 
  Truy cập `https://<IP_MÁY_SERVER>:5173` (Ví dụ: `https://192.168.2.10:5173`).

*(Lưu ý: Do sử dụng Self-signed SSL Certificate cho môi trường dev, trình duyệt sẽ cảnh báo "Not Secure" hoặc "Your connection is not private". Đây là điều bình thường, bạn cứ nhấn **Advanced (Nâng cao) -> Proceed (Tiếp tục truy cập)**).*

## 4. Cấu hình Tường lửa (Firewall) nếu máy LAN không truy cập được

Nếu máy tính khác trong LAN xoay vòng "Loading" liên tục hoặc không vào được trang web, bạn cần mở Port trên máy chủ Windows chứa code. 
Mở CMD với quyền **Administrator** (Run as Administrator) và chạy 2 lệnh sau:

```cmd
netsh advfirewall firewall add rule name="Local Media Server Backend 5000" dir=in action=allow protocol=TCP localport=5000
netsh advfirewall firewall add rule name="Local Media Server Frontend 5173" dir=in action=allow protocol=TCP localport=5173
```

## 5. Chức năng Download File
Bạn có thể tải thẳng các file media từ máy chủ NAS về client.
- **Cách sử dụng:** Truy cập danh sách file ở trang chủ, tại cột "Actions", bấm nút **⬇ Download** cho file tương ứng.
- **Endpoint Backend:** `GET /api/media/download/{path}`
- **Test Backend trực tiếp:** Mở trình duyệt truy cập `http://127.0.0.1:5000/api/media/download/ten-file.mp4`

*(Lưu ý: Chỉ áp dụng cho các tệp (file). Bạn không thể download cả một thư mục (folder). Đồng thời, backend đã được thiết lập để chống Path Traversal, không cho phép tải file ngoài giới hạn của `RootPath`).*

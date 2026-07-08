# API Contract - Local Media Server NAS Mini

Tài liệu này đặc tả các endpoint API hiện có từ backend ASP.NET Core, phục vụ việc xây dựng Mobile App bằng Flutter.

## Thiết lập chung

- **Base URL:** `http://<LAN-IP>:<PORT>` (ví dụ: `http://192.168.1.10:5000`)
- **Headers yêu cầu:**
  - `Content-Type: application/json` (cho hầu hết các request)
  - `Authorization: Bearer <JWT_TOKEN>` (cho mọi request sau khi đăng nhập)
  - `Vault-Password: <PASSWORD>` (cho các thao tác xem/thay đổi liên quan đến thư mục ẩn/vault)

---

## 1. Authentication (Xác thực)

### 1.1 Login

- **Endpoint:** `/api/auth/login`
- **Method:** `POST`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "username": "admin",
    "password": "your_password"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR...",
    "role": "Admin"
  }
  ```
- **Lỗi thường gặp:**
  - `400 Bad Request`: Thiếu username/password.
  - `401 Unauthorized`: Sai thông tin đăng nhập.

---

## 2. File Explorer (Duyệt File)

### 2.1 Get Files & Folders

- **Endpoint:** `/api/files`
- **Method:** `GET`
- **Auth Required:** Yes
- **Query Params:**
  - `path` (string, optional): Đường dẫn thư mục cần list. Nếu rỗng, sẽ list thư mục gốc.
  - `password` (string, optional): Mật khẩu thư mục bị khóa.
- **Headers:** `Vault-Password` (nếu đang ở trạng thái unlock két sắt để xem thư mục ẩn).
- **Response (200 OK):**
  ```json
  [
    {
      "name": "Movies",
      "relativePath": "Movies",
      "isDirectory": true,
      "size": 0,
      "sizeFormatted": "",
      "lastModified": "2023-10-25T14:30:00",
      "type": "Thư mục",
      "isPinned": false,
      "isHidden": false,
      "isLocked": true
    },
    {
      "name": "photo.jpg",
      "relativePath": "Photos/photo.jpg",
      "isDirectory": false,
      "size": 1048576,
      "sizeFormatted": "1 MB",
      "lastModified": "2023-10-25T14:30:00",
      "type": "Hình ảnh",
      "isPinned": true,
      "isHidden": false,
      "isLocked": false
    }
  ]
  ```
- **Lỗi thường gặp:**
  - `401 Unauthorized` (Custom body: "LOCKED"): Yêu cầu nhập mật khẩu thư mục (`password` query param).
  - `404 Not Found`: Không tìm thấy thư mục (hoặc thư mục ẩn mà sai `Vault-Password`).

---

## 3. Media & File Actions

### 3.1 Get Thumbnail

- **Endpoint:** `/api/media/thumbnail/{*relativePath}`
- **Method:** `GET`
- **Auth Required:** Yes
- **Response (200 OK):** Hình ảnh (image/jpeg)
- **Lỗi thường gặp:** `404 Not Found` (File hoặc Thumbnail không tồn tại)

### 3.2 Stream Video

- **Endpoint:** `/api/media/video/{*path}`
- **Method:** `GET`
- **Auth Required:** Yes
- **Headers:** `Range: bytes=0-` (Yêu cầu để hỗ trợ seek)
- **Response (206 Partial Content):** Stream video
- **Lỗi thường gặp:** `404 Not Found`, `403 Forbidden`

### 3.3 Tải Ảnh/File (Image/Generic File Stream)

- **Endpoint:** `/api/media/image/{*path}` hoặc `/api/media/file/{*path}`
- **Method:** `GET`
- **Auth Required:** Yes
- **Response (200 OK / 206 Partial Content):** File stream

### 3.4 Download File (Dùng tải xuống client)

- **Endpoint:** `/api/media/download/{*path}`
- **Method:** `GET`
- **Auth Required:** Yes
- **Response (200 OK):** File stream, header `Content-Disposition: attachment`.

### 3.5 Upload File

- **Endpoint:** `/api/media/upload`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request:**
  - Content-Type: `multipart/form-data`
  - Body Fields: 
    - `file` (IFormFile)
    - `subPath` (string, optional)
- **Response (200 OK):**
  ```json
  { "message": "Tải file lên thành công!" }
  ```

### 3.6 Tạo thư mục

- **Endpoint:** `/api/media/create-folder`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "folderName": "NewFolder", "subPath": "Movies" }
  ```
- **Response (200 OK):** `{ "message": "Tạo thư mục thành công!" }`

### 3.7 Đổi tên

- **Endpoint:** `/api/media/rename`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "path": "Movies/old.txt", "newName": "new.txt" }
  ```
- **Response (200 OK):** `{ "message": "Đã đổi tên..." }`

### 3.8 Xóa File/Thư mục

- **Endpoint:** `/api/media/delete`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "path": "Movies/test.txt" }
  ```
- **Response (200 OK):** `{ "message": "Đã xóa..." }`

### 3.9 Di chuyển (Move)

- **Endpoint:** `/api/files/move`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "sourcePath": "Movies/test.txt", "targetFolder": "Documents" }
  ```
- **Response (200 OK):** `{ "message": "Di chuyển thành công." }`

---

## 4. Bảo mật & Ghim (Vault, Lock, Pin)

### 4.1 Khóa / Mở khóa thư mục

- **Endpoint:** `/api/media/lock` và `/api/media/unlock`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "path": "Movies/Secret", "password": "123" }
  ```
- **Response (200 OK):** `{ "message": "..." }`

### 4.2 Lấy trạng thái Vault

- **Endpoint:** `/api/media/vault/status`
- **Method:** `GET`
- **Auth Required:** Yes
- **Response (200 OK):** `{ "isSet": true }`

### 4.3 Đặt/Đổi mật khẩu Vault

- **Endpoint:** `/api/media/vault/password`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "oldPassword": "...", "newPassword": "123" } // oldPassword null nếu chưa set
  ```
- **Response (200 OK):** `{ "message": "..." }`

### 4.4 Ẩn / Bỏ ẩn thư mục

- **Endpoint:** `/api/media/vault/hide` và `/api/media/vault/unhide`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "path": "Movies", "password": "vault_password" }
  ```
- **Response (200 OK):** `{ "message": "..." }`

### 4.5 Ghim / Bỏ ghim

- **Endpoint:** `/api/files/pin` và `/api/files/unpin`
- **Method:** `POST`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  { "path": "Movies/important.txt" }
  ```
- **Response (200 OK):** `{ "success": true }`

---

## 5. System (Hệ thống)

### 5.1 System Status (Health Check)

- **Endpoint:** `/api/system/status`
- **Method:** `GET`
- **Auth Required:** Yes
- **Response (200 OK):** `{ "status": "running", "rootPath": "D:\\LAN" }`

### 5.2 Dashboard Info

- **Endpoint:** `/api/system/dashboard`
- **Method:** `GET`
- **Auth Required:** Yes
- **Response (200 OK):**
  ```json
  {
    "drives": [
      {
        "name": "C:\\",
        "totalSize": 250000000000,
        "availableFreeSpace": 50000000000,
        "usedSpace": 200000000000,
        "usedPercentage": 80.0
      }
    ],
    "appRamUsage": 150423000,
    "uptime": "05.14:30:22"
  }
  ```

---

## Dart Models Tương Ứng (Dự kiến)

**`FileItemDto` (Models)**
```dart
class FileItem {
  final String name;
  final String relativePath;
  final bool isDirectory;
  final int size;
  final String sizeFormatted;
  final DateTime lastModified;
  final String type;
  final bool isPinned;
  final bool isHidden;
  final bool isLocked;
  // Constructor & fromJson()
}
```

**`DriveInfo` (Models)**
```dart
class DriveInfo {
  final String name;
  final int totalSize;
  final int availableFreeSpace;
  final int usedSpace;
  final double usedPercentage;
}
```

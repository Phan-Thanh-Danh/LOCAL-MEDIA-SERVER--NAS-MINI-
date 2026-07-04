# Local Media Server NAS Mini

## Overview
This project provides a local LAN media server built with ASP.NET Core backend and Vue 3 frontend. It reads files directly from the local filesystem and supports directory browsing, image viewing, and video streaming with HTTP range requests.

## Backend
- ASP.NET Core 8
- Controllers for files/media/system
- Path traversal protection middleware
- SignalR hub and file watcher service

## Frontend
- Vue 3 + Vite
- Explorer-style file table
- Image viewer and video player
- Navigation with home/back and breadcrumb

## Run
### Backend
```bash
dotnet run --project backend/LocalMediaServer/LocalMediaServer.csproj
```

### Frontend
```bash
cd frontend
npm install
npm run dev
```

## Notes
By default the server expects media under D:/Tài Liệu. Update the root path in backend/LocalMediaServer/appsettings.json if needed.

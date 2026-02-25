# BữaChung – Hướng dẫn Build APK

## Cấu trúc dự án đã được sửa
Đây là phiên bản đã fix tất cả lỗi import và cấu trúc Gradle.

## Các lỗi đã sửa
1. `app_state.dart`: Sửa import path `../data/models/models.dart` → `../models/models.dart`
2. `app_state.dart`: Sửa import path `../data/repository/repository.dart` → `./repository.dart`
3. `home_screen.dart`: Xoá import `meal_detail_screen.dart` không tồn tại → thay bằng `other_screens.dart` (MealDetailScreen nằm trong file này)
4. `theme.dart`: Sửa export path `../data/models/models.dart` → `../../data/models/models.dart`
5. Toàn bộ cấu trúc Gradle Android đã được viết lại tương thích với Android Gradle Plugin 8.x

## Cách build APK

### Yêu cầu
- Flutter SDK >= 3.3.0 (khuyến nghị Flutter 3.19+)
- Android Studio / Android SDK (API 21+)
- JDK 17

### Các bước build

```bash
# 1. Vào thư mục dự án
cd buachung_fixed

# 2. Cài đặt dependencies
flutter pub get

# 3. Build APK debug (nhanh, để test)
flutter build apk --debug

# 4. Build APK release (tối ưu, để cài điện thoại)
flutter build apk --release

# File APK sẽ nằm tại:
# build/app/outputs/flutter-apk/app-release.apk
```

### Cài APK vào điện thoại
1. Bật "Developer Options" trên điện thoại Android
2. Bật "Install from unknown sources" (hoặc "Install unknown apps")
3. Copy file `app-release.apk` vào điện thoại
4. Mở file APK trên điện thoại và cài đặt

### Hoặc cài trực tiếp qua USB
```bash
# Kết nối điện thoại qua USB với USB Debugging đã bật
flutter install
```

## Tính năng chính
- 🍽️ **Bữa ăn**: Thêm bữa ăn với tên quán, ngày, tổng tiền, thành viên
- 📸 **Chụp ảnh**: Chụp hoặc chọn ảnh làm bằng chứng bữa ăn  
- 👥 **Thành viên**: Quản lý danh sách thành viên với emoji và màu sắc
- 💳 **Quyết toán**: Tự động tính toán ai nợ ai với số giao dịch tối thiểu
- 💾 **Offline**: Tất cả dữ liệu lưu offline trong SQLite

## Lưu ý
- Dữ liệu được lưu hoàn toàn trên điện thoại (SQLite)
- Lần đầu mở app sẽ tự tạo 5 thành viên mẫu: Tuấn (Thủ quỹ), Hùng, Minh, Nam, Linh

## 🚀 خطوات إعداد Firebase

### 1. إنشاء مشروع Firebase
1. روح على [Firebase Console](https://console.firebase.google.com)
2. دوس **Add Project**
3. سميه `logistics-pro`
4. فعل **Google Analytics** (اختياري)

### 2. إضافة تطبيق Android
1. في Overview، دوس **Android**
2. **Package name:** `com.logistics.pro`
3. **App nickname:** Logistics Pro
4. دوس **Register app**
5. حمل ملف `google-services.json`
6. ضع الملف في: `android/app/google-services.json`

### 3. تفعيل Cloud Messaging
1. روح **Project Settings** → **Cloud Messaging**
2. انسخ **Server key** (هنحتاجه في الـ Backend)

### 4. في Flutter

#### تثبيت الحزم:
```bash
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```

#### في `main.dart`:
```dart
import 'firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(MyApp());
}
```

### 5. في الـ Backend (server/.env):
```env
FIREBASE_SERVER_KEY=your-server-key-from-firebase
```

### 6. اختبار الإشعارات
```bash
# شغل الـ Backend
npm run dev

# شغل التطبيق
flutter run
```

---

## ⚠️ ملاحظات مهمة

### للـ Production:
- استخدم Firebase Admin SDK في الـ Backend
- أضيف Cloud Functions لو عايز إشعارات تلقائية
- فعل Firebase Analytics

### أخطاء شائعة:
- لو ظهر `Duplicate class` error → نفذ `flutter clean`
- لو الإشعارات مش شغالة → تأكد من FCM Token في Console

### روابط مفيدة:
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [FCM HTTP API](https://firebase.google.com/docs/cloud-messaging/http-server-ref)

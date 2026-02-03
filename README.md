# 📦 Logistics Pro - نظام الشحن والتتبع

نظام لوجستي متكامل مبني بـ Flutter يتيح للشركات إدارة الشحنات و للعملاء تتبع شحناتهم في الوقت الفعلي.

## ✨ المميزات

### 🏢 لوحة الشركة
- ✅ **إضافة شحنة** - إدخال بيانات العميل ونوع الخدمة
- ✅ **تحديث الحالة** - نقرة واحدة لتحديث مرحلة الشحنة
- ✅ **إشعارات تلقائية** - إرسال push notification للعميل فور التحديث

### 👤 واجهة العميل
- ✅ **تتبع الشحنة** - معرفة الحالة اللحظية مع شريط التقدم
- ✅ **سجل الرحلة** - عرض جميع مراحل الشحنة بالتفصيل
- ✅ **طلب خدمة** - مقارنة الشركات وطلب خدمة لوجستية

## 📱 الشاشات

| شاشة | الوصف |
|------|-------|
| `AddShipmentScreen` | إضافة شحنة جديدة |
| `CompanyUpdateStatusScreen` | تحديث حالة الشحنة (مع إشعارات) |
| `ClientTrackScreen` | تتبع الشحنة للعميل |
| `RequestServiceScreen` | طلب خدمة من شركة |

## 🏗️ الهيكل

```
lib/
├── main.dart                    # نقطة الدخول
├── models/
│   └── shipment_model.dart      # نموذج الشحنة + المراحل
├── screens/
│   ├── company/
│   │   ├── add_shipment_screen.dart
│   │   └── update_status_screen.dart
│   └── client/
│       ├── track_shipment_screen.dart
│       └── request_service_screen.dart
└── services/
    └── notification_service.dart # خدمة الإشعارات
```

## 🚀 مراحل الشحن

```dart
enum ShipmentStatus {
  received,      // استلام
  customs,       // إجراءات جمركية
  port,          // الميناء
  loading,       // التحميل
  inTransit,     // في الطريق
  arrived,       // الوصول
  delivered,     // تسليم نهائي
}
```

## 📦 التشغيل

```bash
# 1. تثبيت الاعتماديات
flutter pub get

# 2. تشغيل التطبيق
flutter run

# 3. بناء APK
flutter build apk --release
```

## 🔥 إعداد Firebase (للإشعارات)

### الخطوات:

1. أنشئ مشروع في [Firebase Console](https://console.firebase.google.com)

2. أضف تطبيق Android:
   - Package name: `com.example.logistics_v2`
   - حمل `google-services.json`
   - ضعه في `android/app/`

3. فعل Cloud Messaging:
   ```dart
   // في main.dart
   await Firebase.initializeApp();
   await NotificationService().initialize();
   ```

4. في `notification_service.dart` شيل `// TODO` وشغل الكود الفعلي

## 🔗 ربط الشاشتين

### عند تحديث الشركة للحالة:

```dart
// 1. الشركة تضغط "تحديث"
final updatedShipment = shipment.copyWith(
  status: newStatus,
  statusHistory: [...shipment.statusHistory, newUpdate],
);

// 2. إرسال للـ API
await api.updateShipment(updatedShipment);

// 3. إرسال إشعار للعميل
await NotificationService().sendShipmentStatusUpdate(
  customerToken: customer.fcmToken,
  trackingNumber: shipment.trackingNumber,
  newStatus: newStatus.key,
  statusLabelAr: newStatus.labelAr,
);
```

### العميل يستلم الإشعار:

```dart
// في شاشة التتبع
NotificationService().notificationStream.listen((notification) {
  if (notification['type'] == 'shipment_update') {
    // إعادة تحميل بيانات الشحنة
    refreshShipment();
    
    // عرض snackbar
    showUpdateNotification(notification);
  }
});
```

## 🎨 الألوان

| اللون | الكود | الاستخدام |
|-------|-------|----------|
| Dark Blue | `#2C3E50` | AppBar, Primary |
| Green | `#27AE60` | Success, Update button |
| Blue | `#3498DB` | Received status |
| Orange | `#E67E22` | In Transit status |
| Purple | `#9B59B6` | Customs status |

## 📡 API Endpoints (مقترحة)

```
POST   /api/shipments              # إضافة شحنة
PUT    /api/shipments/:id/status   # تحديث الحالة
GET    /api/shipments/:id          # جلب تفاصيل الشحنة
GET    /api/shipments/track/:num   # تتبع بالرقم
POST   /api/notifications/send     # إرسال إشعار
```

## ⚠️ ملاحظات

### ما هو مكتمل:
- ✅ UI كامل لجميع الشاشات
- ✅ نموذج البيانات (Models)
- ✅ منطق الإشعارات (محاكاة)
- ✅ التنقل بين الشاشات

### يحتاج إكمال:
- 🔲 ربط Firebase FCM
- 🔲 Backend API حقيقي
- 🔲 قاعدة بيانات (Firebase/Supabase)
- 🔲 خريطة Google Maps
- 🔲 صلاحيات المستخدم (Auth)

## 🛠️ التقنيات

- Flutter 3.x
- Dart 3.x
- Firebase (FCM, Auth, Firestore)
- Google Maps API

---

**Made with ❤️ using Flutter**

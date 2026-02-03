# 🚀 دليل النشر الشامل

## المشروع متكون من 3 أجزاء:
1. **Flutter App** (Mobile)
2. **Backend API** (Node.js + PostgreSQL)
3. **Firebase** (Push Notifications)

---

## 📱 الجزء 1: Flutter App

### الملفات:
```
lib/
├── main.dart                          # نقطة الدخول
├── firebase_config.dart               # إعداد Firebase
├── firebase_options.dart              # بيانات Firebase (TODO)
├── models/
│   └── shipment_model.dart            # نموذج الشحنة
├── screens/
│   ├── company/
│   │   ├── add_shipment_screen.dart   # إضافة شحنة
│   │   └── update_status_screen.dart  # تحديث الحالة ✅
│   └── client/
│       ├── track_shipment_screen.dart # تتبع الشحنة ✅
│       └── request_service_screen.dart# طلب خدمة
└── services/
    ├── api_service.dart               # HTTP API
    └── notification_service.dart      # Push Notifications
```

### التشغيل:
```bash
cd logistics_v2
flutter pub get
flutter run
```

---

## 🖥️ الجزء 2: Backend API

### الملفات:
```
server/
├── server.js                          # API كامل
├── package.json                       # Dependencies
├── render.yaml                        # Render config
├── .env.example                       # Environment vars
└── README.md                          # Docs
```

### API Endpoints:
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/register | تسجيل جديد |
| POST | /api/auth/login | تسجيل دخول |
| GET | /api/shipments | قائمة الشحنات |
| POST | /api/shipments | إضافة شحنة |
| GET | /api/shipments/track/:num | تتبع شحنة |
| PUT | /api/shipments/:id/status | تحديث الحالة |
| GET | /health | فحص السيرفر |

### النشر على Render:

#### 1. انسخ الكود لـ GitHub:
```bash
cd server
git remote add origin https://github.com/YOUR_USERNAME/logistics-v2-api.git
git push -u origin main
```

#### 2. على Render.com:
1. أنشئ **PostgreSQL**:
   - Name: `logistics-v2-db`
   - Plan: Free

2. أنشئ **Web Service**:
   - Connect GitHub repo
   - Build: `npm install`
   - Start: `node server.js`
   - Add `JWT_SECRET` → Generate

3. ربط Database بالـ Web Service

#### 3. احصل على الـ URL:
```
https://logistics-v2-api.onrender.com
```

#### 4. عدّل Flutter:
في `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://logistics-v2-api.onrender.com/api';
```

---

## 🔥 الجزء 3: Firebase Setup

### الخطوات:
1. روح [Firebase Console](https://console.firebase.google.com)
2. أنشئ مشروع `logistics-pro`
3. أضف تطبيق Android:
   - Package: `com.logistics.pro`
4. حمل `google-services.json`
5. ضعه في `android/app/`
6. فعل Cloud Messaging

### تثبيت الحزم:
```bash
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```

### تفعيل الكود:
في `lib/firebase_options.dart` ضيف بياناتك.
في `main.dart` شيل `//` من `FirebaseConfig.initialize()`.

---

## 🎯 ملخص الربط بين الأجزاء

```
┌─────────────────┐
│  Flutter App    │
│  (User)         │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│  Backend API    │
│  (Render)       │
└────────┬────────┘
         │ SQL
         ▼
┌─────────────────┐
│  PostgreSQL     │
│  (Render DB)    │
└─────────────────┘
         │
         │ Push
         ▼
┌─────────────────┐
│  Firebase FCM   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Flutter App    │
│  (Notification) │
└─────────────────┘
```

---

## ✅ Checklist قبل النشر

### Flutter:
- [ ] عدّل `baseUrl` للـ API
- [ ] أضف خط Cairo في `assets/fonts/`
- [ ] اختبر على جهاز حقيقي

### Backend:
- [ ] ارفع الكود لـ GitHub
- [ ] أنشئ PostgreSQL على Render
- [ ] أنشئ Web Service على Render
- [ ] تأكد إن `/health` شغال

### Firebase:
- [ ] أنشئ مشروع
- [ ] أضف تطبيق Android
- [ ] حمل `google-services.json`
- [ ] اختبر الإشعار

---

## 🆘 Troubleshooting

### مشكلة: الإشعارات مش شغالة
**الحل:** تأكد من FCM Token وإنه متخزن في الـ Backend

### مشكلة: الـ API مش بيرد
**الحل:** تأكد من الـ URL وإن السيرفر شغال على Render

### مشكلة: Database error
**الحل:** تأكد إن `DATABASE_URL` موجود في Environment Variables

---

## 📞 دعم

لو فيه أي مشكلة، ابعت:
1. صورة الـ Error
2. Terminal logs
3. الخطوة اللي وقفت عندها

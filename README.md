# HealinQ — Flutter App

Mental health companion app built with Flutter.

## Tech Stack
- Flutter 3.x
- Dart 3.x
- Provider (state management)
- Google Fonts, smooth_page_indicator, table_calendar, intl, fl_chart

---

## Setup Instructions

### 1. Prerequisites
- Flutter SDK 3.x (tested with 3.38.9)
- Android Studio or VS Code
- Android Emulator / physical device

### 2. Create Flutter Project

Open terminal and run:
```bash
flutter create healinq
cd healinq
```

### 3. Replace Files
Copy all files from this zip into your project, **replacing** the existing ones. The full directory structure is:

```
healinq/
├── pubspec.yaml              ← replace
└── lib/
    ├── main.dart             ← replace
    ├── theme/
    │   └── app_theme.dart
    ├── models/
    │   └── models.dart
    ├── utils/
    │   ├── app_data.dart
    │   └── app_state.dart
    ├── widgets/
    │   └── common_widgets.dart
    └── screens/
        ├── splash_screen.dart
        ├── onboarding_screen.dart
        ├── auth/
        │   ├── welcome_screen.dart
        │   ├── login_screen.dart
        │   └── signup_screen.dart
        ├── home/
        │   └── home_screen.dart
        ├── konsultasi/
        │   ├── konsultasi_screen.dart
        │   ├── counselor_list_screen.dart
        │   ├── booking_form_screen.dart
        │   └── booking_ticket_screen.dart
        ├── self_healing/
        │   └── self_healing_screen.dart
        ├── fyp/
        │   └── fyp_screen.dart
        └── chat/
            ├── message_list_screen.dart
            └── room_chat_screen.dart
```

### 4. Create Asset Directories
```bash
mkdir -p assets/images assets/icons
```

### 5. Install Dependencies
```bash
flutter pub get
```

### 6. Run the App
```bash
flutter run
```

---

## App Flow

```
Splash Screen (3 detik)
    ↓
Onboarding (Visi & Misi → swipe kiri → Welcome Page)
    ↓
Welcome Page → [Login] atau [Create Account]
    ↓                ↓
Login Screen    Sign Up Screen
    ↓                ↓
    └──── Home Screen ────┘
              ↓
    Bottom Nav: Home | Konsultasi | Profile | Self-Healing | FYP
              ↓
    Konsultasi → Pilih Tipe (Online/Offline)
              → Pilih Counselor
              → Isi Form Booking (tanggal, jam, keluhan)
              → Ticket Booking (dengan countdown timer)
              → Konfirmasi → Go to Room Chat
              → Room Chat (chat interaktif)
```

---

## Fitur yang Diimplementasikan

### ✅ Auth
- Splash Screen (animasi fade + scale)
- Onboarding (Visi & Misi + scroll ke Welcome)
- Login (validasi form, mock authentication)
- Sign Up (validasi form lengkap)

### ✅ Home
- Greeting personalised dengan tanggal
- Mascot Rabbit
- Quick Access (Journal, Konsultasi, Jar of Happiness, FYP)
- Recent Journals
- Consultation History
- Daftar Counselor
- Lyric of the Day
- Score Progress (XP, Level, Streak)

### ✅ Konsultasi
- Pilih Online / Offline
- List Counselor (dengan rating dan status)
- Form Booking (date picker, jam, keluhan)
- Booking Ticket (dengan countdown timer)
- Konfirmasi → Go to Room Chat
- Message List (daftar counselor yang pernah dikonsultasi)
- Room Chat (bubble chat interaktif, auto-reply)

### ✅ Self-Healing
- Jar of Happiness (klik → muncul afirmasi/pertanyaan acak)
- Daily Journaling (add, view, mood picker)
- Tampilan "Today" dan "Last Week"

### ✅ FYP (Find Your Passion)
- Lyric of the Day
- 11 pertanyaan dengan skala Likert 1-5
- Hasil berdasarkan skor (Tech, Art, Social, Sport, Business, Education)
- Reset kuis

### ✅ Profile
- Info user (nama, email, level, XP, streak)
- Logout

---

## Catatan Penting

1. **Data Mock** — Semua data (counselors, journals, dll) adalah data dummy di `lib/utils/app_data.dart`. Untuk production, ganti dengan API calls.

2. **State Management** — Menggunakan `Provider` (ChangeNotifier). State di-reset setiap kali app restart (belum ada persistence).

3. **Login** — Saat ini menerima username/email dan password apapun yang tidak kosong (mock). Untuk production, sambungkan ke backend.

4. **Assets** — Tidak ada asset gambar yang diperlukan (semua ilustrasi dibuat dengan CustomPainter).

5. **Intl** — Pastikan locale `id` tersedia, atau ganti format tanggal jika ada error.

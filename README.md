# Beaskit

Beaskit adalah aplikasi web untuk mencari beasiswa dan menghubungkan Mentee dengan Mentor. Teknologi yang digunakan: Flutter Web, Firebase Authentication, Cloud Firestore, dan Firebase Hosting.

## Struktur

```text
lib/
├── core/                 # Gerbang autentikasi dan pemilihan dashboard
├── models/               # Model pengguna, beasiswa, booking, dan lainnya
├── services/             # Akses Firebase dan logika data
└── screens/
    ├── auth/             # Login dan registrasi
    ├── mentee/           # Beasiswa, bookmark, tracker, dan booking
    ├── mentor/           # Profil, jadwal, dan booking mentor
    └── admin/            # Verifikasi mentor dan pengelolaan data
```

## Menjalankan aplikasi

1. Siapkan `lib/firebase_options.dart` dengan menyalin `lib/firebase_options.example.dart` atau menjalankan `flutterfire configure --project=beaskit-a210e`. File `firebase_options.dart` tidak disertakan dalam Git.
2. Jalankan `flutter pub get`.
3. Jalankan `flutter run -d chrome`.

## Deploy

```sh
firebase deploy --only firestore:rules,firestore:indexes
flutter build web
firebase deploy --only hosting
```

## Membuat akun Admin

Buat akun di Firebase Console > Authentication. Kemudian buat dokumen `users/{uid}` di Cloud Firestore dengan field `name`, `email`, dan `role: "admin"`.

## Data contoh beasiswa

Tambahkan dokumen ke koleksi `scholarships` melalui Firebase Console.

| Field | Tipe | Contoh |
|---|---|---|
| `title` | string | Beasiswa Unggulan |
| `organizer` | string | Kemendikbud |
| `description` | string | Beasiswa untuk mahasiswa berprestasi |
| `requirements` | string | IPK minimum 3.0 |
| `required_documents` | array string | `["Transkrip nilai", "CV"]` |
| `deadline` | timestamp | 31 Desember 2026 |
| `application_url` | string | `https://contoh.id/daftar` |
| `status` | string | `published` atau `archived` |

## Catatan implementasi

Proyek ini tidak memakai Cloud Functions. Karena menggunakan paket Firebase tanpa biaya, aturan booking—kapasitas maksimum 3 Mentee aktif, pending selama 30 menit, pencegahan booking ganda, dan pembatalan minimal 24 jam sebelum sesi—dijalankan melalui transaksi Firestore dari aplikasi dan Security Rules. Kedaluwarsa serta penyelesaian booking diproses saat halaman terkait dibuka, bukan melalui proses terjadwal di server. Kapasitas diperiksa saat Mentor menyetujui booking.

## Status fitur

**Selesai:** autentikasi dan registrasi berdasarkan role; pencarian, daftar, dan detail beasiswa; bookmark; tracker dan checklist; profil serta verifikasi Mentor; direktori Mentor dan pengelolaan jadwal; alur booking Mentee/Mentor; pengelolaan beasiswa dan daftar pengguna Admin.

**Belum:** pengujian otomatis menyeluruh dan verifikasi deployment ke Firebase Hosting.

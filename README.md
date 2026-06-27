# Lumina - Yapay Zeka Destekli Mobil Öğrenme Asistanı 🚀

Lumina, öğrencilerin ve araştırmacıların çalışma süreçlerini kolaylaştırmak ve verimliliklerini artırmak amacıyla geliştirilmiş, yapay zeka destekli modern bir mobil öğrenme asistanıdır. Flutter ile geliştirilen uygulama, Google Gemini API ve Firebase entegrasyonları ile güçlü bir kullanıcı deneyimi sunar.

---

## 📱 Özellikler

### 1. Akıllı Belge Analizi ve Özetleme (AI Summary)
* **Desteklenen Formatlar:** PDF, Word (.docx, .doc), Düz Metin (.txt) ve Görseller (.png, .jpg, .jpeg).
* **Gemini 2.5 Flash** modeli entegrasyonu sayesinde belgeler saniyeler içinde analiz edilir.
* **Akıcı Özetler:** Belgenin ne hakkında olduğunu açıklayan net ve anlaşılır bir genel özet oluşturulur.
* **Önemli Çıkarımlar (Takeaways):** Belgedeki en önemli fikirler ve kritik bilgiler liste halinde sunulur.
* **Akıllı Flashcard'lar:** Çalışmayı ve ezber yapmayı kolaylaştıran soru-cevap kartları otomatik olarak üretilir.

### 2. Belge ile Sohbet Etme (Chat with Document)
* Yüklediğiniz belgenin içeriğini bağlam (context) olarak alan yapay zeka asistanı ile birebir sohbet edebilirsiniz.
* Dokümanla ilgili sorular sorabilir, karmaşık formüllerin veya konuların açıklanmasını talep edebilirsiniz.

### 3. Esnek Belge Yükleme ve Tarama (Upload & Scan)
* **Dosya Seçici:** Cihazınızdaki belgeleri kolayca seçip uygulamaya yükleyebilirsiniz.
* **Kamera ile Tarama:** Ders notlarının veya kitap sayfalarının fotoğrafını çekip anında belge listesine ekleyebilirsiniz.

### 4. Güvenli Giriş ve Kullanıcı Yönetimi (Auth)
* **Firebase Authentication:** E-posta ve şifre ile güvenli kayıt olma, giriş yapma ve oturum sonlandırma.
* **İzole Kullanıcı Depolama Alanı:** Her kullanıcının yüklediği belgeler ve çalışma geçmişi kendi hesabı altında izole şekilde, yerel veritabanında güvenle saklanır.

---

## 🛠️ Kullanılan Teknolojiler

* **Mobil Framework:** Flutter & Dart (SDK ^3.11.5)
* **Yapay Zeka (AI SDK):** `google_generative_ai` (Gemini 2.5 Flash)
* **Veritabanı ve Kimlik Doğrulama:**
  - Firebase Core
  - Firebase Authentication
  - Firebase Storage
* **Dosya İşleme & Yardımcı Paketler:**
  - `file_picker` (Dosya seçimi)
  - `image_picker` (Kameradan tarama/fotoğraf çekme)
  - `flutter_pdfview` (Uygulama içi PDF görüntüleme)
  - `archive` (.docx dosyalarını açma ve metin ayıklama)
  - `path_provider` (Güvenli yerel dosya depolama)

---

## 🚀 Kurulum ve Çalıştırma

### 1. Gereksinimler
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (Sürüm 3.11.5 veya üzeri)
* Android Studio / VS Code (Dart ve Flutter eklentileri kurulu)
* Firebase Projesi (Authentication aktif edilmiş olmalıdır)

### 2. Kurulum Adımları

1. Projeyi bilgisayarınıza klonlayın:
   ```bash
   git clone https://github.com/kullanici_adi/lumina.git
   cd lumina
   ```

2. Gerekli bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```

3. API Anahtarı Yapılandırması:
   Uygulamanın Gemini modeline erişebilmesi için geçerli bir API anahtarı eklemeniz gerekir.
   * `lib/config/api_config.dart.template` şablon dosyasını temel alarak `lib/config/api_config.dart` dosyasını oluşturun.
   * Dosya içeriğini şu şekilde düzenleyin ve `YOUR_GEMINI_API_KEY_HERE` yerine Google AI Studio'dan aldığınız API anahtarını yerleştirin:
     ```dart
     class ApiConfig {
       static const String geminiApiKey = 'BURAYA_GEMINI_API_ANAHTARINIZI_YAZIN';
     }
     ```

4. Firebase Yapılandırması:
   * Firebase konsolunda oluşturduğunuz projenin `google-services.json` (Android) veya `GoogleService-Info.plist` (iOS) yapılandırma dosyalarını ilgili dizinlere yerleştirin veya FlutterFire CLI kullanarak `lib/firebase_options.dart` dosyasını oluşturun.

5. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

---

## 📁 Proje Klasör Yapısı

```text
lib/
├── config/
│   ├── api_config.dart           # Gemini API Anahtar Yapılandırması (Gizli)
│   └── api_config.dart.template  # API Yapılandırma Şablonu
├── services/
│   ├── ai_service.dart           # Gemini API entegrasyonu ve doküman özetleme servisi
│   ├── auth_service.dart         # Firebase Auth işlemleri (Giriş/Kayıt/Çıkış)
│   └── document_service.dart     # Belgeleri yerel depolamada saklama ve yönetme servisi
├── screens/
│   ├── login.dart                # Giriş Yap Sayfası
│   ├── register.dart             # Kayıt Ol Sayfası
│   ├── home.dart                 # Ana Sayfa Dashboard (Döküman listesi & Yükleme alanı)
│   ├── profile.dart              # Kullanıcı Profil Sayfası
│   ├── document_view.dart        # Belge Detay, Özet ve Flashcard Sayfası
│   ├── chat_page.dart            # Belge Üzerinden Yapay Zeka ile Sohbet Sayfası
│   └── photo_approval.dart       # Kameradan Çekilen Görseli Onaylama ve Adlandırma Sayfası
├── widgets/
│   ├── app_logo.dart             # Uygulama Logosu
│   ├── custom_text_field.dart    # Özelleştirilmiş Metin Giriş Alanı
│   ├── primary_button.dart       # Özelleştirilmiş Buton
│   ├── recent_documents.dart     # Son Yüklenen Belgeler Listesi
│   └── upload_card.dart          # Hızlı Dosya Yükleme Paneli
└── main.dart                     # Uygulama Başlangıç Noktası (Auth Durum Kontrolü)
```

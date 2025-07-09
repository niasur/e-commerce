# e-commerce

Nama: Nia Surniati  
NPM: 2022804102  
Kelas: SI 6A Pagi


# 🛍️ E-commerce
Aplikasi e-commerce sederhana & modern yang dibuat menggunakan **Flutter**.  
Menggabungkan **Firebase Authentication** dan **JSON Server** untuk pengelolaan pengguna.  
Aplikasi ini mendukung fitur-fitur seperti search & filter produk, wishlist, checkout, serta riwayat pesanan.

---

## ✨ Fitur Aplikasi

### 🔐 Autentikasi Pengguna
- **Login menggunakan Firebase** (Email & Password)
- **Registrasi menggunakan JSON Server**
- Data login disimpan dengan `SharedPreferences`

### 🎨 Tampilan
- Mendukung **Mode Terang & Gelap (Light/Dark Mode)**
- Animasi menggunakan **Lottie** untuk:
  - Logo / ikon toko
  - Animasi sukses saat pembayaran berhasil

### 🧭 Navigasi
- Navigasi bawah (Bottom NavBar) dengan 3 menu utama:
  - **Home** 🏠: Product list, search, filters, wishlist
  - **Cart** 🛒: Manage items, checkout
  - **Profile** 👤: Manage user, order history, log out

### 🔍 Jelajahi Produk
- Fitur **pencarian produk** berdasarkan nama
- **Filter produk** berdasarkan:
  - Harga Terendah
  - Harga Tertinggi
- Fitur **Wishlist** (produk favorit) ❤️

### 🛒 Keranjang & Checkout
- Tambahkan produk ke keranjang dengan pilihan **varian**
- **Atur jumlah produk**,  hapus item
- Tampilkan **detail produk dan varian yang dipilih**
- Proses **checkout** meliputi:
  - Memilih **metode pengiriman**
  - Memilih **metode pembayaran**
  - Tampilkan **rincian pesanan**
  - Tampilkan **animasi sukses**

### 📦 Riwayat Pesanan
- Menyimpan riwayat pesanan secara lokal
- Menampilkan produk yang dibeli, waktu pesanan, total, metode pembayaran, dan status (sukses/gagal)

---

## 🛠️ Teknologi yang Digunakan

- **Flutter** (menggunakan Stateful Widget dan `setState`)
- **Firebase Authentication** (hanya untuk login)
- **JSON Server** (untuk registrasi & data pengguna)
- **Lottie** untuk animasi
- **SharedPreferences** untuk cache lokal
- **HTTP package** untuk komunikasi API
- Desain UI mengikuti standar **Material Design** (terang & gelap)

---

#### Getting Started
Berikut tampilan dari e-commerce app:
https://youtu.be/r_dx7NzrRW0?si=6xN9ROHp7LDkf58H 
https://github.com/niasur/e-commerce/blob/main/src/LKQE88163.MP4

---

# Terima kasih

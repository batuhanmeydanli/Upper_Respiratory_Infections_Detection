import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hastayimm/login/sifreUnuttum.dart';
import 'package:hastayimm/login/kayit.dart';

import '../alert.dart';

class GirisPage extends StatefulWidget {
  const GirisPage({Key? key}) : super(key: key);

  @override
  State<GirisPage> createState() => _GirisPageState();
}

class _GirisPageState extends State<GirisPage> {
  final _formKey = GlobalKey<FormState>();
  final firebaseAuth = FirebaseAuth.instance;
  late String email, password; // E-mail ve şifreyi saklamak için değişkenler

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Üst Görsel
            Container(
              height: height * 0.37,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage("images/log1.png"),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Form Alanı
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Merhaba\nHoş geldiniz!",
                        style: TextStyle(
                          color: Color(0xFF0731c5),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 20),
                      // E-mail TextField
                      _buildEmailField(),
                      const SizedBox(height: 10),
                      // Password TextField
                      _buildPasswordField(),
                      const SizedBox(height: 20),
                      // Giriş Yap Butonu
                      _buildSignInButton(),
                      const SizedBox(height: 10),
                      // Alt Butonlar (Şifremi Unuttum, Kayıt Ol)
                      _buildFooterButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // E-mail TextField
  Widget _buildEmailField() {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Lütfen bir e-posta adresi giriniz";
        }
        if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
          return "Lütfen geçerli bir e-posta adresi giriniz";
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: "Kullanıcı Adı (Email)",
        hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0731c5), width: 2),
        ),
      ),
      onSaved: (value) {
        email = value!.trim();
      },
    );
  }

  // Password TextField
  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Lütfen şifrenizi giriniz";
        }
        if (value.length < 6) {
          return "Şifre en az 6 karakter olmalıdır";
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: "Şifre",
        hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 3),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0731c5), width: 3),
        ),
      ),
      onSaved: (value) {
        password = value!.trim();
      },
    );
  }

  // Giriş Yap Butonu
  Widget _buildSignInButton() {
    return Container(
      height: 45,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0731c5)),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF0731c5),
      ),
      child: TextButton(
        onPressed: signIn,
        child: const Text(
          'Giriş Yap',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // Alt Butonlar
  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SifreUnut()),
            );
          },
          child: const Text(
            "Şifremi Unuttum",
            style: TextStyle(color: Color(0xFF0731c5), fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UyeOl()),
            );
          },
          child: const Text(
            "Kayıt Ol",
            style: TextStyle(color: Color(0xFF0731c5), fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }

  // Giriş İşlemi
  void signIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final userCredential = await firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        final User? user = userCredential.user;
        if (user != null) {
          print("Giriş başarılı: ${user.email}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AlertPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = "Bu e-posta ile kayıtlı bir kullanıcı bulunamadı.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Şifrenizi yanlış girdiniz.";
        } else {
          errorMessage = "Bir hata oluştu: ${e.message}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bilinmeyen bir hata oluştu: $e")),
        );
      }
    }
  }
}

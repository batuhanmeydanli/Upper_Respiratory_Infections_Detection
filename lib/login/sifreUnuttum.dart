import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'giris.dart';

class SifreUnut extends StatefulWidget {
  const SifreUnut({Key? key}) : super(key: key);

  @override
  State<SifreUnut> createState() => _SifreUnutState();
}

class _SifreUnutState extends State<SifreUnut> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String email;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst görsel
              Container(
                height: height * 0.19,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage("images/uye.png"),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "E-posta adresinizi giriniz",
                  style: TextStyle(
                    fontSize: 22.0,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // E-posta alanı
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Lütfen bir e-posta adresi giriniz.";
                        } else if (!RegExp(
                            r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                            .hasMatch(value)) {
                          return "Geçerli bir e-posta adresi giriniz.";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        email = value!.trim();
                      },
                      decoration: const InputDecoration(
                        hintText: "E-posta adresinizi giriniz",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    // Şifre sıfırlama butonu
                    InkWell(
                      onTap: _sendPasswordResetEmail,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0731c5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Center(
                            child: Text(
                              "Şifre sıfırlama bağlantısını gönder",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // Giriş sayfasına dön butonu
                    TextButton(
                      child: const Text(
                        "Giriş Sayfasına Dön",
                        style: TextStyle(
                          color: Color(0xFF0731c5),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const GirisPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Şifre sıfırlama fonksiyonu
  void _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await _auth.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GirisPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Bir hata oluştu: $e",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}



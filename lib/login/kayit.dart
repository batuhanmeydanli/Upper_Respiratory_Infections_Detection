import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'giris.dart';




class UyeOl extends StatefulWidget {
  @override
  State<UyeOl> createState() => _UyeOlState();
}

class _UyeOlState extends State<UyeOl> {
  final _formKey = GlobalKey<FormState>();
  final firebaseAuth = FirebaseAuth.instance;

  late String email, password, isim, soyisim;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0731c5),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopImage(height, "images/uye.png"),
              SizedBox(height: 15,),
              Text("Kayıt ol",style: TextStyle(color: Colors.white,fontSize: 24,fontFamily: 'Poppins'),),
              SizedBox(height: 10,),
              _buildForm(context, height),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopImage(double height, String imagePath) {
    return Container(
      height: height * 0.25,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage(imagePath),
        ),
      ),
    );
  }


  Widget _buildForm(BuildContext context, double height) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height * 0.81),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              hintText: "İsim*",
              validatorMessage: "İsim kısmı zorunludur",
              onSaved: (value) => isim = value!,
            ),
            SizedBox(height: 10,),
            _buildTextField(
              hintText: "Soyisim*",
              validatorMessage: "Soyisim kısmı zorunludur",
              onSaved: (value) => soyisim = value!,
            ),
            SizedBox(height: 10,),
            _buildTextField(
              hintText: "E-mail*",
              validatorMessage: "Geçerli bir e-posta adresi giriniz",
              onSaved: (value) => email = value!,
            ),SizedBox(height: 10,),
            _buildTextField(
              hintText: "Parola*",
              obscureText: true,
              validatorMessage: "Parola giriniz",
              onSaved: (value) => password = value!,
            ),SizedBox(height: 20,),
            _buildButton(
              text: "Kayıt Ol",
              onPressed: signUp,
              color: const Color(0xFF0731c5),
              textColor: Colors.white,
            ),
            _buildButton(
              text: "Giriş Sayfasına Dön",
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => GirisPage()),
              ),
              color: Colors.white,
              textColor: const Color(0xFF0731c5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required String validatorMessage,
    required Function(String?) onSaved,
    bool obscureText = false,
  }) {
    return TextFormField(
      obscureText: obscureText,
      validator: (value) => value == null || value.isEmpty ? validatorMessage : null,
      onSaved: onSaved,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0731c5), width: 2),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  void signUp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Firebase Auth ile kullanıcı oluşturma
        final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // Firebase Auth'tan kullanıcı UID'sini al
        final User? user = userCredential.user;

        if (user != null) {
          // Kullanıcı bilgilerini Firestore'a kaydet
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'isim': isim,
            'soyisim': soyisim,
            'email': email,
          });

          print("Kullanıcı Oluşturuldu: ${user.email}");
        }

        _formKey.currentState!.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF0731c5),
            content: Text(
              "Kaydınız başarıyla oluşturuldu. Giriş yapabilirsiniz",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        // Giriş ekranına yönlendir
        Navigator.pushReplacementNamed(context, "/");
      } catch (e) {
        // Hata durumunda mesaj göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }


}

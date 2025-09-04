import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'analiz.dart';
import 'doktor.dart';
import 'homePage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            userData = doc.data() ?? {};
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print("Kullanıcı bilgileri alınamadı: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _editUserInfo(String field, {String? hintText}) async {
    TextEditingController controller = TextEditingController(
      text: userData[field]?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$field Güncelle"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText ?? "$field giriniz", // Örn: ARh+ gibi bir ipucu eklenir
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({field: controller.text});
                    setState(() {
                      userData[field] = controller.text;
                    });
                  } catch (e) {
                    print("$field güncellenemedi: $e");
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0731c5),
      appBar: AppBar(
        backgroundColor: Color(0xFF0731c5),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Geri düğmesi
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const homePage()),
            );
          },
        ),


      ),
      bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.white,
          color: const Color(0xFF0731c5),
          animationDuration: const Duration(milliseconds: 250),
          index: 4,
          onTap: (index) {
            setState(() {
              if (index == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
              } else if (index == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AnalizPage()));
              } else if (index == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  homePage()));
              } else if (index == 3) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
              } else if (index == 4) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
              }
            });
          },
          items: [
            Image.asset('images/orphar.png', height: 25),
            const Icon(Icons.add_a_photo, color: Colors.white),
            const Icon(Icons.home, color: Colors.white),
            Image.asset(
              'images/virus1.png',
              height: 23,
            ),
            Image.asset(
              'images/user.png',
              height: 23,
            ),
          ]),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'images/profil.png',
              height: MediaQuery.of(context).size.height * 0.25,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 160,
            left: 0,
            right: 0,
            child:
            Center(
              child: Text(
                "${userData['isim'] ?? 'Kullanıcı'} ${userData['soyisim'] ?? ''}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(0),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Kişisel Bilgiler",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0731c5),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => _editUserInfo("Yaş"),
                          child: _buildInfoCard(
                              "Yaş", "${userData['Yaş'] ?? "-"} Yaş", 'images/id-card.png'),
                        ),
                        GestureDetector(
                          onTap: () => _editUserInfo("Kan Grubu", hintText: "Örn: ARh+"),
                          child: _buildInfoCard("Kan Grubu", userData['Kan Grubu'] ?? "-", 'images/blood.png'),
                        ),
                
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => _editUserInfo("Kilo"),
                          child: _buildInfoCard(
                              "Kilo", "${userData['Kilo'] ?? "-"} Kg", 'images/scale.png'),
                        ),
                        GestureDetector(
                          onTap: () => _editUserInfo("Boy"),
                          child: _buildInfoCard(
                              "Boy", "${userData['Boy'] ?? "-"} Cm", 'images/ruler.png'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, String assetPath) {
    return Container(
      width: 150,
      height: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0731c5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(assetPath, height: 36, width: 36, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hastayimm/analiz.dart';
import 'package:hastayimm/login/giris.dart';
import 'package:hastayimm/profile.dart';
import 'doktor.dart';
import 'package:intl/intl.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  String isim = "";
  String soyisim = "";
  List<Map<String, dynamic>> _diseaseHistory = [];
  bool _isLoading = true;

  String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchDiseaseHistory();
    fetchPersonalInformation();

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
            isim = doc.data()?['isim'] ?? 'Kullanıcı';
            soyisim = doc.data()?['soyisim'] ?? '';
          });
        }
      } catch (e) {
        print("Kullanıcı bilgileri alınamadı: $e");
      }
    }
  }
  String formatDate(String date) {
    try {
      // UTC olarak gelen tarihi parse ediyoruz
      final parsedDate = DateTime.parse(date);
      // 3 saat ekliyoruz
      final adjustedDate = parsedDate.add(const Duration(hours: 3));
      // Formatlayıp döndürüyoruz
      return DateFormat('dd MMMM yyyy | HH:mm', 'tr').format(adjustedDate);
    } catch (e) {
      print("Tarih formatlama hatası: $e");
      return 'Tarih Hatası';
    }
  }
  Future<void> _fetchDiseaseHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .get();
        print("Firestore verileri:");
        querySnapshot.docs.forEach((doc) {
          print("Belge ID: ${doc.id}, Veriler: ${doc.data()}");
        });

        setState(() {
          _diseaseHistory = querySnapshot.docs.map((doc) {
            return {
              'id': doc.id, // Belge ID'si ekleniyor
              'date': doc['date'],
              'disease': doc['disease'],
              'severity': doc['severity'],
            };
          }).toList();

          // Tarihe göre sıralama
          _diseaseHistory.sort((a, b) {
            final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(0);
            final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(0);
            return dateB.compareTo(dateA);
          });

          _isLoading = false;
        });
      } catch (e) {
        print("Hastalık geçmişi alınamadı: $e");
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _deleteDiseaseHistory(String documentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .doc(documentId)
            .delete();
        print("Hastalık geçmişi başarıyla silindi!");
      } catch (e) {
        print("Silme işlemi sırasında hata oluştu: $e");
      }
    }
  }
  String Yas = 'Bilinmiyor';
  String Boy = 'Bilinmiyor';
  String Kilo = 'Bilinmiyor';
  String KanGrubu = 'Bilinmiyor';

  Future<void> fetchPersonalInformation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            Yas = doc.data()?['Yaş']?.toString() ?? 'Bilinmiyor';
            Boy = doc.data()?['Boy']?.toString() ?? 'Bilinmiyor';
            Kilo = doc.data()?['Kilo']?.toString() ?? 'Bilinmiyor';
            KanGrubu = doc.data()?['Kan Grubu']?.toString() ?? 'Bilinmiyor';
          });
        }
      } catch (e) {
        print("Kullanıcı bilgileri alınamadı: $e");
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Silmek istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Onayı kapat
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                await _deleteDiseaseHistory(documentId); // Firebase'den sil
                setState(() {
                  _diseaseHistory.removeWhere((item) => item['id'] == documentId); // Listeden sil
                });
                Navigator.of(context).pop(); // Onayı kapat
              },
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );
  }



  void _showDiseaseHistoryBottomSheet(BuildContext context, List<Map<String, dynamic>> diseaseHistory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Geçmiş Hastalıklar",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child
                    : ListView.builder(
                  padding: EdgeInsets.only(top: 8), // Boşlukları azalt
                  itemCount: _diseaseHistory.length,
                  itemBuilder: (context, index) {
                    final history = _diseaseHistory[index];
                    final formattedDate = formatDate(history['date']);

                    return GestureDetector(
                      onLongPress: () {
                        if (history.containsKey('id') && history['id'] != null && history['id'] != '') {
                          _showDeleteConfirmation(context, history['id']); // Silme onayı
                        } else {
                          print("Hata: ID bulunamadı veya boş.");
                        }
                      },

                      child: Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'images/bakteri.png',
                              height: 45,
                              width: 30,
                            ),
                            SizedBox(width: 8,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate, // Formatlanmış tarih
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${history['disease']} : ${history['severity']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              ),
              const SizedBox(height: 16),
              TextButton(onPressed: (){
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const homePage()),
              );
              }, child: Text("Kapat", style: TextStyle(color: Colors.black)))

            ],
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0731c5),
      bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.white,
          color: const Color(0xFF0731c5),
          animationDuration: const Duration(milliseconds: 250),
          index: 2,
          onTap: (index) {
            setState(() {
              if (index == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
              } else if (index == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AnalizPage()));
              } else if (index == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  homePage()));
              } else if (index == 3) {
                _showDiseaseHistoryBottomSheet(context, _diseaseHistory);
              }
              else if (index == 4) {
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
      key: _globalKey,
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.indigoAccent, Color(0xFF0731c5)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft),
          ),
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.home,
                  color: Colors.white,
                ),
                title: const Text('Ana Sayfa', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => homePage()),
                  );
                },
              ),
              ListTile(
                leading: Image.asset(
                  'images/orphar.png',
                  height: 23,
                ),
                title: const Text('Doktor', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                ),
                title: const Text('Hastalık Analiz', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AnalizPage()),
                  );
                },
              ),
              ListTile(
                leading: Image.asset(
                  'images/virus1.png',
                  height: 23,
                ),
                title: const Text('Geçmiş Hastalıklar', style: TextStyle(color: Colors.white)),
                onTap: ()  {
                Navigator.pop(context); // Drawer'ı kapatır
                _showDiseaseHistoryBottomSheet(context, _diseaseHistory);
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.white),
                title: const Text("Çıkış Yap",style: TextStyle(color: Colors.white),),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GirisPage(),
                    )),
              )
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 13,
            left: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  color: Colors.white,
                  onPressed: () {
                    _globalKey.currentState?.openDrawer();
                  },
                ),
                Expanded(
                  child: Container(
                    height: 120,
                    color: const Color(0xFF0731c5),
                    child: const Center(
                      child: Text(
                        'restise',
                        style: TextStyle(color: Colors.white, fontSize: 40, fontFamily: 'Abril'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Positioned(
            top: 120,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    height: 120,
                    padding: const EdgeInsets.only(right: 20, top: 30, left: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 1,
                          top: 10,
                          child: Text(
                            'Hoş Geldiniz!',
                            style: TextStyle(
                              color: Color(0xFF0731c5),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Positioned(
                          top: 35,
                          child: Text(
                            "${capitalize(isim)} ${capitalize(soyisim)}",
                            style: const TextStyle(
                              color: Color(0xFF0731c5),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),

                        Positioned(
                          top: -4,
                          left: 253,
                          child: Row(
                            children: [
                              Image.asset(
                                'images/id-card.png',
                                height: 25,
                                width: 25,
                              ),
                              Text(" : $Yas"),

                            ],
                          )
                        ),
                        Positioned(
                            top: 21,
                            left: 254,
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/blood.png',
                                  height: 18,
                                  width: 25,
                                ),
                                Text(" : $KanGrubu ")

                              ],
                            )
                        ),
                        Positioned(
                            top: 43,
                            left: 253,
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/scale.png',
                                  height: 21,
                                  width: 25,
                                ),
                                Text(" : $Kilo")
                              ],
                            )
                        ),
                        Positioned(
                            top: 66,
                            left: 257,
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/ruler.png',
                                  height: 20,
                                  width: 25,
                                ),
                                Text(" :$Boy")
                              ],
                            )
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 140,
                    padding: const EdgeInsets.only(left: 10, right: 20, top: 30),
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                        border: Border.all(width: 4, color: const Color(0xFF0731c5)),
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF0731c5)),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -8,
                          left: 10,
                          child: TextButton(
                            child: const Text(
                              'Sanal\nDoktorunuz',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26.0,
                                  fontFamily: 'DancingScript'),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChatScreen()),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 20,
                          child: Image.asset(
                            'images/pharmacist.png',
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 105,
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                        border: Border.all(width: 4, color: const Color(0xFF0731c5)),
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF0731c5)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Positioned(
                          top: 10,
                          left: 10,
                          child: Icon(
                            Icons.add_a_photo,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          top: 7,
                          left: 50,
                          child: TextButton(
                            child: const Text(
                              'Semptom Analizi',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 20.0, fontFamily: 'Poppins'),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AnalizPage()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    color: Colors.transparent,
                    width: double.infinity,
                    height: 25, // Scroll alanını kapsayacak toplam yükseklik
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                    'Geçmiş Hastalıklarım',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),),

                  Container(
                    color: Colors.transparent,
                    width: double.infinity,
                    height:  MediaQuery.of(context).size.height - kBottomNavigationBarHeight - 590, // Scroll alanını kapsayacak toplam yükseklik
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator()) // Veriler yüklenirken gösterilecek
                              : _diseaseHistory.isEmpty
                              ? const Center(
                            child: Text(
                              'Henüz bir hastalık geçmişi bulunmamaktadır.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                              : ListView.builder(
                            padding: EdgeInsets.only(top: 8), // Boşlukları azalt
                            itemCount: _diseaseHistory.length,
                            itemBuilder: (context, index) {
                              final history = _diseaseHistory[index];
                              final formattedDate = formatDate(history['date']);

                              return GestureDetector(
                                onLongPress: () {
                                  if (history.containsKey('id') && history['id'] != null && history['id'] != '') {
                                    _showDeleteConfirmation(context, history['id']); // Silme onayı
                                  } else {
                                    print("Hata: ID bulunamadı veya boş.");
                                  }
                                },

                                child: Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        'images/bakteri.png',
                                        height: 45,
                                        width: 30,
                                      ),
                                      SizedBox(width: 8,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formattedDate, // Formatlanmış tarih
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${history['disease']} : ${history['severity']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),



                        ),
                      ],
                    ),
                  ),


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



void _showDiseaseHistoryBottomSheet(BuildContext context, List<Map<String, dynamic>> diseaseHistory) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Geçmiş Hastalıklar",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0731c5),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child
                  : ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: diseaseHistory.length,
                itemBuilder: (context, index) {
                  final history = diseaseHistory[index];
                  final formattedDate = history['formattedDate'] ?? history['date'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'images/bakteri.png',
                          height: 45,
                          width: 30,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate, // Formatlanmış tarih
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${history['disease']} : ${history['severity']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0731c5),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Kapat", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    },
  );
}

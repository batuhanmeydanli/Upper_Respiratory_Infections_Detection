import 'package:flutter/material.dart';
import 'homePage.dart';

class AlertPage extends StatelessWidget {
  const AlertPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Altta homePage widget'ı
          const homePage(),

          // Üstte AlertDialog
          Center(
            child: AlertDialog(
              backgroundColor: const Color(0xFFf5f5f7),
              title: const Text("Hoş geldiniz!"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/throat.png',
                      height: 140,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Merhaba! Restise doğru sonuçlar verebilmek için hastanın boğaz fotoğrafına ihtiyaç duymaktadır. "
                          "Lütfen yönergeleri dikkatlice takip ederek fotoğraf çekimini gerçekleştirin.",
                      textAlign: TextAlign.left,
                    ),
                    const Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "1. Ağzınızı olabildiğince geniş açarak bademciklerinizin görünmesini sağlayın."
                          "\n2. Dişlerinizin yaklaşık 3 ila 4 parmak genişliğinde açık olduğundan emin olun ve dilinizi dışarı çıkartın."
                          "\n3. Dişlerinizin, örnek görseldeki çizgilerin hemen dışında konumlandığından emin olun."
                          "\n4. Fotoğraf çekimini iyi aydınlatılmış bir ortamda gerçekleştirin."
                          "\n5. Daha iyi bir görüntü için arka kamerayı kullanarak çekim yapmak üzere bir yakınınızdan yardım alabilirsiniz.",
                      textAlign: TextAlign.left,
                    ),
                    const Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "📢 Dikkat: Kötü çekilmiş fotoğraflar, yanlış sonuçlara neden olabilir. "
                          "Lütfen yukarıdaki adımları eksiksiz uygulayarak doğru bir fotoğraf çekimi sağlayın.",
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Tamam"),
                  onPressed: () {
                    // homePage'e yönlendir
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const homePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'doktor.dart';
import 'homePage.dart';
import 'dart:convert'; // jsonDecode için
import 'package:http/http.dart' as http; // http işlemleri için
import 'dart:io'; // File sınıfı için gerekli
import 'dart:ui'; // BackdropFilter için gerekli
import 'dart:convert'; // jsonDecode için


class AnalizPage extends StatefulWidget {
  const AnalizPage({super.key});

  @override
  State<AnalizPage> createState() => _AnalizPageState();
}

class _AnalizPageState extends State<AnalizPage> {
  final ImagePicker _picker = ImagePicker();
  String? _predictionResult;
  String? _selectedImagePath; // Fotoğraf yolu burada saklanacak


  final ScrollController _scrollController = ScrollController();
  List<String> selectedOptions = List.filled(4, ""); // Her soru için seçim durumu
  int? lastQuestionSelection; // Yaş sorusu için seçim değeri (-1, 0, 1)
  int totalScore = 0; // Toplam puan
  bool showResults = false; // Sonuçları gösterme durumu

  String getSeverityLevel(int score) {
    if (score == 0) {
      return "Sağlıklı";
    } else if (score == 1) {
      return "Hafif Semptomlar";
    } else if (score == 2) {
      return "Hafif İlerlemiş Semptomlar";
    } else if (score == 3) {
      return "Orta Dereceli Semptomlar";
    } else if (score == 4) {
      return "Ciddi Semptomlar";
    } else {
      return "Acil Durum";
    }
  }


  Future<void> _pickAndPredictImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path; // Fotoğraf yolu kaydediliyor
      });
      final result = await sendImageToServer(image.path);
      setState(() {
        _predictionResult = result; // Tahmin sonucu kaydediliyor
      });


    } else {
      print("Fotoğraf seçilmedi.");
    }
  }




  Future<String> sendImageToServer(String imagePath) async {
    final uri = Uri.parse("http://10.0.2.2:5000/predict"); // Flask API'ye URL
    final request = http.MultipartRequest("POST", uri);

    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody);
        return json["prediction"];
      } else {
        return "Hata: ${response.statusCode}";
      }
    } catch (e) {
      return "Bağlantı hatası: $e";
    }
  }






  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text('Kameradan Fotoğraf Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndPredictImage(ImageSource.camera); // Kameradan çekme için çağrı
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Galeriden Fotoğraf Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndPredictImage(ImageSource.gallery); // Galeriden seçme için çağrı
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void calculateScore() {
    totalScore = 0; // Toplam puanı sıfırla

    // Fotoğraftan gelen tahmin sonucunu dahil et
    bool isPredictionAvailable = _predictionResult == "Tonsilit" || _predictionResult == "Faranjit";
    if (isPredictionAvailable) {
      totalScore += 1; // Tahmin edilen sonuç varsa puan artır
    }

    // Her soru için "Evet" seçiliyse puan artır
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i] == "Evet") {
        totalScore += 1;
      }
    }

    // Yaş sorusunun puanını ekle
    totalScore += (lastQuestionSelection ?? 0);

    // Eğer hiçbir veri girilmediyse -1 puan ver
    if (!isPredictionAvailable && selectedOptions.every((option) => option.isEmpty) && lastQuestionSelection == null) {
      totalScore = -1;
    }

    print("Toplam puan: $totalScore");
  }


  String getbaslik() {
    if (totalScore == 0) {
      return "Sağlıklı Görünüyorsunuz";
    } else if (totalScore == 1) {
      return "Hafif Semptomlar - Dinlenmeniz tavsiye edilir";
    } else if (totalScore == 2) {
      return "Hafif İlerlemiş Semptomlar - Bol sıvı tüketin";
    } else if (totalScore == 3) {
      return "Orta Dereceli Semptomlar - Bol vitamin alın ve nemli bir ortam sağlayın";
    } else if (totalScore == 4) {
      return "Ciddi Semptomlar - Doktora gitmeniz önerilir";
    } else if (totalScore >=5) {
      return "Acil Durum - Hemen Tıbbi Yardım Alın";
    } else {
      return "Neler olduğunu anlayamadık :(";
    }
  }

  String getSonuc() {
    if(_predictionResult=='Tonsilit' || _predictionResult=='Faranjit' && totalScore>0){
      return "$_predictionResult olmuşsunuz gibi görünüyor";
    }
    else if(_predictionResult!='Tonsilit' || _predictionResult!='Faranjit' && totalScore>0){
      return "";
    }
    else{
      return "";
    }
  }
  String getRecommendation() {
    if (totalScore == 0) {
      return "Belirgin bir semptom gözükmüyor, bu da vücudunuzun enfeksiyonlara karşı dirençli olduğunu gösteriyor. Sağlıklı yaşam alışkanlıklarını sürdürmeniz önemlidir. Günde 2-3 litre su tüketmek, bağışıklık sisteminizin optimal çalışmasına destek olabilir. Düzenli olarak taze meyve ve sebzeler tüketerek vücudunuzun ihtiyaç duyduğu vitamin ve mineralleri alabilirsiniz. Ayrıca, haftada en az 150 dakika hafif fiziksel aktivite yaparak sağlığınızı koruyabilirsiniz. Yeni semptomlar ortaya çıkarsa veya mevcut sağlık durumunuzda değişiklik hissederseniz, bir sağlık profesyoneline danışmaktan çekinmeyin.";

    }else if(_predictionResult!='Faranjit' && _predictionResult!='Tonsilit'&& totalScore==1){
      return "Vücudunuz, olası bir enfeksiyona karşı erken aşamada mücadele ediyor olabilir."
          " Hafif semptomlar, genellikle dinlenme ve sıvı tüketimiyle geçer."
          " Bol sıvı tüketmek, özellikle enfeksiyonların erken aşamalarında toksinlerin vücuttan atılmasına yardımcı olur."
          " Bitki çayları (örneğin, adaçayı, papatya çayı) ve ballı ılık su gibi boğazı rahatlatıcı içecekler tüketebilirsiniz."
          " Ayrıca eğer parasetamol içeren ilaçlara karşı alerjiniz yoksa, kısa süreli ağrı veya hafif ateş durumlarında, parasetamol içerikli ağrı kesiciler kullanabilirsiniz."
          " Bu ilaçların doktor önerisiyle alınması gerektiğini unutmayın."
          " Semptomlar 2-3 gün içinde düzelmezse, bir sağlık uzmanına danışmanız önemlidir.";

    } else if(_predictionResult=='Faranjit' && totalScore==1){
      return "Faranjit, genellikle viral enfeksiyonlar nedeniyle boğazın arka kısmında iltihaplanma ile kendini gösterir."
          " Hafif semptomlar arasında boğaz ağrısı, yutkunmada rahatsızlık, tahriş hissi ve bazen hafif bir ateş bulunur."
          " Bu durum özellikle bağışıklık sisteminin zayıf olduğu dönemlerde sık görülür."
          " Hafif semptomlar, genellikle dinlenme ve bol sıvı tüketimiyle geçer."
          " Bol sıvı tüketmek, özellikle enfeksiyonların erken aşamalarında toksinlerin vücuttan atılmasına yardımcı olur."
          " Boğazınızı rahatlatmak için ılık ballı ve limonlu su tüketebilirsiniz; bu hem boğazınızı nemlendirir hem de tahrişi azaltır."
          " Papatya veya ada çayı gibi bitki çayları, boğazınızda yatıştırıcı bir etki yaratabilir."
          " Ayrıca, tuzlu suyla gargara yaparak boğazdaki iltihabı hafifletebilirsiniz."
          " Sigara dumanından ve aşırı soğuk ya da sıcak içeceklerden kaçınarak tahrişi önleyebilirsiniz."
          " Dinlenmeye özen gösterin ve bağışıklık sisteminizi desteklemek için taze meyve ve sebze tüketimine ağırlık verin."
          " Özellikle C vitamini açısından zengin portakal, kivi ve yeşil yapraklı sebzeler tüketebilirsiniz."
          " Ayrıca eğer parasetamol içeren ilaçlara karşı alerjiniz yoksa, kısa süreli ağrı veya hafif ateş durumlarında, parasetamol içerikli ağrı kesiciler kullanabilirsiniz."
          " Bu ilaçların doktor önerisiyle alınması gerektiğini unutmayın."
          " Belirtileriniz 2-3 gün içinde düzelmezse ya da kötüleşirse bir sağlık uzmanına danışmanız önemlidir.";

    }else if(_predictionResult=='Tonsilit' && totalScore==1){
      return "Tonsilit, bademciklerin enfekte olmasıyla karakterize bir durumdur ve genellikle viral veya bakteriyel enfeksiyonlardan kaynaklanır."
          " Semptomlar arasında boğaz ağrısı, yutkunmada güçlük, yüksek ateş ve bademciklerin şişmesi görülebilir."
          " Bazı durumlarda bademciklerde beyaz veya sarı lekeler de fark edilebilir."
          " Bu semptomlar özellikle bağışıklık sisteminin zayıfladığı dönemlerde daha belirgin hale gelebilir."
          " Dinlenmek ve bol sıvı tüketmek tedavinin temel taşlarıdır."
          " Vücudunuzu nemli tutmak ve enfeksiyonla savaşmasına yardımcı olmak için su, ılık bitki çayları ve tavuk suyu gibi sıvılar tüketebilirsiniz."
          " Ilık ballı su veya tuzlu suyla gargara yapmak, boğaz ağrısını hafifletebilir ve tahrişi azaltabilir."
          " Sigara dumanından kaçınmak ve boğazı tahriş edebilecek soğuk, baharatlı veya sert gıdalardan uzak durmak önemlidir."
          " Taze meyve ve sebzeler tüketerek bağışıklık sisteminizi destekleyebilirsiniz."
          " Özellikle C vitamini bakımından zengin portakal, kivi ve çilek gibi besinler faydalı olacaktır."
          " Eğer ağrınız çok şiddetliyse veya yüksek ateşiniz varsa, doktor tavsiyesiyle ağrı kesici veya ateş düşürücü ilaçlar kullanabilirsiniz."
          " Ancak semptomlarınız 2-3 gün içinde düzelmezse veya kötüleşirse bir sağlık uzmanına başvurmanız gereklidir."
          " Bakteriyel bir enfeksiyon söz konusuysa antibiyotik tedavisi gerekebilir; bu nedenle bir doktorun değerlendirmesi önemlidir.";
    }
    else if (_predictionResult!='Faranjit' && _predictionResult!='Tonsilit'&& totalScore == 2) {
      return "Semptomlarınız hafif bir enfeksiyonun ilerlemekte olduğuna işaret ediyor."
          " Bu aşamada, bağışıklık sisteminizi destekleyecek adımlar atmak önemlidir."
          " Tuzlu suyla gargara yapmak, boğaz ağrısını hafifletmek için etkili bir yöntemdir. "
          " Nemli bir ortamda bulunarak solunum yollarınızı rahatlatabilirsiniz. "
          " Günlük sıvı alımınızı artırarak ve dinlenmeye özen göstererek vücudunuzun toparlanmasına yardımcı olun."
          " Ayrıca, kısa süreli ağrı veya hafif ateş durumlarında, parasetamol içerikli ağrı kesiciler kullanabilirsiniz."
          " Eğer belirtileriniz kötüleşir veya 3 gün içinde düzelmezse, bir sağlık uzmanına danışmanız gerekebilir.";

    }else if(_predictionResult=='Faranjit' && totalScore==2){
      return "Faranjit, genellikle viral enfeksiyonlar nedeniyle boğazın arka kısmında iltihaplanma ile kendini gösteren bir rahatsızlıktır."
          " Bu durumda boğaz ağrısı, yutkunmada zorluk, hafif ateş ve genel bir halsizlik hissedebilirsiniz."
          " Ayrıca, boğazınızda kuruluk ve tahriş hissi de sıkça görülebilir."
          " Bu seviyede, rahatsızlığın ilerlemesini engellemek ve semptomları hafifletmek için birkaç basit adım atabilirsiniz."
          " Bol sıvı tüketmek çok önemlidir."
          " Özellikle ılık ballı su ve limonlu içecekler boğazınızı nemlendirir ve tahrişi hafifletir."
          " Ayrıca, bu içecekler boğazınızda yatıştırıcı bir etki sağlayarak ağrıyı azaltabilir."
          " Tuzlu suyla gargara yapmak ise iltihabı hafifletebilir ve boğazınızı temiz tutmaya yardımcı olabilir."
          " Eğer öksürüğünüz varsa, bu yöntem boğazınızı rahatlatacaktır."
          " Nemli bir ortamda bulunarak da solunum yollarınızı rahatlatabilir ve tahrişi azaltabilirsiniz."
          " Papatya veya ada çayı gibi bitki çayları da tüketebilirsiniz, rahatlatıcı bir etki sağlacaklardır."
          " Ayrıca, çok sıcak veya çok soğuk içeceklerden kaçınmanız, boğazınızın daha fazla tahriş olmasını önleyecektir."
          " Sigara dumanı gibi tahriş edici faktörlerden uzak durun ve dinlenmeye özen gösterin."
          " Beslenmenize dikkat ederek bağışıklık sisteminizi güçlendirmeye çalışmalısınız."
          " C vitamini açısından zengin portakal, mandalina, kivi ve yeşil yapraklı sebzeler gibi besinleri tüketmeye özen gösterin."
          " Ayrıca, zencefil veya zerdeçal gibi doğal anti-inflamatuar özelliklere sahip besinleri diyetinize ekleyebilirsiniz."
          " Bu aşamada, belirtiler genellikle evde alınan önlemlerle hafifler."
          " Dinlenmeye çok önem vermelisiniz."
          " İş yükünüzü azaltarak vücudunuza toparlanması için zaman tanıyın."
          " Hafif fiziksel aktiviteler yerine tam dinlenmeyi tercih edin."
          " Eğer ağrı veya ateş şikayetiniz varsa, doktor önerisiyle hafif ağrı kesiciler kullanabilirsiniz."
          " Ancak, bu ilaçları yalnızca doktorunuzun önerdiği dozda ve süre boyunca kullanmanız gerektiğini unutmayın."
          " Belirtiler 2-3 gün içinde geçmez veya kötüleşirse, bir sağlık uzmanına başvurmanız doğru olacaktır.";

    }else if(_predictionResult=='Tonsilit' && totalScore==2){
      return "Tonsilit, genellikle bademciklerin enfeksiyon kapması sonucu ortaya çıkan bir rahatsızlıktır. "
          "Bu durumda boğaz ağrısı, yutkunmada zorluk, hafif ateş ve bademciklerde şişlik veya beyaz plak oluşumu gibi belirtiler görülebilir. "
          "Bu seviyede, rahatsızlığın ilerlemesini önlemek ve semptomları hafifletmek için birkaç basit adım atabilirsiniz. "
          "Bol sıvı tüketmek oldukça önemlidir. "
          "Özellikle ılık ballı su ve limonlu içecekler boğazınızı nemlendirir, tahrişi hafifletir ve rahatlama sağlar. "
          "Papatya veya ada çayı gibi bitki çayları tüketerek de boğazınızı yatıştırabilirsiniz."
          "Eğer ağrınız şiddetleniyorsa veya bademciklerde ciddi hassasiyet varsa, tuzlu suyla gargara yapmak iltihabı hafifletmeye yardımcı olabilir. "
          "Ayrıca, sigara dumanı gibi tahriş edici faktörlerden uzak durarak boğazınızı koruyabilirsiniz. "
          "Dinlenmeye özen göstermek ve bağışıklık sisteminizi desteklemek için meyve ve sebze tüketiminizi artırmak önemlidir. "
          "Özellikle C vitamini açısından zengin portakal, kivi ve yeşil yapraklı sebzeler tüketmek bağışıklık sisteminize destek sağlayabilir."
          "Bu aşamada, belirtiler genellikle evde alınan önlemlerle hafifler. "
          "Ancak, belirtiler 2-3 gün içinde düzelmezse veya kötüleşirse, bir sağlık uzmanına danışmanız önemlidir. "
          "Enfeksiyonun ilerlemesini önlemek için erken müdahale kritik olabilir.";

    } else if (_predictionResult!='Faranjit' && _predictionResult!='Tonsilit'&& totalScore == 3) {
      return "Semptomlarınız, vücudunuzun enfeksiyona karşı ciddi bir mücadele verdiğini gösteriyor."
          " Dinlenme süresini artırarak vücudunuzun toparlanmasına yardımcı olun."
          " Özellikle öksürük veya boğaz ağrısı yaşıyorsanız, sıcak ve rahatlatıcı içecekler tüketmek faydalı olacaktır."
          " Yüksek ateşiniz varsa, ateş düşürücü ilaçları doktor tavsiyesiyle kullanabilirsiniz."
          " Bol sıvı tüketmek ve hafif gıdalarla beslenmek bağışıklık sisteminizi destekleyecektir."
          " Eğer belirtileriniz kötüleşirse veya 2-3 gün içinde geçmezse, bir doktora başvurmanız gereklidir.";

    } else if (_predictionResult=='Faranjit' && totalScore == 3) {
      return "Faranjit, boğazın arka kısmında iltihaplanmaya yol açarak genellikle yutkunma zorluğu, belirgin boğaz ağrısı, orta dereceli ateş ve halsizlik gibi semptomlara neden olur."
          " Bu seviyede, rahatsızlık günlük yaşamı etkileyecek kadar yoğun hale gelebilir."
          " Yutkunma sırasında hissedilen ağrı artmış olabilir ve konuşurken bile rahatsızlık duyabilirsiniz."
          "Ayrıca, boyun bölgesindeki lenf bezlerinde hassasiyet ve şişlik fark edilebilir. "
          "Bu durumda, boğazınızı rahatlatmak ve semptomları hafifletmek için birkaç etkili yöntemi uygulayabilirsiniz. "
          "Ilık ballı su veya limonlu içecekler, boğazınızın rahatlamasına yardımcı olacaktır. "
          "Bunun yanı sıra, papatya, ada çayı veya zencefil çayı gibi doğal bitki çayları da boğazdaki tahrişi yatıştırır ve enfeksiyonun etkilerini hafifletir. "
          "Tuzlu suyla gargara yapmak, boğazdaki iltihabı azaltmak ve rahat bir nefes almanızı sağlamak için oldukça etkili bir yöntemdir. "
          "Ayrıca, boğaz pastilleri de yutkunma sırasında oluşan rahatsızlığı azaltabilir.Bu dönemde dinlenmeye öncelik vermelisiniz. "
          "Vücudunuz enfeksiyonla savaşırken, enerjiye ve zamana ihtiyaç duyar. "
          "Günlük aktivitelerinizi en aza indirin ve düzenli olarak nemli bir ortamda bulunmaya özen gösterin. "
          "Aşırı kuru hava veya sigara dumanı gibi tahriş edici unsurlardan kesinlikle kaçınmalısınız. "
          "Beslenmenize dikkat ederek bağışıklık sisteminizi desteklemek de oldukça önemlidir. "
          "Portakal, mandalina ve kivi gibi C vitamini açısından zengin meyveler tüketerek bağışıklık fonksiyonlarınızı artırabilirsiniz. "
          "Ayrıca, çinko içeren besinler (örneğin, kabak çekirdeği veya ceviz) vücudunuzun iyileşme sürecine katkıda bulunabilir. "
          "Eğer ateş veya ağrı şikayetiniz varsa, doktor tavsiyesiyle ağrı kesici veya ateş düşürücü ilaçlar kullanabilirsiniz. "
          "Ancak bu ilaçları yalnızca önerilen dozda kullanmanız gerektiğini unutmayın. "
          "Belirtileriniz birkaç gün içinde hafiflemiyor, aksine artıyorsa veya yutkunma zorluğu ciddi hale geldiyse, mutlaka bir doktora danışmalısınız. "
          "Bu seviyede hızlı bir değerlendirme, enfeksiyonun komplikasyonlara yol açmasını engellemek adına oldukça önemlidir.";

    } else if(_predictionResult=='Tonsilit' && totalScore==3){
      return "Tonsilit, bademciklerin iltihaplanmasıyla ortaya çıkan bir durumdur ve genellikle viral ya da bakteriyel enfeksiyonlardan kaynaklanır. "
          "Bu seviyede, belirtiler arasında belirgin boğaz ağrısı, yutkunma zorluğu, yüksek olmayan ancak rahatsızlık veren bir ateş ve genel halsizlik öne çıkar. "
          "Ayrıca bademcikler üzerinde beyaz ya da sarı plaklar görülebilir. "
          "Bademciklerin şişmesi, boyunda lenf düğümlerinin hassasiyetine ve şişmesine neden olabilir."
          "Bu durumda öncelikle bol sıvı tüketmeniz çok önemlidir. "
          "Ilık ballı su ya da limonlu içecekler boğazınızda yatıştırıcı bir etki yaratabilir. "
          "Nemli bir ortamda bulunmak, solunum yollarını rahatlatabilir ve ağrıyı hafifletebilir. "
          "Tuzlu suyla gargara yapmak bademciklerdeki iltihabı hafifletmeye yardımcı olabilir. "
          "Eğer boğazdaki ağrı çok yoğunsa, yumuşak ve kolay yutulan yiyecekler tüketmek daha rahat etmenizi sağlayabilir."
          "Dinlenmek bağışıklık sisteminizin enfeksiyonla daha etkili mücadele etmesine yardımcı olacaktır. "
          "Bu dönemde sigara dumanı gibi tahriş edici maddelerden uzak durmanız önemlidir. "
          "Ayrıca, C vitamini açısından zengin meyve ve sebzeler tüketerek bağışıklık sisteminizi destekleyebilirsiniz. "
          "Portakal, kivi, kırmızı biber ve yeşil yapraklı sebzeler bu konuda faydalı olacaktır."
          "Eğer semptomlar 2-3 gün içinde iyileşmez veya kötüleşirse, mutlaka bir sağlık uzmanına başvurmalısınız. "
          "Tonsilitin bakteriyel bir enfeksiyondan kaynaklanma ihtimali varsa, doktorunuz antibiyotik tedavisi önerebilir. "
          "Ancak, doktor tavsiyesi olmadan antibiyotik ya da başka ilaçlar kullanmaktan kaçınmalısınız.";

    }else if (_predictionResult!='Faranjit' && _predictionResult!='Tonsilit'&& totalScore == 4) {
      return "Semptomlarınız ciddi bir enfeksiyona işaret ediyor."
          " Şiddetli boğaz ağrısı, lenf düğümlerinde şişlik, yüksek ateş veya yutkunma zorluğu yaşıyorsanız, bir sağlık uzmanına danışmanız önemlidir."
          " Bu aşamada, evde uygulayacağınız yöntemler yalnızca geçici bir rahatlama sağlayabilir."
          " Tuzlu suyla gargara yapmak ve boğaz pastilleri kullanmak semptomlarınızı hafifletebilir."
          " Ancak, doktor değerlendirmesi olmadan antibiyotik veya diğer ilaçları kullanmaktan kaçının."
          " En kısa sürede bir sağlık kuruluşuna başvurarak doğru tedaviyi almayı ihmal etmeyin.";

    } else if (_predictionResult=='Faranjit' && totalScore == 4) {
      return "Faranjit, boğazın arka kısmında şiddetli iltihaplanmaya neden olan bir durumdur ve bu seviyede semptomlar daha ciddi bir hal almıştır. "
          "Yutkunma sırasında dayanılması güç bir ağrı, yüksek ateş, genel halsizlik, iştahsızlık ve boğazda belirgin bir şişlik hissedebilirsiniz. "
          "Ayrıca boyun bölgesindeki lenf bezlerinde şişlik ve hassasiyet oluşabilir. "
          "Bu durum, günlük hayatınızı önemli ölçüde etkileyebilir ve ihmal edilmemesi gerekir."
          "Bu seviyede boğaz ağrınızı hafifletmek için ılık ballı su içebilir, papatya veya ada çayı gibi rahatlatıcı bitki çaylarını deneyebilirsiniz. "
          "Tuzlu suyla gargara yapmak boğazdaki şişliğin azalmasına ve iltihabın hafiflemesine yardımcı olabilir. "
          "Bunun yanı sıra, boğaz pastilleri yutkunma sırasında yaşanan rahatsızlığı azaltabilir. "
          "Ancak bu yöntemler yalnızca semptomları geçici olarak hafifletir."
          "Etrafınızdaki hava kalitesine dikkat etmeli, sigara dumanından ve kirli havadan kaçınmalısınız. "
          "Nemli bir ortamda bulunarak boğazınızın daha az tahriş olmasını sağlayabilirsiniz. "
          "Bunun için bir nemlendirici cihaz kullanabilir veya odanızın havasını nemli tutmak için bir kap su bulundurabilirsiniz. "
          "Dinlenmeye önem vermeli ve vücudunuzun enfeksiyonla savaşmasına olanak tanımalısınız. "
          "Bu süreçte enerji harcayan aktivitelerden kaçınmalısınız."
          "Beslenme konusunda bağışıklık sisteminizi destekleyecek yiyeceklere ağırlık vermeniz önemlidir. "
          "C vitamini açısından zengin portakal, greyfurt, kivi gibi meyveler tüketebilir ve bol bol sıvı alarak vücudunuzun toksinlerden arınmasını destekleyebilirsiniz. "
          "Protein ve çinko içeren besinler (örneğin, tavuk çorbası, balık veya badem) vücudunuzun toparlanma sürecine katkıda bulunabilir."
          "Ancak bu seviyedeki semptomlar genellikle evde uygulanacak yöntemlerle tamamen iyileşmeyebilir. "
          "Ağrınız şiddetliyse, ateşiniz düşmüyorsa veya boğazınızdaki şişlik giderek artıyorsa, mutlaka bir doktora başvurmalısınız. "
          "Doktorunuz gerek görürse antibiyotik tedavisine başlayabilir veya daha kapsamlı bir değerlendirme yapabilir. "
          "Bu aşamada bir sağlık uzmanının yönlendirmesi, enfeksiyonun kontrol altına alınması ve komplikasyonların önlenmesi için hayati önem taşır.";

    }else if(_predictionResult=='Tonsilit' && totalScore==4){
      return "Tonsilit, bademciklerin ciddi şekilde iltihaplanmasına neden olan bir durumdur ve bu seviyede belirtiler genellikle daha belirgindir. "
          "Boğaz ağrısı dayanılmaz hale gelebilir ve yutkunma büyük ölçüde zorlaşabilir. "
          "Ayrıca yüksek ateş, halsizlik, boyundaki lenf düğümlerinde şişlik ve hassasiyet görülebilir. "
          "Bademciklerin üzerinde beyaz veya sarı plaklar bulunabilir ve bu, enfeksiyonun daha ilerlediğine işaret eder."
          "Bu aşamada ağrıyı hafifletmek ve iyileşmeyi hızlandırmak için birkaç önemli adım atabilirsiniz. "
          "Bol sıvı tüketimi burada da çok önemlidir. Ancak, boğazdaki şişlik nedeniyle yutkunmada zorluk yaşayabileceğiniz için sıvıları yavaş yavaş ve küçük yudumlarla içmek faydalı olacaktır. "
          "Ilık ballı su, boğazınızı nemlendirerek ağrıyı hafifletebilir. "
          "Nemli bir ortamda bulunmak, solunum yollarınızı rahatlatabilir. "
          "Bunun yanında, tuzlu suyla gargara yaparak bademciklerdeki iltihabı hafifletmeye yardımcı olabilirsiniz."
          "Yumuşak ve kolay yutulabilir yiyecekler tercih etmek önemlidir. "
          "Çorba, yoğurt veya püre gibi hafif besinler tüketmek, yemek yerken oluşan rahatsızlığı en aza indirir. "
          "Sigara dumanı gibi tahriş edici faktörlerden uzak durarak boğazınızın daha fazla zarar görmesini önleyebilirsiniz."
          "Dinlenmek bu aşamada büyük önem taşır. "
          "Vücudunuz enfeksiyonla savaşırken enerjiye ihtiyaç duyar ve bu nedenle yeterince dinlenmek bağışıklık sisteminizin daha etkili çalışmasına yardımcı olacaktır. "
          "Ayrıca bağışıklığınızı desteklemek için taze meyve ve sebzeler tüketmeye özen gösterin. "
          "Özellikle C vitamini yönünden zengin olan portakal, çilek, kırmızı biber ve brokoli faydalı olacaktır."
          "Eğer belirtileriniz 2-3 gün içinde düzelmez, kötüleşir ya da nefes almakta veya yutkunmada ciddi zorluk yaşarsanız, mutlaka bir sağlık uzmanına başvurmanız gerekir. "
          "Doktorunuz durumunuza uygun antibiyotik tedavisi veya başka bir medikal müdahale önerebilir. "
          "Ancak unutmayın, antibiyotikler yalnızca doktor önerisiyle kullanılmalıdır.";

    } else if (_predictionResult!='Faranjit' && _predictionResult!='Tonsilit'&& totalScore >= 5) {
      return "Belirtileriniz ciddi bir enfeksiyon veya komplikasyon riskine işaret ediyor olabilir."
          " Yüksek ateş (39°C ve üzeri), nefes almakta güçlük veya yutma zorluğu gibi semptomlarla karşılaşırsanız, bu bir acil durum olabilir."
          " Hemen bir sağlık kuruluşuna başvurmanız hayati önem taşır."
          " Tonsillit veya faranjit gibi ciddi durumlarda, enfeksiyonun yayılmasını önlemek için uzman değerlendirmesi gerekebilir."
          " Doktorunuz, enfeksiyonun türüne göre antibiyotik tedavisi veya başka medikal müdahaleler uygulayabilir."
          " Kendi başınıza ilaç kullanımından kaçınmalı ve tıbbi yardım almayı geciktirmemelisiniz.";

    }else if (_predictionResult=='Faranjit' && totalScore >= 5) {
      return "Faranjit, boğazın arka kısmında meydana gelen ve genellikle viral enfeksiyonlardan kaynaklanan bir iltihaplanmadır. "
          "Ancak, bu durumda semptomlarınız çok daha ciddi bir seviyeye ulaşmış olabilir. "
          "Şiddetli boğaz ağrısı, yüksek ateş, yutkunmada ciddi zorluklar ve halsizlik bu aşamada sıkça görülen belirtilerdir. "
          "Bu semptomlar, vücudunuzun enfeksiyona karşı güçlü bir mücadele verdiğini ve artık kendi kendine geçebilecek bir durumda olmadığını gösterebilir."
          "Bu noktada, evde alınacak önlemler yalnızca kısa süreli rahatlama sağlayabilir. "
          "Tuzlu suyla gargara yapmak, boğazınızı rahatlatabilir, ancak iltihaplanmayı tamamen hafifletmeyecektir. "
          "Yeterli sıvı alımına devam edin; özellikle ılık ballı su, boğazınızı nemlendirmek için faydalı olabilir. "
          "Bunun yanında, nemli bir ortamda bulunmak solunum yollarınızı rahatlatacaktır."
          "Bununla birlikte, artık mutlaka bir sağlık uzmanına başvurmanız gerekir. "
          "Faranjit bu aşamada komplikasyonlara neden olabilir ve bazen antibiyotik tedavisi ya da diğer medikal müdahaleler gerektirebilir. "
          "Evde denediğiniz yöntemlerle belirtilerinizde herhangi bir iyileşme olmuyorsa ya da durumunuz kötüleşiyorsa, gecikmeden bir doktora danışmanız çok önemlidir. "
          "Kendi başınıza ilaç kullanmaktan kaçının ve sağlık profesyonelinin yönlendirmelerini takip edin. "
          "Sağlığınız için erken müdahale bu aşamada kritik önem taşır.";

    }else if(_predictionResult=='Tonsilit' && totalScore>=5){
      return "Tonsilit, bademciklerin ciddi şekilde iltihaplanmasına neden olan bir durumdur ve bu seviyede oldukça ciddi bir enfeksiyon halindedir. "
          "Bademciklerde yoğun iltihaplanma, bademciklerin üzerinde kalın beyaz veya sarı plaklar, yüksek ateş (39°C ve üzeri), şiddetli boğaz ağrısı, yutkunmada ciddi zorluk, konuşma ve nefes almada rahatsızlık gibi belirtiler görülebilir. "
          "Boyundaki lenf düğümleri büyük ölçüde şişmiş ve ağrılı olabilir. "
          "Ayrıca, genel bir halsizlik ve iştahsızlık da yaygındır. "
          "Bu aşamada enfeksiyonun çevredeki dokulara veya vücudun diğer bölgelerine yayılma riski yüksektir."
          "Bu durumda evde uygulayabileceğiniz yöntemler yalnızca geçici bir rahatlama sağlayabilir. "
          "Ilık ballı su veya papatya çayı gibi rahatlatıcı içecekler, boğazı nemlendirmek ve tahrişi hafifletmek için kullanılabilir. "
          "Tuzlu suyla gargara yapmak, iltihaplanmayı bir miktar hafifletebilir ve boğazdaki mikroorganizmaların azaltılmasına yardımcı olabilir. "
          "Ancak bu aşamada bu tür önlemler genellikle yeterli değildir."
          "Yumuşak gıdalar tüketmek ve aşırı sıcak ya da soğuk yiyeceklerden kaçınmak boğaz ağrısını bir miktar hafifletebilir. "
          "Bununla birlikte, boğazdaki şişlik nedeniyle sıvı alımı ve beslenme zorlaşabileceği için, vücudun susuz kalmaması adına sıvı tüketimi öncelikli olmalıdır."
          "Mutlaka bir doktora başvurmanız gerekir. Bu seviyedeki tonsilit genellikle antibiyotik tedavisi gerektirir ve enfeksiyonun yayılmasını önlemek için zamanında müdahale çok önemlidir. "
          "Doktorunuz, bademciklerdeki iltihaplanmayı azaltmak ve enfeksiyonu kontrol altına almak için uygun bir tedavi planı uygulayacaktır. "
          "Ağrı yönetimi ve ateş düşürme için doktor tarafından önerilen ilaçlar kullanılabilir."
          "Nefes almakta veya yutkunmakta ciddi zorluk, ateşin uzun süre düşmemesi, şiddetli halsizlik gibi durumlar acil müdahale gerektirir. "
          "Tonsilitin bu şiddetli hali, apse oluşumu (peritonsiller apse) veya diğer komplikasyonlara yol açabilir. "
          "Bu tür belirtilerle karşılaşırsanız, en kısa sürede bir sağlık kuruluşuna gitmelisiniz."
          "Unutmayın, tonsilitin bu seviyesi profesyonel tıbbi bakım gerektirir ve erken müdahale ciddi komplikasyonları önleyebilir.";

    }else {
      return "Durumunuz hakkında daha fazla bilgiye ihtiyacımız var.";
    }
  }


  void scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }


  void handleOptionSelection(int index, String option) {
    setState(() {
      if (selectedOptions[index] == option) {
        // Eğer aynı seçeneğe tekrar basılmışsa seçimi iptal et
        selectedOptions[index] = "";
      } else {
        // Yeni bir seçim yapıldıysa mevcut seçimi güncelle
        selectedOptions[index] = option;
      }
      calculateScore(); // Puanı tekrar hesapla
    });
  }

  void handleAgeSelection(int value) {
    setState(() {
      if (lastQuestionSelection == value) {
        // Eğer aynı yaş seçimine tekrar basılmışsa iptal et
        lastQuestionSelection = null;
      } else {
        // Yeni yaş seçimini kaydet
        lastQuestionSelection = value;
      }
      calculateScore(); // Puanı tekrar hesapla
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0731c5),
        iconTheme: IconThemeData(color: Colors.white),
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
      backgroundColor: Color(0xFF0731c5),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Color(0xFF0731c5),
        animationDuration: Duration(milliseconds: 250),
        index: 1,
        onTap: (index) {
          setState(() {
            if (index == 0) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ChatScreen()));
            } else if (index == 1) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ChatScreen()));
            } else if (index == 2) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => homePage()));
            } else if (index == 3) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ChatScreen()));
            } else if (index == 4) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ChatScreen()));
            }
          });
        },
        items: [
          Image.asset(
            'images/orphar.png',
            height: 25,
          ),
          Icon(Icons.add_a_photo, color: Colors.white),
          Icon(Icons.home, color: Colors.white),
          Image.asset(
            'images/virus1.png',
            height: 23,
          ),
          Image.asset(
            'images/user.png',
            height: 23,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 12,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Color(0xFF0731c5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Semptom Analiz Sayfası',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),SizedBox(height: 12,),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 180,
                              padding: const EdgeInsets.only(right: 2, left: 1, top: 20),
                              margin: const EdgeInsets.symmetric(horizontal: 80.0),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: GestureDetector(
                                onTap: _showPhotoOptions,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Fotoğraf varsa göster
                                      if (_selectedImagePath != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.file(
                                                File(_selectedImagePath!),
                                                fit: BoxFit.cover,
                                              ),
                                              BackdropFilter(
                                                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Blur efekti
                                                child: Container(
                                                  color: Colors.black.withOpacity(0.1), // Hafif bir arka plan rengi
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Fotoğraf kaldırma çarpı işareti
                                      if (_selectedImagePath != null)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImagePath = null; // Fotoğrafı sıfırla
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Fotoğraf yoksa ikon ve metni göster
                                      if (_selectedImagePath == null)
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey[700]),
                                              SizedBox(height: 8),
                                              Text(
                                                'Fotoğraf Ekleyin',
                                                style: TextStyle(color: Colors.grey[700], fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),


                            SizedBox(height: 15),
                            ...["Ateşiniz 38'den çok mu?",
                              "Öksürük var mı?",
                              "Boynun ön tarafında şişmiş ve hassas lenf düğümleri var mı?",
                              "Bademcikleriniz şiş veya beyaz plaklarla kaplı mı?"].asMap().entries.map((entry) {
                              int index = entry.key;
                              String question = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFe9e9e9),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF0731c5),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            question,
                                            style: TextStyle(
                                                color: Colors.white, fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedOptions[index] = "Evet";
                                            calculateScore();
                                            if (index == 2) scrollToBottom();
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: selectedOptions[index] == "Evet"
                                                ? Color(0xFF0731c5)
                                                : Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(25),
                                            border: Border.all(color: Color(0xFF0731c5)),
                                          ),
                                          child: Text(
                                            "Evet",
                                            style: TextStyle(
                                              color: selectedOptions[index] == "Evet"
                                                  ? Colors.white
                                                  : Color(0xFF0731c5),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedOptions[index] = "Hayır";
                                            calculateScore();
                                            if (index == 2) scrollToBottom();
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: selectedOptions[index] == "Hayır"
                                                ? Color(0xFF0731c5)
                                                : Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(25),
                                            border: Border.all(color: Color(0xFF0731c5)),
                                          ),
                                          child: Text(
                                            "Hayır",
                                            style: TextStyle(
                                              color: selectedOptions[index] == "Hayır"
                                                  ? Colors.white
                                                  : Color(0xFF0731c5),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFe9e9e9),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF0731c5),
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: Text(
                                          "Yaşınız kaç?",
                                          style: TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          lastQuestionSelection = 1; // 3-14
                                          calculateScore();
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: lastQuestionSelection == 1 ? Color(0xFF0731c5) : Colors.white,
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(color: Color(0xFF0731c5)),
                                        ),
                                        child: Text(
                                          "3-14",
                                          style: TextStyle(
                                            color: lastQuestionSelection == 1 ? Colors.white : Color(0xFF0731c5),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          lastQuestionSelection = 0; // 15-44
                                          calculateScore();
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: lastQuestionSelection == 0 ? Color(0xFF0731c5) : Colors.white,
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(color: Color(0xFF0731c5)),
                                        ),
                                        child: Text(
                                          "15-44",
                                          style: TextStyle(
                                            color: lastQuestionSelection == 0 ? Colors.white : Color(0xFF0731c5),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          lastQuestionSelection = -1; // 44<
                                          calculateScore();
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: lastQuestionSelection == -1 ? Color(0xFF0731c5) : Colors.white,
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(color: Color(0xFF0731c5)),
                                        ),
                                        child: Text(
                                          "44<",
                                          style: TextStyle(
                                            color: lastQuestionSelection == -1 ? Colors.white : Color(0xFF0731c5),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                               onPressed: () async {
                                setState(() {
                                  calculateScore();
                                  showResults = true;
                                  scrollToBottom();
                                });
                                // Firestore'a kaydetme işlemi
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null && _predictionResult != null) {
                                  final severity = getSeverityLevel(totalScore); // Hastalık seviyesini belirle
                                  await FirestoreService().savePredictionResultWithSeverity(
                                    user.uid,
                                    _predictionResult!,
                                    severity,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Sonuçlar kaydedildi: $_predictionResult - $severity",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0731c5),
                                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'Sonuçları Göster',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                            if (showResults) ...[
                              SizedBox(height: 40),
                              Align(
                                alignment: Alignment.topCenter,
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getbaslik(),
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 20,),
                                    Visibility(
                                      visible: getSonuc().isNotEmpty, // Eğer sonuç boş değilse göster
                                      child: Text(
                                        getSonuc(),
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),

                                    Text(
                                      getRecommendation(),
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black87,
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                              SizedBox(height: 50),
                            ],
                          ],
                        ),
                      ),
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


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePredictionResultWithSeverity(
      String userId, String disease, String severity) async {
    try {
      final collectionRef = _firestore
          .collection('users') // Ana koleksiyon
          .doc(userId) // Kullanıcı dokümanı
          .collection('history'); // Alt koleksiyon

      await collectionRef.add({
        'disease': disease,
        'severity': severity,
        'date': DateTime.now().toIso8601String(), // Kayıt tarihi
      });

      print("Hastalık geçmişi başarıyla kaydedildi!");
    } catch (e) {
      print("Firestore kaydetme hatası: $e");
    }
  }
}

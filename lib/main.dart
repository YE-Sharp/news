import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RssFeedScreen(),
    );
  }
}

class RssFeedScreen extends StatefulWidget {
  @override
  _RssFeedScreenState createState() => _RssFeedScreenState();
}

class _RssFeedScreenState extends State<RssFeedScreen> {
  List<RssItem> rssItems = [];

  @override
  void initState() {
    super.initState();
    fetchRssFeeds();
  }

  Future<void> fetchRssFeeds() async {
    List<String> urls = [
      "https://www.haberturk.com/rss/kategori/gundem.xml",
      "https://www.haberturk.com/rss/kategori/is-yasam.xml",
      "https://www.haberturk.com/rss/kategori/dunya.xml"
    ];

    for (String url in urls) {
      List<RssItem> items = await getNewsByCategory(url);
      setState(() {
        rssItems.addAll(items);
      });
    }
  }

  Future<List<RssItem>> getNewsByCategory(String url) async {
    String xmlString = await getRss(url);

    if (xmlString.isEmpty) {
      print("RSS verisi alınamadı: $url");
      return [];
    }

    final document = xml.XmlDocument.parse(xmlString);
    final channel = document.findAllElements("channel").first;

    final items = channel.findElements("item");
    List<RssItem> rssItemList = [];

    for (var item in items) {
      String title = item.findElements("title").first.text;
      String pubDate = item.findElements("pubDate").first.text;
      String link = item.findElements("link").first.text;
      String image = item.findElements("image").isNotEmpty
          ? item.findElements("image").first.text
          : "";
      String description = item.findElements("description").first.text;

      rssItemList.add(RssItem(
        title: title,
        pubDate: pubDate,
        link: link,
        image: image,
        description: description,
      ));
    }
    return rssItemList;
  }

  Future<String> getRss(String url) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout =
          const Duration(milliseconds: 5000); // Bağlantı için 5 saniye
      dio.options.receiveTimeout =
          const Duration(milliseconds: 3000); // Yanıt almak için 3 saniye
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        print("HTTP Hatası: ${response.statusCode}, Cevap: ${response.data}");
        return "";
      }
    } catch (e) {
      if (e is DioError) {
        // DioError durumunda, hata ayrıntılarına erişim
        print("DioError oluştu: ${e.message}");
        print("Hata Tipi: ${e.type}");
        if (e.response != null) {
          print("Cevap Durum Kodu: ${e.response?.statusCode}");
          print("Cevap Verisi: ${e.response?.data}");
        } else {
          print("Sunucuya erişilemiyor veya zaman aşımı oldu.");
        }
      } else {
        print("Beklenmeyen Hata: $e");
      }
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RSS Haberler'),
      ),
      body: rssItems.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: rssItems.length,
              itemBuilder: (context, index) {
                final item = rssItems[index];
                return NewPreviewComponent(item: item, index: index);
              },
            ),
    );
  }
}

class NewPreviewComponent extends StatelessWidget {
  NewPreviewComponent({super.key, required this.item, required this.index});

  final RssItem item;
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      child: Container(
        margin: const EdgeInsets.all(10),
        // padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xfff2f2f2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  height: 30,
                  width: 40,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(8),
                          topLeft: Radius.circular(8)),
                      color: Colors.red.shade500),
                  child: Center(
                    child: Text(
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                      index.toString() ?? "0",
                    ),
                  ),
                )
              ],
            ),
            Container(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.image.isNotEmpty)                  
                    Image.network(
                      item.image,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(height: 10),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Yayın Tarihi: ${item.pubDate}",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class RssItem {
  final String title;
  final String pubDate;
  final String link;
  final String image;
  final String description;

  RssItem({
    required this.title,
    required this.pubDate,
    required this.link,
    required this.image,
    required this.description,
  });
}

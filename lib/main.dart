import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gapopa Task Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageGallery(),
    );
  }
}

class ImageGallery extends StatefulWidget {
  const ImageGallery({Key? key}) : super(key: key);

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final String apiKey = "19638506-cdd7d461185a335a510193d37";
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _images = [];
  int _page = 1;
  bool _loading = false;
  bool _isFullscreen = false;
  String _selectedImageURL = '';

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchImages();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchImages();
      }
    });
  }

  Future<void> fetchImages({String query = ""}) async {
    setState(() {
      _loading = true;
    });

    String url =
        "https://pixabay.com/api/?key=$apiKey&page=$_page&q=${query.isEmpty ? '' : Uri.encodeComponent(query)}";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      setState(() {
        _images.addAll(data['hits']);
        _page++;
        _loading = false;
      });
    } catch (error) {
      print("Error fetching images: $error");
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search Images',
          ),
          onSubmitted: (value) {
            setState(() {
              _images.clear();
              _page = 1;
            });
            fetchImages(query: value);
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _images.clear();
            _page = 1;
          });
          await fetchImages();
        },
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _isFullscreen ? 1 : _calculateCrossAxisCount(MediaQuery.of(context).size.width),
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: _images.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _isFullscreen = true;
                  _selectedImageURL = _images[index]['largeImageURL'];
                });
              },
              child: Hero(
                tag: _images[index]['largeImageURL'],
                child: _isFullscreen && _selectedImageURL == _images[index]['largeImageURL']
                    ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFullscreen = false;
                      _selectedImageURL = '';
                    });
                  },
                  child: Image.network(
                    _selectedImageURL,
                    fit: BoxFit.cover,
                  ),
                )
                    : Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CachedNetworkImage(
                            imageUrl: _images[index]['webformatURL'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.favorite, color: Colors.red),
                            Text(
                              "${_images[index]['likes']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 20.0),
                            const Icon(Icons.remove_red_eye, color: Colors.blue),
                            Text(
                              "${_images[index]['views']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _isFullscreen
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _isFullscreen = false;
            _selectedImageURL = '';
          });
        },
        child: const Icon(Icons.close),
      )
          : null,
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) {
      return 4;
    } else if (width > 800) {
      return 3;
    } else if (width > 600) {
      return 2;
    } else {
      return 1;
    }
  }
}

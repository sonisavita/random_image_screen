import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Image App',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const RandomImageScreen(),
    );
  }
}

class RandomImageScreen extends StatefulWidget {
  const RandomImageScreen({super.key});

  @override
  State<RandomImageScreen> createState() => _RandomImageScreenState();
}

class _RandomImageScreenState extends State<RandomImageScreen>
    with SingleTickerProviderStateMixin {

  String? imageUrl;
  bool isLoading = false;
  Color backgroundColor = Colors.black;

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  static const apiBase = "https://november7-730026606190.europe-west1.run.app";

  @override
  void initState() {
    super.initState();

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeIn,
    );

    fetchImage();
  }

  Future<void> fetchImage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse("$apiBase/image"));

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch image");
      }

      final data = jsonDecode(response.body);
      final apiUrl = data["url"];

      final forcedUrl = "$apiUrl?ts=${DateTime.now().millisecondsSinceEpoch}";

      setState(() {
        imageUrl = forcedUrl;
      });

      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(forcedUrl),
        maximumColorCount: 20,
      );

      final dominant = palette.dominantColor?.color ?? backgroundColor;

      setState(() {
        backgroundColor = dominant;
      });

      fadeController.reset();
      fadeController.forward();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading image: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                if (isLoading)
                  const CircularProgressIndicator()
                else if (imageUrl != null)
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Semantics(
                      label: "Random image fetched from API",
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey.shade300),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                Semantics(
                  button: true,
                  label: "Load another image",
                  child: ElevatedButton(
                    onPressed: fetchImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: const Text("Another"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
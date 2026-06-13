import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_screen.dart';
import 'landing_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/vid.mp4')
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        // Mute to allow autoplay on web
        _controller.setVolume(0.0);
        _controller.play().catchError((e) {
          debugPrint('Autoplay error: $e');
        });
        
        // Listen for when the video finishes
        _controller.addListener(() {
          if (_controller.value.isInitialized) {
            final duration = _controller.value.duration;
            final position = _controller.value.position;
            if (position >= duration && duration > Duration.zero) {
              _goToLogin();
            }
          }
        });
      }).catchError((error) {
        debugPrint('Initialize error: $error');
        setState(() {
          _error = error.toString();
        });
      });
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LandingScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_initialized && !_controller.value.isPlaying) {
            // Unmute on tap and play
            _controller.setVolume(1.0);
            _controller.play();
            setState((){});
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Erro ao carregar vídeo:\n$_error', style: const TextStyle(color: Colors.red, fontSize: 16)),
                ),
              )
            else if (_initialized) ...[
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (!_controller.value.isPlaying)
                const Center(
                  child: Icon(Icons.play_circle_fill, size: 80, color: Colors.white70),
                ),
            ] else
              Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
            
          ],
        ),
      ),
    );
  }
}

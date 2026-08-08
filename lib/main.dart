import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BabFmApp());
}

class BabFmApp extends StatelessWidget {
  const BabFmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BAB FM',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: const RadioHome(),
    );
  }
}

class RadioHome extends StatefulWidget {
  const RadioHome({super.key});

  @override
  State<RadioHome> createState() => _RadioHomeState();
}

class _RadioHomeState extends State<RadioHome> {
  static const fm = MethodChannel('bab.fm/radio');

  double frequency = 99.5;
  bool playing = false;
  bool recording = false;
  List<double> favorites = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      favorites = (prefs.getStringList('favorites') ?? [])
          .map(double.parse)
          .toList();
    });
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'favorites',
      favorites.map((e) => e.toString()).toList(),
    );
  }

  Future<void> tune(double value) async {
    final newFrequency =
        double.parse(value.clamp(76.0, 108.0).toStringAsFixed(1));

    setState(() {
      frequency = newFrequency;
    });

    try {
      await fm.invokeMethod('tune', {
        'frequency': newFrequency,
      });
    } catch (_) {}
  }

  Future<void> startRadio() async {
    try {
      await fm.invokeMethod('start');

      await fm.invokeMethod('tune', {
        'frequency': frequency,
      });

      setState(() {
        playing = true;
      });
    } catch (_) {
      showMessage('FM driver integration yana bukatar gyara.');
    }
  }

  Future<void> stopRadio() async {
    try {
      await fm.invokeMethod('stop');
    } catch (_) {}

    setState(() {
      playing = false;
    });
  }

  Future<void> autoScan() async {
    try {
      final result =
          await fm.invokeMethod<List<dynamic>>('scan');

      if (result != null && result.isNotEmpty) {
        await tune((result.first as num).toDouble());

        showMessage(
          'An samu stations ${result.length}.',
        );
      } else {
        showMessage(
          'Ba a samu station ba tukuna.',
        );
      }
    } catch (_) {
      showMessage(
        'Auto Scan yana bukatar FM driver na wayar.',
      );
    }
  }

  Future<void> recordingControl() async {
    try {
      if (!recording) {
        await fm.invokeMethod('startRecording');

        setState(() {
          recording = true;
        });
      } else {
        await fm.invokeMethod('stopRecording');

        setState(() {
          recording = false;
        });
      }
    } catch (_) {
      showMessage(
        'Direct FM Recording yana bukatar FM driver integration.',
      );
    }
  }

  Future<void> toggleFavorite() async {
    if (favorites.contains(frequency)) {
      favorites.remove(frequency);
    } else {
      favorites.add(frequency);
    }

    await saveFavorites();

    setState(() {});
  }

  Future<void> sleepTimer() async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [5, 10, 20, 30, 60]
              .map(
                (minutes) => ListTile(
                  leading: const Icon(Icons.bedtime),
                  title: Text('$minutes minutes'),
                  onTap: () {
                    Navigator.pop(context, minutes);
                  },
                ),
              )
              .toList(),
        );
      },
    );

    if (minutes == null) return;

    Future.delayed(
      Duration(minutes: minutes),
      () {
        if (mounted && playing) {
          stopRadio();
        }
      },
    );

    showMessage(
      'Sleep timer: $minutes minutes.',
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = favorites.contains(frequency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BAB FM v1'),
        actions: [
          IconButton(
            tooltip: 'Auto Scan',
            onPressed: autoScan,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.radio,
            size: 90,
          ),

          const SizedBox(height: 15),

          Center(
            child: Text(
              '${frequency.toStringAsFixed(1)} MHz',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Slider(
            min: 76,
            max: 108,
            divisions: 320,
            value: frequency,
            onChanged: tune,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 40,
                onPressed: () => tune(frequency - 0.1),
                icon: const Icon(
                  Icons.remove_circle_outline,
                ),
              ),

              const SizedBox(width: 15),

              FilledButton.icon(
                onPressed:
                    playing ? stopRadio : startRadio,
                icon: Icon(
                  playing
                      ? Icons.stop
                      : Icons.play_arrow,
                ),
                label: Text(
                  playing ? 'STOP' : 'PLAY',
                ),
              ),

              const SizedBox(width: 15),

              IconButton(
                iconSize: 40,
                onPressed: () => tune(frequency + 0.1),
                icon: const Icon(
                  Icons.add_circle_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: toggleFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                label: const Text('Favorite'),
              ),

              OutlinedButton.icon(
                onPressed: recordingControl,
                icon: Icon(
                  recording
                      ? Icons.stop
                      : Icons.fiber_manual_record,
                ),
                label: Text(
                  recording
                      ? 'Stop Recording'
                      : 'Record',
                ),
              ),

              OutlinedButton.icon(
                onPressed: sleepTimer,
                icon: const Icon(Icons.bedtime),
                label: const Text('Sleep'),
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Text(
            '❤️ Favorites',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text(
                'Babu favorite station tukuna.',
              ),
            ),

          ...favorites.map(
            (station) => ListTile(
              leading: const Icon(Icons.radio),
              title: Text(
                '${station.toStringAsFixed(1)} MHz',
              ),
              onTap: () => tune(station),
            ),
          ),

          const Divider(height: 30),

          const Text(
            '🇳🇬 Nigeria / 🇳🇪 Niger',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Auto Scan zai gano FM stations '
            'da suke cikin yankinka.',
          ),

          const SizedBox(height: 15),

          const Text(
            '🌐 BAB FM an tsara shi domin '
            'FM reception ba tare da internet ba.',
          ),
        ],
      ),
    );
  }
}

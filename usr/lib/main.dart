import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const PaintingApp());
}

class PaintingApp extends StatelessWidget {
  const PaintingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painting App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const PaintingScreen(),
    );
  }
}

class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;

  DrawnLine({required this.path, required this.color, required this.width});
}

class PaintingScreen extends StatefulWidget {
  const PaintingScreen({super.key});

  @override
  State<PaintingScreen> createState() => _PaintingScreenState();
}

class _PaintingScreenState extends State<PaintingScreen> {
  List<DrawnLine> lines = [];
  List<DrawnLine> redoLines = [];
  
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;

  final List<Color> colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
  ];

  void onPanStart(DragStartDetails details) {
    setState(() {
      lines.add(DrawnLine(
        path: [details.localPosition],
        color: selectedColor,
        width: strokeWidth,
      ));
      redoLines.clear();
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    setState(() {
      lines.last.path.add(details.localPosition);
    });
  }

  void onPanEnd(DragEndDetails details) {
    // Handled intrinsically
  }

  void undo() {
    if (lines.isNotEmpty) {
      setState(() {
        redoLines.add(lines.removeLast());
      });
    }
  }

  void redo() {
    if (redoLines.isNotEmpty) {
      setState(() {
        lines.add(redoLines.removeLast());
      });
    }
  }

  void clear() {
    setState(() {
      lines.clear();
      redoLines.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Flutter Painter'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: lines.isNotEmpty ? undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: redoLines.isNotEmpty ? redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: clear,
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas
          Positioned.fill(
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: ClipRect(
                child: CustomPaint(
                  painter: _DrawingPainter(lines: lines),
                  size: Size.infinite,
                  isComplex: true,
                  willChange: true,
                ),
              ),
            ),
          ),
          
          // Toolbar
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brush Size Slider
                      Row(
                        children: [
                          Icon(Icons.brush, size: 20, color: Colors.grey[700]),
                          Expanded(
                            child: Slider(
                              value: strokeWidth,
                              min: 1.0,
                              max: 30.0,
                              activeColor: Colors.blueGrey,
                              onChanged: (val) {
                                setState(() {
                                  strokeWidth = val;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              strokeWidth.toStringAsFixed(1),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Colors
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: colors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final color = colors[index];
                            final isSelected = color == selectedColor;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.grey.shade300,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : [],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;

  _DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill the background white
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.path.isEmpty) continue;

      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(line.path.first.dx, line.path.first.dy);
      
      for (int j = 1; j < line.path.length; j++) {
        path.lineTo(line.path[j].dx, line.path[j].dy);
      }
      
      if (line.path.length == 1) {
        canvas.drawPoints(PointMode.points, [line.path.first], paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    // Simple repainting check
    return true;
  }
}
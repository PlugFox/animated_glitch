import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

late ui.Image _$image;
Future<ui.Image> _loadImage(String assetPath) async {
  ByteData data = await rootBundle.load(assetPath);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  ui.FrameInfo fi = await codec.getNextFrame();

  return fi.image;
}

Future<void> $initImage(String assetPath) async =>
    _$image = await _loadImage(assetPath);

class AnimatedGlitchWithShader extends StatefulWidget {
  const AnimatedGlitchWithShader({
    required this.chance,
    required this.colorChannelSpreadReduce,
    required this.distortionSpreadReduce,
    required this.frequency,
    required this.level,
    required this.showColorChannel,
    required this.showDistortion,
    required this.child,
    required this.glitchAmount,
    super.key,
    // https://stackoverflow.com/questions/38986208/webgl-loop-index-cannot-be-compared-with-non-constant-expression
  }) : assert(glitchAmount <= 10,
            'glitchAmount must be less than or equal to 10');

  final double distortionSpreadReduce;
  final double colorChannelSpreadReduce;
  final double level;
  final int glitchAmount;
  final double frequency;
  final int chance;
  final bool showDistortion;
  final bool showColorChannel;
  final Widget child;

  @override
  State<AnimatedGlitchWithShader> createState() =>
      _AnimatedGlitchWithShaderState();
}

class _AnimatedGlitchWithShaderState extends State<AnimatedGlitchWithShader>
    with SingleTickerProviderStateMixin {
  static final Future<ui.FragmentShader> _shaderFuture = () async {
    const shader = 'packages/animated_glitch/shader/glitch.frag';
    final program = await ui.FragmentProgram.fromAsset(shader);

    return program.fragmentShader();
  }();

  late final ValueNotifier<double> _seed = ValueNotifier<double>(0.0);

  late final Ticker _ticker =
      createTicker((elapsed) => _seed.value = elapsed.inMicroseconds / 1000000);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: FutureBuilder<ui.FragmentShader>(
          future: _shaderFuture,
          initialData: null,
          builder: (context, snapshot) => CustomPaint(
            painter: _AnimatedGlitchPainter$Shader(
              seed: _seed,
              shader: snapshot.data,
              distortionSpreadReduce: widget.distortionSpreadReduce,
              colorChannelSpreadReduce: widget.colorChannelSpreadReduce,
              level: widget.level,
              frequency: widget.frequency,
              chance: widget.chance,
              showDistortion: widget.showDistortion,
              showColorChannel: widget.showColorChannel,
              glitchAmount: widget.glitchAmount,
              image: _$image,
            ),
            child: widget.child,
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _AnimatedGlitchPainter$Shader extends CustomPainter {
  _AnimatedGlitchPainter$Shader({
    required this.seed,
    required this.shader,
    required this.distortionSpreadReduce,
    required this.colorChannelSpreadReduce,
    required this.level,
    required this.frequency,
    required this.chance,
    required this.showDistortion,
    required this.showColorChannel,
    required this.glitchAmount,
    required this.image,
  }) : super(repaint: seed);

  final ValueListenable<double> seed;
  final ui.FragmentShader? shader;
  final double distortionSpreadReduce;
  final double colorChannelSpreadReduce;
  final double level;
  final double frequency;
  final int chance;
  final bool showDistortion;
  final bool showColorChannel;
  final int glitchAmount;
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    if (shader == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.transparent);
    }
    final paint = Paint()
      ..shader = (shader!
        // uTime
        ..setFloat(0, seed.value)
        // uResolution x
        ..setFloat(1, size.width)
        // uResolution y
        ..setFloat(2, size.height)
        // uDistortionOffsetDivisor
        ..setFloat(3, distortionSpreadReduce)
        // uColorChannelOffsetDivisor
        ..setFloat(4, colorChannelSpreadReduce)
        // uLevel
        ..setFloat(5, level)
        // uFrequency
        ..setFloat(6, frequency)
        // uChance
        ..setFloat(7, chance.toDouble())
        // uShowDistortion
        ..setFloat(8, showDistortion ? 1.0 : 0.0)
        // uShowColorChannel
        ..setFloat(9, showColorChannel ? 1.0 : 0.0)
        // uShiftColorChannelsY
        ..setFloat(10, 0)
        // uShiftColorChannelsY
        ..setFloat(11, 1)
        // uGlitchAmount
        ..setFloat(12, glitchAmount.toDouble())
        // uChannel0
        ..setImageSampler(0, image));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedGlitchPainter$Shader oldDelegate) =>
      oldDelegate.seed.value != seed.value ||
      oldDelegate.shader != shader ||
      oldDelegate.distortionSpreadReduce != distortionSpreadReduce ||
      oldDelegate.colorChannelSpreadReduce != colorChannelSpreadReduce ||
      oldDelegate.level != level ||
      oldDelegate.frequency != frequency ||
      oldDelegate.chance != chance ||
      oldDelegate.showDistortion != showDistortion ||
      oldDelegate.showColorChannel != showColorChannel ||
      oldDelegate.glitchAmount != glitchAmount;
}

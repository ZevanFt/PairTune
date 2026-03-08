import 'package:flutter/material.dart';

class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.base = const Color(0xFFE9E4DB),
    this.highlight = const Color(0xFFF7F2E8),
  });

  final double? width;
  final double height;
  final double radius;
  final Color base;
  final Color highlight;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + value * 2.0, -0.3),
              end: Alignment(1.0 + value * 2.0, 0.3),
              colors: [widget.base, widget.highlight, widget.base],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

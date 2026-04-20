import 'package:flutter/material.dart';

class ExpandableFab extends StatefulWidget {
  final List<Widget> children;
  final double distance;

  const ExpandableFab({
    super.key,
    required this.children,
    required this.distance,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(
        milliseconds: 300,
      ), // Sedikit dilambatkan agar elegan
      vsync: this,
    );

    // Menggunakan kurva easeOutBack untuk efek pantulan (bouncy) yang modern
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Jarak ideal antar tombol untuk jempol adalah sekitar 65 pixel
    final double thumbSpacing = 65.0;

    return SizedBox(
      width: 60,
      // Tinggi kotak menyesuaikan jumlah tombol agar tidak terpotong
      height: 60 + (widget.children.length * thumbSpacing),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          ..._buildExpandingActionButtons(thumbSpacing),
          _buildMainButton(),
        ],
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons(double spacing) {
    final children = <Widget>[];
    final count = widget.children.length;

    for (var i = 0; i < count; i++) {
      children.add(
        _ExpandingActionButton(
          // Tombol disusun lurus ke atas dengan jarak kelipatan spacing
          bottomOffset: spacing * (i + 1),
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildMainButton() {
    return Positioned(
      bottom: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            // Berputar 90 derajat saat ditekan
            angle: _controller.value * 3.14159 / 2,
            child: FloatingActionButton(
              onPressed: _toggle,
              // Transisi warna: dari Navy ke Putih saat terbuka
              backgroundColor: Color.lerp(
                navyColor,
                Colors.white,
                _controller.value,
              ),
              // Transisi ikon: dari Gold ke Merah saat terbuka
              foregroundColor: Color.lerp(
                goldColor,
                Colors.redAccent,
                _controller.value,
              ),
              elevation: _open ? 8 : 4,
              child: Icon(
                _open ? Icons.close_rounded : Icons.menu_open_rounded,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ====================================================================
// WIDGET ANIMASI TOMBOL ANAK
// ====================================================================
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.bottomOffset,
    required this.progress,
    required this.child,
  });

  final double bottomOffset;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        return Positioned(
          // Mengatur posisi gerakan murni dari bawah ke atas vertikal
          bottom: 4.0 + (progress.value * bottomOffset),
          child: Transform.scale(
            scale: progress.value, // Efek membesar (Pop)
            child: Opacity(
              opacity: progress.value.clamp(0.0, 1.0), // Efek pudar transparan
              child: child!,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ====================================================================
// WIDGET DESAIN TOMBOL ANAK (ACTION BUTTON)
// ====================================================================
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.color,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: color,
      elevation: 6, // Bayangan dipertebal sedikit agar pop up lebih tegas
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: Colors.white,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

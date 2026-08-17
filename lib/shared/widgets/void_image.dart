import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:void_app/core/services/local_image_cache_service.dart';

/// Universal, high-performance image widget for VOID.
///
/// Automatically caches remote images to disk and memory for instant offline loading.
class VoidImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  const VoidImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  @override
  State<VoidImage> createState() => _VoidImageState();
}

class _VoidImageState extends State<VoidImage> {
  Uint8List? _cachedBytes;
  Future<Uint8List?>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  @override
  void didUpdateWidget(covariant VoidImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _checkAndLoad();
    }
  }

  void _checkAndLoad() {
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      _cachedBytes = null;
      _loadFuture = null;
      return;
    }

    final mem = LocalImageCacheService.instance.getMemoryCached(url);
    if (mem != null) {
      _cachedBytes = mem;
      _loadFuture = null;
    } else {
      _cachedBytes = null;
      _loadFuture = LocalImageCacheService.instance.loadImageBytes(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget content;

    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      content = widget.errorWidget ?? _buildDefaultFallback(isDark);
    } else if (_cachedBytes != null) {
      content = Image.memory(
        _cachedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            widget.errorWidget ?? _buildDefaultFallback(isDark),
      );
    } else {
      content = FutureBuilder<Uint8List?>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final bytes = snapshot.data;
            if (bytes != null && bytes.isNotEmpty) {
              return AnimatedOpacity(
                duration: widget.fadeInDuration,
                opacity: 1.0,
                child: Image.memory(
                  bytes,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) =>
                      widget.errorWidget ?? _buildDefaultFallback(isDark),
                ),
              );
            } else {
              return widget.errorWidget ?? _buildDefaultFallback(isDark);
            }
          }

          return widget.placeholder ?? _buildDefaultPlaceholder(isDark);
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildDefaultPlaceholder(bool isDark) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: isDark ? const Color(0xFF181D27) : const Color(0xFFE2E8F0),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultFallback(bool isDark) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: isDark ? const Color(0xFF1E232E) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.insert_drive_file_outlined,
          size: (widget.width != null && widget.width! < 40) ? 14 : 22,
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const ShimmerEffect(),
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({super.key});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.transparent,
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: const SlidingGradientTransform(),
            ).createShader(bounds);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
          ),
        );
      },
    );
  }
}

class SlidingGradientTransform extends GradientTransform {
  const SlidingGradientTransform();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      (DateTime.now().millisecondsSinceEpoch % 3000) / 3000 * bounds.width,
      0.0,
      0.0,
    );
  }
}

// Skeleton for Posts Grid
class PostsGridSkeleton extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const PostsGridSkeleton({super.key, this.count = 6, this.crossAxisCount = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: count,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 160, borderRadius: 16),
          const SizedBox(height: 12),
          SkeletonLoader(height: 20, borderRadius: 8),
          const SizedBox(height: 8),
          SkeletonLoader(height: 14, width: 100, borderRadius: 8),
        ],
      ),
    );
  }
}

// Skeleton for Users Grid
class UsersGridSkeleton extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const UsersGridSkeleton({super.key, this.count = 6, this.crossAxisCount = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: count,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(width: 50, height: 50, borderRadius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(height: 16, borderRadius: 8),
                    const SizedBox(height: 8),
                    SkeletonLoader(height: 12, borderRadius: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonLoader(height: 14, borderRadius: 8),
          const SizedBox(height: 8),
          SkeletonLoader(height: 14, borderRadius: 8),
          const SizedBox(height: 12),
          Row(
            children: [
              SkeletonLoader(width: 60, height: 24, borderRadius: 12),
              const SizedBox(width: 8),
              SkeletonLoader(width: 80, height: 24, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

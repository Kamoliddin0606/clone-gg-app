/// ============================================================================
/// Balance Shimmer Widget
/// ============================================================================
/// Balans yuklanayotganda ko'rsatiladigan shimmer effect widgetlari.
/// ============================================================================

import 'package:flutter/material.dart';

/// ============================================================================
/// BalanceCardShimmer - Balans kartasi uchun shimmer
/// ============================================================================
class BalanceCardShimmer extends StatefulWidget {
  const BalanceCardShimmer({super.key});

  @override
  State<BalanceCardShimmer> createState() => _BalanceCardShimmerState();
}

class _BalanceCardShimmerState extends State<BalanceCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              Row(
                children: [
                  _ShimmerBox(width: 20, height: 20, animation: _animation),
                  const SizedBox(width: 8),
                  _ShimmerBox(width: 100, height: 14, animation: _animation),
                  const Spacer(),
                  _ShimmerBox(width: 50, height: 24, animation: _animation, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 16),
              // Date shimmer
              _ShimmerBox(width: 120, height: 11, animation: _animation),
              const SizedBox(height: 12),
              // Status shimmer
              _ShimmerBox(width: 80, height: 13, animation: _animation),
              const SizedBox(height: 8),
              // Amount shimmer
              _ShimmerBox(width: 150, height: 24, animation: _animation),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================================
/// BalanceDetailsShimmer - Balans detallari uchun shimmer
/// ============================================================================
class BalanceDetailsShimmer extends StatefulWidget {
  const BalanceDetailsShimmer({super.key});

  @override
  State<BalanceDetailsShimmer> createState() => _BalanceDetailsShimmerState();
}

class _BalanceDetailsShimmerState extends State<BalanceDetailsShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Column(
            children: [
              // Balance card shimmer
              _buildCardShimmer(),
              const SizedBox(height: 24),
              // Chart shimmer
              _buildChartShimmer(),
              const SizedBox(height: 24),
              // Stats shimmer
              _buildStatsShimmer(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardShimmer() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Icon shimmer
            _ShimmerBox(width: 64, height: 64, animation: _animation, borderRadius: 32),
            const SizedBox(height: 16),
            // Status text shimmer
            _ShimmerBox(width: 120, height: 16, animation: _animation),
            const SizedBox(height: 8),
            // Amount shimmer
            _ShimmerBox(width: 180, height: 28, animation: _animation),
            const SizedBox(height: 16),
            // Date shimmer
            _ShimmerBox(width: 150, height: 12, animation: _animation),
          ],
        ),
      ),
    );
  }

  Widget _buildChartShimmer() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 150, height: 14, animation: _animation),
            const SizedBox(height: 16),
            // Pie chart placeholder
            Center(
              child: _ShimmerBox(width: 150, height: 150, animation: _animation, borderRadius: 75),
            ),
            const SizedBox(height: 16),
            // Progress bar shimmer
            _ShimmerBox(width: double.infinity, height: 20, animation: _animation, borderRadius: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 100, height: 14, animation: _animation),
            const SizedBox(height: 16),
            // Stats rows
            for (int i = 0; i < 4; i++) ...[
              Row(
                children: [
                  _ShimmerBox(width: 20, height: 20, animation: _animation),
                  const SizedBox(width: 12),
                  _ShimmerBox(width: 100, height: 14, animation: _animation),
                  const Spacer(),
                  _ShimmerBox(width: 60, height: 14, animation: _animation),
                ],
              ),
              if (i < 3) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// ContractListShimmer - Shartnomalar ro'yxati uchun shimmer
/// ============================================================================
class ContractListShimmer extends StatefulWidget {
  final int itemCount;

  const ContractListShimmer({super.key, this.itemCount = 3});

  @override
  State<ContractListShimmer> createState() => _ContractListShimmerState();
}

class _ContractListShimmerState extends State<ContractListShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ShimmerBox(width: 32, height: 32, animation: _animation, borderRadius: 8),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ShimmerBox(width: 120, height: 14, animation: _animation),
                              const SizedBox(height: 4),
                              _ShimmerBox(width: 80, height: 12, animation: _animation),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ShimmerBox(width: 60, height: 12, animation: _animation),
                              const SizedBox(height: 4),
                              _ShimmerBox(width: 100, height: 14, animation: _animation),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ShimmerBox(width: 60, height: 12, animation: _animation),
                              const SizedBox(height: 4),
                              _ShimmerBox(width: 100, height: 14, animation: _animation),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ============================================================================
/// _ShimmerBox - Shimmer effect bilan box
/// ============================================================================
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final Animation<double> animation;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.animation,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(animation.value - 1, 0),
          end: Alignment(animation.value + 1, 0),
          colors: isDark
              ? [
                  cs.surfaceContainerHighest,
                  cs.surfaceContainerHighest.withOpacity(0.5),
                  cs.surfaceContainerHighest,
                ]
              : [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
        ),
      ),
    );
  }
}

// lib/features/posts/presentation/pages/posts_management_page.dart
import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/core/utils/responsive_helper.dart';
import 'package:admin_dashboard/features/posts/data/models/post_model.dart';
import 'package:admin_dashboard/features/posts/presentation/state/posts_controller.dart';
import 'package:admin_dashboard/features/posts/presentation/widgets/confirm_dialog.dart';
import 'package:admin_dashboard/features/posts/presentation/widgets/post_card_skeleton.dart';
import 'package:admin_dashboard/features/posts/presentation/widgets/post_editor_shell.dart';
import 'package:admin_dashboard/features/posts/presentation/widgets/posts_card.dart';
import 'package:admin_dashboard/features/posts/presentation/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostsManagementPage extends StatelessWidget {
  const PostsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PostsController(),
      child: const _PostsPageContent(),
    );
  }
}

class _PostsPageContent extends StatefulWidget {
  const _PostsPageContent();

  @override
  State<_PostsPageContent> createState() => _PostsPageContentState();
}

class _PostsPageContentState extends State<_PostsPageContent>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterStatus = 'all';
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _updateFilterStatus(String status) {
    setState(() {
      _filterStatus = status;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _filterStatus = 'all';
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    _showMessages();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header - بدون Expanded
          const _HeaderSection(),
          const _StatsSection(),
          _SearchAndFiltersSection(
            onSearchChanged: _updateSearchQuery,
            onFilterChanged: _updateFilterStatus,
            currentFilter: _filterStatus,
          ),
          // المحتوى الرئيسي - يأخذ المساحة المتبقية
          Expanded(
            child: Consumer<PostsController>(
              builder: (context, controller, _) {
                if (controller.isLoading && controller.posts.isEmpty) {
                  return const _SkeletonGrid();
                }
                return Stack(
                  children: [
                    _PostsGrid(
                      scrollController: _scrollController,
                      controller: controller,
                      searchQuery: _searchQuery,
                      filterStatus: _filterStatus,
                      onClearFilters: _clearAllFilters,
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _buildScrollToTopButton(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToTopButton() {
    return AnimatedOpacity(
      opacity: _scrollController.hasClients && _scrollController.offset > 300
          ? 1.0
          : 0.0,
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.small(
        onPressed: _scrollToTop,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ),
    );
  }

  void _showMessages() {
    final controller = context.read<PostsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(controller.successMessage!)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        controller.clearMessages();
      }
      if (controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(controller.error!)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        controller.clearMessages();
      }
    });
  }
}

// ==================== Header Section ====================

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  Future<void> _showPostForm(
      BuildContext context, PostsController controller, Post? post) async {
    if (controller.isActionInProgress) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostEditorShell(postId: post?.id),
      ),
    );

    if (result == true) {
      await controller.loadPosts(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final double horizontalPadding = isSmallScreen ? 16 : 24;
    final double verticalPadding = isSmallScreen ? 12 : 16;

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة إدارة المنشورات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButtons(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<PostsController>(
      builder: (context, controller, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRefreshButton(controller),
            const SizedBox(width: 12),
            _buildNewPostButton(context, controller),
          ],
        );
      },
    );
  }

  Widget _buildRefreshButton(PostsController controller) {
    return Tooltip(
      message: 'تحديث المنشورات',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isLoading
              ? null
              : () => controller.loadPosts(forceRefresh: true),
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.accent.withOpacity(0.1),
          highlightColor: AppColors.accent.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedRotation(
                  turns: controller.isLoading ? 0.5 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Icon(
                    Icons.refresh,
                    color: controller.isLoading
                        ? Colors.grey.shade400
                        : AppColors.accent,
                    size: 20,
                  ),
                ),
                if (controller.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPostButton(BuildContext context, PostsController controller) {
    return Tooltip(
      message: 'منشور جديد',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          onPressed: controller.isActionInProgress
              ? null
              : () => _showPostForm(context, controller, null),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: controller.isActionInProgress
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add, size: 18, key: ValueKey('icon')),
          ),
          label: const Text(
            'جديد',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            overlayColor: Colors.white.withOpacity(0.1),
            disabledBackgroundColor: AppColors.accent.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

// ==================== Stats Section ====================

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<PostsController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.posts.isEmpty) {
          return const _StatsSkeleton();
        }

        final total = controller.posts.length;
        final published = controller.posts
            .where((p) => p.status == PostStatus.published)
            .length;
        final scheduled = controller.posts
            .where((p) => p.status == PostStatus.scheduled)
            .length;
        final drafts =
            controller.posts.where((p) => p.status == PostStatus.draft).length;
        final totalViews =
            controller.posts.fold<int>(0, (sum, p) => sum + p.viewCount);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 800;

              if (isSmallScreen) {
                return Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatCard(
                            'الكل', total, Icons.article_outlined, Colors.blue),
                        _buildStatCard('منشور', published, Icons.public,
                            AppColors.success),
                        _buildStatCard(
                            'مجدول', scheduled, Icons.schedule, AppColors.info),
                        _buildStatCard('مسودة', drafts, Icons.edit_note,
                            AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTotalViewsCard(totalViews),
                  ],
                );
              } else {
                return Row(
                  children: [
                    _buildStatCard(
                        'الكل', total, Icons.article_outlined, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'منشور', published, Icons.public, AppColors.success),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'مجدول', scheduled, Icons.schedule, AppColors.info),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'مسودة', drafts, Icons.edit_note, AppColors.warning),
                    const Spacer(),
                    _buildTotalViewsCard(totalViews),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatNumber(count),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalViewsCard(int totalViews) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'إجمالي المشاهدات: ${_formatNumber(totalViews)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num < 0) return '0';
    final formatter = NumberFormat('#,###', 'ar');

    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}م';
    }
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}ألف';
    }
    return formatter.format(num);
  }
}

// ==================== Stats Skeleton ====================

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: isSmallScreen
          ? Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(4, (index) => _buildSkeletonCard()),
                ),
                const SizedBox(height: 12),
                _buildSkeletonTotalCard(),
              ],
            )
          : Row(
              children: [
                ...List.generate(
                    4, (index) => Expanded(child: _buildSkeletonCard())),
                const SizedBox(width: 12),
                _buildSkeletonTotalCard(),
              ],
            ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 11,
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 2),
              Container(
                width: 30,
                height: 16,
                color: Colors.grey.shade200,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonTotalCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            color: Colors.grey.shade200,
          ),
          const SizedBox(width: 8),
          Container(
            width: 120,
            height: 13,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}

// ==================== Search and Filters Section ====================

class _SearchAndFiltersSection extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final String currentFilter;

  const _SearchAndFiltersSection({
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          CustomSearchBar(onSearchChanged: onSearchChanged),
          const SizedBox(height: 16),
          _buildFilterTabs(),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final Map<String, Map<String, dynamic>> filters = {
      'all': {'label': 'الكل', 'icon': Icons.grid_view_outlined},
      'published': {'label': 'منشور', 'icon': Icons.public_outlined},
      'scheduled': {'label': 'مجدول', 'icon': Icons.schedule_outlined},
      'draft': {'label': 'مسودة', 'icon': Icons.edit_note_outlined},
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.entries.map((entry) {
          final isSelected = currentFilter == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry.value['icon'],
                      size: 16,
                      color:
                          isSelected ? AppColors.accent : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.value['label'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.accent
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==================== Posts Grid with Pagination ====================

class _PostsGrid extends StatelessWidget {
  final ScrollController scrollController;
  final PostsController controller;
  final String searchQuery;
  final String filterStatus;
  final VoidCallback onClearFilters;

  const _PostsGrid({
    required this.scrollController,
    required this.controller,
    required this.searchQuery,
    required this.filterStatus,
    required this.onClearFilters,
  });

  List<Post> _getFilteredPosts() {
    return controller.posts.where((post) {
      final matchesSearch = searchQuery.isEmpty ||
          post.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          post.content.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter =
          filterStatus == 'all' || post.status.name == filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _getFilteredPosts();
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);

    // عرض حالة التحميل الأولي
    if (controller.isLoading && filteredPosts.isEmpty) {
      return const _SkeletonGrid();
    }

    // عرض حالة عدم وجود بيانات
    if (filteredPosts.isEmpty) {
      return _buildEmptyState(context);
    }

    // عرض الشبكة مع دعم السحب للتحديث والتحميل التدريجي
    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadPosts(forceRefresh: true);
      },
      color: AppColors.accent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // التحميل التلقائي عند الوصول للنهاية
          if (!controller.isLoadingMore &&
              controller.hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMorePosts();
          }
          return false;
        },
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio:
                      ResponsiveHelper.getCardAspectRatio(context),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < filteredPosts.length) {
                      return _PostCardWrapper(
                        post: filteredPosts[index],
                        controller: controller,
                      );
                    }
                    return null;
                  },
                  childCount: filteredPosts.length,
                ),
              ),
            ),
            // مؤشر تحميل المزيد
            if (controller.hasMore)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasFilters = searchQuery.isNotEmpty || filterStatus != 'all';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: hasFilters ? 100 : 120,
              height: hasFilters ? 100 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade50,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                hasFilters ? Icons.search_off_outlined : Icons.article_outlined,
                size: hasFilters ? 50 : 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              hasFilters ? 'لا توجد نتائج مطابقة' : 'لا يوجد منشورات حالياً',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'حاول تعديل كلمات البحث أو إزالة الفلاتر'
                  : 'ابدأ بإضافة أول منشور لك الآن',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('مسح جميع الفلاتر'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showPostForm(context, null),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('إنشاء منشور جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostForm(BuildContext context, Post? post) async {
    if (controller.isActionInProgress) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostEditorShell(postId: post?.id),
      ),
    );
    if (result == true) {
      await controller.loadPosts(forceRefresh: true);
    }
  }
}

// ==================== Post Card Wrapper ====================

class _PostCardWrapper extends StatelessWidget {
  final Post post;
  final PostsController controller;

  const _PostCardWrapper({
    required this.post,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      onEdit: () => _showPostForm(context, post),
      onDelete: () => _deletePost(context, post),
      onDeleteAudio: () => _deleteAudioOnly(context, post),
      onReschedule: () => _showRescheduleDialog(context, post),
    );
  }

  Future<void> _showPostForm(BuildContext context, Post post) async {
    if (controller.isActionInProgress) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostEditorShell(postId: post.id),
      ),
    );
    if (result == true) {
      await controller.loadPosts(forceRefresh: true);
    }
  }

  Future<void> _showRescheduleDialog(BuildContext context, Post post) async {
    DateTime newDate =
        post.scheduledFor ?? DateTime.now().add(const Duration(days: 1));
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _RescheduleDialog(
        initialDate: newDate,
        onConfirm: (date) async {
          await controller.schedulePost(post.id, date);
        },
      ),
    );
  }

  Future<void> _deleteAudioOnly(BuildContext context, Post post) async {
    if (!post.hasAudio) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('هذه الميزة قيد التطوير حالياً'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'تأكيد الحذف',
        message: 'هل أنت متأكد من حذف هذا المنشور؟',
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed == true) {
      await controller.deletePost(post.id);
    }
  }
}

// ==================== Reschedule Dialog ====================

class _RescheduleDialog extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onConfirm;

  const _RescheduleDialog({
    required this.initialDate,
    required this.onConfirm,
  });

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الجدولة'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDatePicker(),
          const SizedBox(height: 12),
          _buildTimePicker(),
          const SizedBox(height: 20),
          _buildPreviewCard(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_selectedDate);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('تأكيد الجدولة'),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.accent),
              ),
              child: child!,
            );
          },
        );
        if (selected != null) {
          setState(() {
            _selectedDate = DateTime(
              selected.year,
              selected.month,
              selected.day,
              _selectedDate.hour,
              _selectedDate.minute,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التاريخ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDate),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.accent),
              ),
              child: child!,
            );
          },
        );
        if (selected != null) {
          setState(() {
            _selectedDate = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              selected.hour,
              selected.minute,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الوقت',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.infoLight,
            AppColors.infoLight.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'موعد النشر الجديد',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} - ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Skeleton Grid ====================

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const PostCardSkeleton(),
    );
  }
}

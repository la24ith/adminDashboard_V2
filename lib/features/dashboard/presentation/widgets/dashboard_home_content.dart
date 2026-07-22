import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/animated_widgets.dart';
import '../../../users/presentation/pages/users_page.dart';
import '../../../users/presentation/widgets/user_form_page.dart';

class DashboardHomeContent extends StatefulWidget {
  final DashboardController controller;

  const DashboardHomeContent({super.key, required this.controller});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (widget.controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              widget.controller.error!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.controller.refreshDashboard(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final data = widget.controller.dashboardData;
    final weeklyActivity = widget.controller.weeklyActivity;

    return RefreshIndicator(
      onRefresh: () => widget.controller.refreshDashboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsGrid(data, isSmallScreen),
            const SizedBox(height: 24),

            // Charts Row with real activity data
            LayoutBuilder(
              builder: (context, constraints) {
                final isRowLayout = constraints.maxWidth > 900;
                if (isRowLayout) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildActivityChart(weeklyActivity)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildEngagementCard(data)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildActivityChart(weeklyActivity),
                      const SizedBox(height: 20),
                      _buildEngagementCard(data),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // ✅ توزيع فئات المستخدمين (user_segments)
            _buildUserSegmentsChart(data),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(data),
            const SizedBox(height: 24),

            // Quick Actions with real functions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accent, AppColors.accentDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مرحباً بعودتك،',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.controller.adminName ?? 'المدير',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'هذا ملخص أداء لوحة التحكم اليوم',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data, bool isSmallScreen) {
    final stats = [
      _StatItem(
        title: 'إجمالي المستخدمين',
        value: _formatNumber(data['total_users']),
        icon: Icons.people_outline,
        color: AppColors.primary,
      ),
      _StatItem(
        title: 'الاشتراكات النشطة',
        value: _formatNumber(data['active_subscriptions']),
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _StatItem(
        title: 'الاشتراكات المنتهية',
        value: _formatNumber(data['expired_subscriptions']),
        icon: Icons.remove_circle_outline,
        color: AppColors.error,
      ),
      _StatItem(
        title: 'منشورات اليوم',
        value: _formatNumber(data['today_posts']),
        icon: Icons.article_outlined,
        color: AppColors.warning,
      ),
      _StatItem(
        title: 'معدل الالتزام',
        value: '${_toNum(data['commitment_rate']).toInt()}%',
        icon: Icons.trending_up,
        color: AppColors.info,
      ),
    ];

    // ✅ توزيع تلقائي لعدد البطاقات في كل صف حسب العرض المتاح،
    // بدل الاعتماد على فهارس ثابتة (يدعم إضافة/حذف بطاقات مستقبلاً دون كسر التخطيط)
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ حماية: أحياناً يعطي الأب عرضاً صفرياً أو سالباً مؤقتاً أثناء أول رسم
        // للواجهة أو أثناء تغيير حجم النافذة/طي السايدبار — قبل أن يستقر التخطيط
        if (!constraints.maxWidth.isFinite || constraints.maxWidth <= 0) {
          return const SizedBox.shrink();
        }

        const spacing = 12.0;
        const minCardWidth = 150.0;
        int perRow = (constraints.maxWidth / (minCardWidth + spacing)).floor();
        perRow = perRow.clamp(2, stats.length);
        final rawItemWidth =
            (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        // ✅ لا نسمح أبداً بعرض سالب (كان هذا سبب انهيار BoxConstraints)
        final itemWidth = rawItemWidth.clamp(0.0, constraints.maxWidth);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats
              .map((s) => SizedBox(width: itemWidth, child: _StatCard(item: s)))
              .toList(),
        );
      },
    );
  }

  // ✅ النشاط الأسبوعي مع بيانات حقيقية من API
  Widget _buildActivityChart(List<Map<String, dynamic>> weeklyData) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 النشاط الأسبوعي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weeklyData.map((item) {
                  final percentage = _toNum(item['count']).toDouble();
                  final day = (item['day'] ?? '').toString();
                  return _buildBarChartItem(
                      day, percentage.clamp(0.0, 100.0).toDouble());
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartItem(String day, double percentage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: percentage,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(day,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildEngagementCard(Map<String, dynamic> data) {
    final commitmentRate = _toNum(data['commitment_rate']).toDouble();
    final engagementRate = commitmentRate / 100;

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎯 نسبة الالتزام',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: engagementRate.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: AppColors.surfaceVariant,
                      color: AppColors.success,
                    ),
                  ),
                  Column(
                    children: [
                      Text('${commitmentRate.toInt()}%',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('التزام',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEngagementStat('إجمالي المستخدمين',
                    _formatNumber(data['total_users'] ?? 0)),
                _buildEngagementStat(
                    'منشورات اليوم', _formatNumber(data['today_posts'] ?? 0)),
                _buildEngagementStat('اشتراكات نشطة',
                    _formatNumber(data['active_subscriptions'] ?? 0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  // ✅ رسم بياني دائري لتوزيع فئات المستخدمين (user_segments)
  Widget _buildUserSegmentsChart(Map<String, dynamic> data) {
    final rawSegments = data['user_segments'];

    // لا نعرض الكرت إطلاقاً إذا لم يرسل الباك اند هذا الحقل بعد
    if (rawSegments == null || rawSegments is! Map || rawSegments.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = rawSegments.entries.toList();
    final total = entries.fold<num>(0, (sum, e) => sum + _toNum(e.value));

    return FadeInUp(
      duration: const Duration(milliseconds: 550),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('👥 توزيع فئات المستخدمين',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isRowLayout = constraints.maxWidth > 500;

                final chart = SizedBox(
                  width: 180,
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(entries.length, (i) {
                        final value = _toNum(entries[i].value).toDouble();
                        final color =
                            _getSegmentColor(entries[i].key.toString(), i);
                        final percent = total > 0 ? (value / total * 100) : 0.0;
                        return PieChartSectionData(
                          value: value,
                          color: color,
                          radius: 45,
                          title: '${percent.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                );

                final legend = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(entries.length, (i) {
                    final color =
                        _getSegmentColor(entries[i].key.toString(), i);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatSegmentLabel(entries[i].key.toString()),
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatNumber(entries[i].value),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    );
                  }),
                );

                if (isRowLayout) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      chart,
                      const SizedBox(width: 24),
                      Expanded(child: legend),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Center(child: chart),
                      const SizedBox(height: 16),
                      legend,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ التطبيق مخصص للإناث فقط، لذا كل فئات الدائرة تُلوَّن بدرجات من اللون الزهري (pink)
  Color _getSegmentColor(String key, int index) {
    final pinkShades = [
      const Color(0xFFEC4899), // pink 500
      const Color(0xFFF472B6), // pink 400
      const Color(0xFFDB2777), // pink 600
      const Color(0xFFF9A8D4), // pink 300
      const Color(0xFFBE185D), // pink 700
      const Color(0xFFFBCFE8), // pink 200
    ];
    return pinkShades[index % pinkShades.length];
  }

  /// ✅ ترجمة أسماء فئات المستخدمين الشائعة إلى العربية
  /// (fallback لعرض المفتاح كما هو لو لم يكن معروفاً)
  /// (fallback لعرض المفتاح كما هو لو لم يكن معروفاً)
  String _formatSegmentLabel(String key) {
    const labels = {
      'new': 'مستخدمون جدد',
      'active': 'نشطون',
      'inactive': 'غير نشطين',
      'premium': 'مميزون',
      'free': 'مجانيون',
      'churned': 'منسحبون',
      'general': 'عام',
      'diabetic': 'سكري',
      'breastfeeding': 'مرضعات',
      'weight_loss': 'فقدان وزن',
      'weight_gain': 'زيادة وزن',
    };
    return labels[key.toLowerCase()] ?? key;
  }

  Widget _buildRecentActivity(Map<String, dynamic> data) {
    final activities = data['recent_activities'] ?? [];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🕐 آخر النشاطات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('لا توجد نشاطات حديثة')),
              )
            else
              ...activities.map((activity) => Column(
                    children: [
                      _buildActivityItem(
                        icon: _getActivityIcon(activity['type']),
                        text: activity['message'] ?? '',
                        time: activity['time'] ?? '',
                        color: _getActivityColor(activity['type']),
                      ),
                      const Divider(),
                    ],
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String text,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ أزرار الإجراءات السريعة مع دوال حقيقية
  Widget _buildQuickActions(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡ إجراءات سريعة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionButton(
                  icon: Icons.person_add,
                  label: 'إضافة مستخدم',
                  color: AppColors.primary,
                  onPressed: () => _showAddUserDialog(context),
                ),
                _buildQuickActionButton(
                  icon: Icons.add_comment,
                  label: 'إضافة منشور',
                  color: AppColors.success,
                  onPressed: () => _navigateToPosts(context),
                ),
                _buildQuickActionButton(
                  icon: Icons.notifications_active,
                  label: 'إرسال إشعار',
                  color: AppColors.warning,
                  onPressed: () => _navigateToNotifications(context),
                ),
                _buildQuickActionButton(
                  icon: Icons.ads_click,
                  label: 'إضافة إعلان',
                  color: AppColors.info,
                  onPressed: () => _navigateToAds(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // ✅ دوال الإجراءات السريعة
  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserFormPage(
        user: null,
        onSave: (userData) async {
          // سيتم ربطه مع UsersController لاحقاً
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('سيتم إضافة المستخدم قريباً'),
                backgroundColor: AppColors.success),
          );
        },
      ),
    );
  }

  void _navigateToPosts(BuildContext context) {
    widget.controller.navigateToPage(AdminPage.posts);
  }

  void _navigateToNotifications(BuildContext context) {
    widget.controller.navigateToPage(AdminPage.notifications);
  }

  void _navigateToAds(BuildContext context) {
    widget.controller.navigateToPage(AdminPage.ads);
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'user':
        return Icons.person_add;
      case 'post':
        return Icons.article;
      case 'notification':
        return Icons.notifications;
      case 'ad':
        return Icons.ads_click;
      default:
        return Icons.circle_notifications;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'user':
        return AppColors.success;
      case 'post':
        return AppColors.info;
      case 'notification':
        return AppColors.warning;
      case 'ad':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  String _formatNumber(dynamic number) {
    final n = _toNum(number);
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toInt().toString();
  }

  /// ✅ تحويل آمن لأي قيمة قادمة من الـ API (num أو String أو null)
  /// يمنع انهيار الواجهة إذا أرجع الخادم الأرقام كنصوص (String)
  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // ✅ استخراج الجزء الرقمي فقط من القيمة (تتجاهل %, K, M وأي رموز أخرى)
    final numericMatch = RegExp(r'[\d.]+').firstMatch(item.value);
    final targetValue = double.tryParse(numericMatch?.group(0) ?? '') ?? 0;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: targetValue),
      duration: const Duration(seconds: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double val, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(item.icon, size: 18, color: item.color),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${val.toInt()}${item.value.replaceAll(RegExp(r'[\d.]'), '')}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(item.title,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

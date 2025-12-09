import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings/app_strings.dart';
import 'settings/app_theme.dart';
import 'settings/change_password_page.dart';
import 'main.dart'; // for CleaningApp.of(context)
import 'profile_edit_page.dart';
import 'my_orders_page.dart';
import 'reservation_page.dart';
import 'admin_pages/admin_dashboard_page.dart';
import 'splash_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Color _colorFromName(String name) {
    switch (name) {
      case 'green':
        return AppColors.green;
      case 'blue':
        return AppColors.blue;
      case 'orange':
      default:
        return AppColors.orange;
    }
  }

  IconData _iconFromType(String type) {
    switch (type) {
      case 'sofa':
        return Icons.chair_alt_outlined;
      case 'carpet':
        return Icons.grid_view_rounded;
      case 'car':
        return Icons.directions_car_filled_outlined;
      case 'curtains':
        return Icons.window_rounded;
      default:
        return Icons.cleaning_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesStream = FirebaseFirestore.instance
        .collection('services')
        .where('active', isEqualTo: true)
        .snapshots();

    final appState = CleaningApp.of(context);
    final s = S.of(context);
    final isArabic = s.isArabic;

    return Scaffold(
      // ---------- APP BAR ----------
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 72,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 42,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              S.appNameText(context),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
      drawer: const HomeDrawer(),

      // ---------- BODY ----------
      // Use SingleChildScrollView so header + news + services all scroll together.
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------- Header (with animation) ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orange,
                    AppColors.green,
                    AppColors.blue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    S.welcomeTitleText(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.welcomeSubtitleText(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const CleaningHeaderAnimation(),
                  const SizedBox(height: 6),
                  Text(
                    s.homeTapServiceHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ---------- Latest news title ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.latestNewsText(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const NewsCarousel(),
            const SizedBox(height: 8),

            // ---------- Services grid (non-scrollable, inside main scroll) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: StreamBuilder<QuerySnapshot>(
                stream: servicesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        s.errorLoadingServices(snapshot.error.toString()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(s.noServicesAvailable),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  final services = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? 'Service') as String;
                    final subtitle = (data['subtitle'] ?? '') as String;
                    final priceHint = (data['priceHint'] ?? '') as String;
                    final colorName = (data['color'] ?? 'orange') as String;
                    final iconType = (data['icon'] ?? 'sofa') as String;
                    final topService = (data['top'] ?? true) as bool;
                    final imageBase64 = (data['imageBase64'] ?? '') as String;

                    return CleaningService(
                      id: doc.id,
                      title: title,
                      subtitle: subtitle,
                      priceHint: priceHint,
                      icon: _iconFromType(iconType),
                      color: _colorFromName(colorName),
                      isTop: topService,
                      imageBase64: imageBase64,
                    );
                  }).toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 4 / 3,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return ServiceCard(service: service);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
const _facebookPageUrl =
    'https://www.facebook.com/share/1AHaiwAnS9/?mibextid=wwXIfr';

Future<void> _openFacebookPage() async {
  final uri = Uri.parse(_facebookPageUrl);

  // open in external app (Facebook / browser)
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}
// ==========================================================
// Drawer
// ==========================================================

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  // 🔹 Open Facebook page – works on web & mobile
  Future<void> _openFacebookPage(BuildContext context) async {
    const url = 'https://www.facebook.com/share/1AHaiwAnS9/?mibextid=wwXIfr';
    final uri = Uri.parse(url);

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank', // new tab on web
      );

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Facebook page.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Facebook: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser!;
    final userDocStream =
    FirebaseFirestore.instance.collection('users').doc(authUser.uid).snapshots();

    final appState = CleaningApp.of(context);
    final currentLocale = appState.locale;
    final isArabic = currentLocale.languageCode == 'ar';
    final isDark = appState.themeMode == ThemeMode.dark;

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: userDocStream,
        builder: (context, snapshot) {
          String name = authUser.email?.split('@').first ?? 'User';
          String role = 'user';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = (data['name'] ?? name) as String;
            role = (data['role'] ?? 'user') as String;
          }

          return Column(
            children: [
              // ================= HEADER =================
              UserAccountsDrawerHeader(
                accountName: Text(name),
                accountEmail: Text(authUser.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.orange,
                    ),
                  ),
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orange,
                      AppColors.green,
                      AppColors.blue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Use Expanded + ListView so we can pin Facebook at bottom
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ---------- Profile ----------
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        isArabic ? 'البيانات الشخصية' : 'Personal details',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditPage(),
                          ),
                        );
                      },
                    ),

                    // ---------- My orders ----------
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        isArabic ? 'طلباتي' : 'My orders',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyOrdersPage(),
                          ),
                        );
                      },
                    ),

                    // ---------- Admin panel ----------
                    if (role == 'admin') ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: Text(
                          isArabic ? 'لوحة التحكم' : 'Admin panel',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardPage(),
                            ),
                          );
                        },
                      ),
                    ],

                    const Divider(),

                    // ---------- Language ----------
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(isArabic ? 'اللغة' : 'Language'),
                      subtitle: Text(isArabic ? 'العربية' : 'English'),
                      trailing: Switch(
                        value: isArabic,
                        onChanged: (_) {
                          // toggle & rebuild whole app (drawer will refresh)
                          appState.toggleLocale();
                        },
                      ),
                    ),

                    // ---------- Dark mode ----------
                    ListTile(
                      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                      title: Text(isArabic ? 'الوضع الداكن' : 'Dark mode'),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) {
                          appState.toggleTheme();
                        },
                      ),
                    ),

                    const Divider(),

                    // ---------- Change password ----------
                    ListTile(
                      leading: const Icon(Icons.lock_reset_outlined),
                      title: Text(
                        isArabic ? 'تغيير كلمة المرور' : 'Change password',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // ---------- Logout ----------
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(
                        isArabic ? 'تسجيل الخروج' : 'Logout',
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const SplashPage(),
                            ),
                                (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ================= BOTTOM FACEBOOK BUTTON =================
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.facebook,
                    color: Color(0xFF1877F2),
                  ),
                  title: Text(
                    isArabic ? 'صفحتنا على فيسبوك' : 'Our Facebook page',
                  ),
                  onTap: () => _openFacebookPage(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


// ==========================================================
// Header cleaning animation
// ==========================================================

class CleaningHeaderAnimation extends StatefulWidget {
  const CleaningHeaderAnimation({super.key});

  @override
  State<CleaningHeaderAnimation> createState() =>
      _CleaningHeaderAnimationState();
}

class _CleaningHeaderAnimationState extends State<CleaningHeaderAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: false);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final broomX = width * (0.1 + 0.6 * _anim.value);
              final binX = width * 0.8;

              return Stack(
                children: [
                  for (int i = 0; i < 4; i++)
                    Positioned(
                      bottom: 6 + i.toDouble() * 4,
                      left: width * 0.12 +
                          (binX - width * 0.12) *
                              (_anim.value * (i + 1) / 4),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: Colors.white.withOpacity(0.55 - i * 0.1),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: broomX,
                    child: Transform.rotate(
                      angle: -0.1 + 0.05 * (_anim.value - 0.5),
                      child: const Icon(
                        Icons.cleaning_services_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: binX,
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white70,
                      size: 26,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================================
// News carousel, model, and service card
// ==========================================================

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _currentPage = 0;

  void _startAutoScroll(int itemCount) {
    _timer?.cancel();
    if (itemCount <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % itemCount;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsStream = FirebaseFirestore.instance
        .collection('news')
        .where('active', isEqualTo: true)
        .limit(3)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: newsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading news: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        _startAutoScroll(docs.length);

        return SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = (data['title'] ?? '') as String;
              final body = (data['body'] ?? '') as String;
              final imageBase64 = (data['imageBase64'] ?? '') as String;

              Uint8List? bytes;
              if (imageBase64.isNotEmpty) {
                try {
                  bytes = Uint8List.fromList(base64Decode(imageBase64));
                } catch (_) {
                  bytes = null;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: bytes != null
                                ? Image.memory(
                              bytes,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              color:
                              AppColors.orange.withOpacity(0.1),
                              child: const Center(
                                child: Icon(
                                  Icons.campaign_outlined,
                                  color: AppColors.orange,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class CleaningService {
  final String id;
  final String title;
  final String subtitle;
  final String priceHint;
  final IconData icon;
  final Color color;
  final bool isTop;
  final String imageBase64;

  CleaningService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceHint,
    required this.icon,
    required this.color,
    this.isTop = true,
    this.imageBase64 = '',
  });
}

class ServiceCard extends StatelessWidget {
  final CleaningService service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    Uint8List? imageBytes;
    if (service.imageBase64.isNotEmpty) {
      try {
        imageBytes = Uint8List.fromList(base64Decode(service.imageBase64));
      } catch (_) {
        imageBytes = null;
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReservationPage(
              serviceId: service.id,
              serviceName: service.title,
            ),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 4,
          child: Stack(
            children: [
              Positioned.fill(
                child: imageBytes != null
                    ? Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                )
                    : Container(
                  color: service.color.withOpacity(0.08),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                          Colors.white.withOpacity(0.18),
                          child: Icon(
                            service.icon,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (service.isTop)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.topServiceLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          service.priceHint,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                            Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReservationPage(
                                  serviceId: service.id,
                                  serviceName: service.title,
                                ),
                              ),
                            );
                          },
                          child: Text(s.detailsButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

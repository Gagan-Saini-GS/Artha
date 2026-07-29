import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/providers/logout_provider.dart';
import 'package:tracker/providers/user_api_provider.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/widgets/bottom_nav_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String activeId = "logout";

  @override
  Widget build(BuildContext context) {
    final logoutState = ref.watch(logoutProvider);
    final userState = ref.watch(userApiProvider);

    // Show error message if logout fails
    if (logoutState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(logoutState.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(logoutProvider.notifier).clearError();
      });
    }
    return Scaffold(
      backgroundColor: darkGrayColor,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: CustomSliverAppBarDelegate(expandedHeight: 200),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // User Info Section
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/man.png',
                    fit: BoxFit.contain,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${userState.user?.name}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: whiteColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userState.user?.email}',
                  style: TextStyle(fontSize: 16, color: grayColor),
                ),
                const SizedBox(height: 20),

                // Settings Button
                Card(
                  elevation: 2,
                  shadowColor: greenColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: darkGrayColor,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: greenColor,
                      child: logoutState.isLoggingOut
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  whiteColor,
                                ),
                              ),
                            )
                          : Icon(Icons.settings_outlined, color: whiteColor),
                    ),
                    title: Text(
                      "Settings",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: whiteColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: grayColor,
                    ),
                    onTap: () {
                      context.push('/settings');
                    },
                  ),
                ),

                // Profile Menu List
                _buildProfileMenu(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
      floatingActionButton: FloatingActionButton(
        backgroundColor: greenColor,
        onPressed: () {
          context.push('/add-transaction');
        },
        elevation: 4,
        child: Icon(Icons.add, color: whiteColor),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Widget for building the list of profile options
  Widget _buildProfileMenu() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // _buildMenuListItem(id: "theme", icon: Icons.sunny, title: 'Theme'),
          _buildMenuListItem(
            id: "logout",
            icon: Icons.logout_outlined,
            title: 'Logout',
          ),
        ],
      ),
    );
  }

  // Reusable widget for each menu item
  Widget _buildMenuListItem({
    required String id,
    required IconData icon,
    required String title,
  }) {
    final isActive = id == activeId;
    final logoutState = ref.watch(logoutProvider);

    return Card(
      elevation: isActive ? 2 : 1,
      shadowColor: isActive ? greenColor : blackColor,
      // margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isActive ? darkGrayColor : lightGrayColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? greenColor : Colors.transparent,
          child: logoutState.isLoggingOut
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                  ),
                )
              : Icon(icon, color: isActive ? whiteColor : grayColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: whiteColor),
        ),
        trailing: logoutState.isLoggingOut
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(grayColor),
                ),
              )
            : Icon(Icons.arrow_forward_ios, size: 16, color: grayColor),
        onTap: logoutState.isLoggingOut
            ? null
            : () async {
                await ref.read(logoutProvider.notifier).logout(context);
              },
      ),
    );
  }
}

// Custom delegate for the sliver app bar to create the curved effect
class CustomSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;

  const CustomSliverAppBarDelegate({required this.expandedHeight});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // Background with curved shape
        ClipPath(
          clipper: CustomShapeClipper(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: profileGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // AppBar content (Title and Actions)
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Profile',
              style: TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            // actions: [
            //   Container(
            //     margin: const EdgeInsets.only(right: 10),
            //     decoration: BoxDecoration(
            //       color: whiteColor.withAlpha(65),
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //     child: GestureDetector(
            //       onTap: () {
            //         // Handle Download click
            //       },
            //       child: Padding(
            //         padding: const EdgeInsets.all(6),
            //         child: Icon(
            //           Icons.notifications_none,
            //           color: whiteColor,
            //           size: 24,
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 40;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}

// Custom clipper for the curved app bar shape
class CustomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 35,
      size.width,
      size.height - 35,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

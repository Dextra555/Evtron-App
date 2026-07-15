import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../Controller/profile_controller.dart';
import '../../Model/profile_model.dart';
import '../Home/mapui.dart';
import '../Login/Bottom.dart';
import '../Login/login.dart';
import 'CustomerDetailsScreen.dart';
import 'complaint.dart';
import 'editprofile.dart';
import 'favourites.dart';
import 'history.dart';
import 'support.dart';
import '../Scanner/scanner.dart';
import 'myevs.dart';
import '../Payment/paymentpage.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      isDarkMode: isDarkMode,
      onToggle: () {
        setState(() {
          isDarkMode = !isDarkMode;
        });
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _profileController = ProfileController();

  UserProfile? _userProfile;
  bool _isLoading = true;
  int _currentIndex = 3;
  String? _authToken;
  bool _isCustomerDetailsEnabled = false; // Add this variable

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTokenFromPreferences();
    _loadCustomerDetailsStatus(); // Add this
  }

  Future<void> _loadCustomerDetailsStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isCustomerDetailsEnabled = prefs.getBool('customer_details_enabled') ?? false;
      });
    } catch (e) {
      print('Error loading customer details status: $e');
    }
  }

  Future<void> _loadTokenFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      String fullToken = '';
      if (tokenType != null && token != null) {
        fullToken = '$tokenType $token';
      } else if (token != null) {
        fullToken = 'Bearer $token';
      }

      setState(() {
        _authToken = fullToken;
      });

      print('========== TOKEN LOADED IN PROFILE SCREEN ==========');
      print('Token: $_authToken');
      print('====================================================');
    } catch (e) {
      print('Error loading token: $e');
      setState(() {
        _authToken = 'Error loading token';
      });
    }
  }

  // ---------- Navigation ----------
  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const MapScreen();
        break;
      case 1:
        page = const ScannerPage();
        break;
      case 2:
        page = const PaymentScreen();
        break;
      case 3:
        page = ProfileScreen(isDarkMode: widget.isDarkMode, onToggle: widget.onToggle);
        break;
      default:
        page = const MapScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final userProfile = await _profileController.fetchUserProfile();

    if (mounted) {
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });

      if (userProfile != null) {
        _showSuccessMessage('Profile loaded successfully');
      } else {
        _showErrorMessage('Failed to load profile');
        _redirectToLogin();
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _redirectToLogin() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout', style: TextStyle(fontSize: 18)),
          content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
            ),
            TextButton(
              onPressed: () async {
                await _profileController.logout();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditProfile() async {
    if (_userProfile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          name: _userProfile!.name,
          phoneNumber: _userProfile!.phone,
          email: _userProfile!.email,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body: _isLoading
          ? _buildLoadingView()
          : _buildProfileContent(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onScanTap: () => _onTabTapped(1),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 60),
        _buildProfileCard(),
        const SizedBox(height: 28),
        _buildMenuItems(),
        const SizedBox(height: 16),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _userProfile?.name ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _userProfile?.phone ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    if (_userProfile?.email.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _userProfile?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _navigateToEditProfile,
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItemWithStatus(
          icon: Icons.business_center,
          title: 'Customer Details',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerDetailsScreen(),
              ),
            );

            if (result == true) {
              _loadCustomerDetailsStatus();
            }
          },
          isEnabled: _isCustomerDetailsEnabled,
        ),

        _buildMenuItem(
          icon: Icons.electric_car,
          title: "My Ev's",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyVehiclesPage()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.history,
          title: 'History',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChargingHistoryScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.report_problem_outlined,
          title: 'Complaint Raising',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ComplaintCreatePage()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.support_agent,
          title: 'Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'FAQ',
          onTap: _launchFAQ,
        ),
      ],
    );
  }

  Widget _buildMenuItemWithStatus({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
            size: 18,
          ),
        ],
      ),
      onTap: onTap,
      dense: true,
    );
  }

  // Regular menu item (unchanged)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
        size: 18,
      ),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildTokenDisplay() {
    if (_authToken == null || _authToken!.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.key_off, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No token found. Please login again.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Truncate token for display if it's too long
    String displayToken = _authToken!;
    if (displayToken.length > 80) {
      displayToken = '${displayToken.substring(0, 40)}...${displayToken.substring(displayToken.length - 30)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Access Token',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _copyTokenToClipboard();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  displayToken,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
                if (_authToken!.length > 80) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Token is too long. Tap copy to get full token.',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyTokenToClipboard() {
    if (_authToken != null && _authToken!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _authToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      print('Token copied to clipboard');
    }
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        height: 46,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red[400], size: 18),
            const SizedBox(width: 6),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchFAQ() async {
    final Uri uri = Uri.parse('https://evtron.in');
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error: $e');
      }
    }
  }
}
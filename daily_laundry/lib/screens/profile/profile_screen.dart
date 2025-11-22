import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../api/api_service.dart';
import '../../service/google_auth_service.dart';
import '../../widgets/profile_item_card.dart';
import '../address/address_model.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../address/address_list_screen.dart';
import '../address/add_edit_address_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final data = await ApiService.getUserInfo();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to load user info')));
    }
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await GoogleAuthService.googleSignIn.signOut();
      print("🚪 Logging out...");
      await _secureStorage.delete(key: 'jwt_token');
      ApiService.token = null;
      print("🧹 Token cleared from secure storage and memory");

    // / Toast Message
    Fluttertoast.showToast(
    msg: "Logout Successful!",
    backgroundColor: Colors.green,
    textColor: Colors.white,
    gravity: ToastGravity.BOTTOM,
    );

    if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Logout Failed!",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settings = [
      {'icon': Icons.location_on, 'title': 'Manage Addresses'},
      {'icon': Icons.notifications, 'title': 'Notifications'},
      {'icon': Icons.security, 'title': 'Privacy & Security'},
      {'icon': Icons.help_outline, 'title': 'Help & Support'}
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("No user data found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.purple,
                    child: Text(
                      userData!['name']?[0].toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData!['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userData!['email'] ?? 'No Email',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final updatedUser = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProfileScreen(userData: userData!),
                        ),
                      );

                      if (updatedUser != null) {
                        setState(() => userData = updatedUser);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Other Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoRow(Icons.phone, 'Mobile',
                      userData!['mobile'] ?? 'N/A'),
                  const Divider(),
                  _infoRow(Icons.location_city, 'City',
                      userData!['city'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settings.length,
              itemBuilder: (context, index) {
                final item = settings[index];
                return ProfileItemCard(
                  icon: item['icon'],
                  title: item['title'],
                  onTap: () async {
                    if (item['title'] == 'Manage Addresses') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddressListScreen()),
                      );
                      fetchUserInfo(); // refresh after returning
                    } else if (item['title'] == 'Notifications') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Coming soon: Notifications settings')),
                      );
                    } else if (item['title'] == 'Privacy & Security') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Coming soon: Privacy settings')),
                      );
                    } else if (item['title'] == 'Help & Support') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Help & Support section under development')),
                      );
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart'; // Custom AppColors

class CustomSidebarMenu extends StatelessWidget {
  final String userName; // User's name to display in the sidebar

  // Constructor to accept the user's name
  CustomSidebarMenu({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primary, // Custom background color for the sidebar
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // DrawerHeader section for user profile
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.secondary, // Use secondary color for the header
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.account_circle, // Placeholder for the profile image
                    size: 40,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Sidebar menu items
          _buildDrawerItem(context, Icons.dashboard, 'Dashboard', () {
            Navigator.pushReplacementNamed(context, '/dashboard'); // Navigate to Dashboard
          }),
          _buildDrawerItem(context, Icons.account_circle, 'Profile', () {
            Navigator.pushNamed(context, '/profile'); // Navigate to Profile
          }),
          _buildDrawerItem(context, Icons.settings, 'Settings', () {
            Navigator.pushNamed(context, '/settings'); // Navigate to Settings
          }),
          _buildDrawerItem(context, Icons.exit_to_app, 'Log Out', () {
            // Log out functionality
            Navigator.pushReplacementNamed(context, '/login'); // Navigate to Login
          }),
        ],
      ),
    );
  }

  // Helper method to build each drawer item
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white), // Icon for the menu item
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white, // White text color for the menu items
          fontSize: 16,
          fontWeight: FontWeight.bold, // Bold text for better readability
        ),
      ),
      onTap: onTap, // When a menu item is tapped, it navigates
    );
  }
}

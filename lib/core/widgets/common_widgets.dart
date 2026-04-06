import 'package:etribunals/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Custom Text widget for reusability
Widget customText(
  String text, {
  double size = 16,
  FontWeight weight = FontWeight.normal,
  Color color = Colors.black,
  TextAlign align = TextAlign.start,
}) {
  return Text(
    text,
    textAlign: align,
    style: TextStyle(fontSize: size, fontWeight: weight, color: color),
  );
}

/// Custom TextFormField widget for reusable input fields
Widget inputTextField({
  required TextEditingController controller,
  required String label,
  bool isPassword = false,
  TextInputType inputType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: isPassword,
    keyboardType: inputType,
    validator: validator,
    style: const TextStyle(color: Colors.black),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accent),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

/// Custom Elevated Button widget
Widget customButton(String label, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontSize: 16)),
  );
}

/// Custom AppBar widget (Reusable)
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  this.backgroundColor = Colors.blue, // Default color
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      backgroundColor: backgroundColor,
      elevation: 5, // Slight shadow
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      toolbarHeight: 70, // Increased height for a better visual appeal
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70); // Height of the AppBar
}

/// Custom Footer Bar widget (Reusable)
class CustomFooterBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomFooterBar({
    super.key,
    this.selectedIndex = 0,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
  backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
    );
  }
}

/// Custom Dropdown widget
/// 
/// import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String? selectedValue;
  final List<Map<String, String>> items;
  final Function(String?) onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(labelText: label),
      items: items.map((court) {
        return DropdownMenuItem(
          value: court['id'],
          child: Text(court['name']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}


/// Reusable styled text input field
class CustomTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final void Function()? onEditingComplete;

  const CustomTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: AppColors.accent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }
}

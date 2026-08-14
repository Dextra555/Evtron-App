import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {},
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Notification type cards
            _buildNotificationTypeCard(
              icon: Icons.notifications_outlined,
              title: 'Notification',
              isSelected: true,
            ),
            const SizedBox(height: 10),
            _buildNotificationTypeCard(
              icon: Icons.sms_outlined,
              title: 'SMS',
              isSelected: false,
            ),
            const SizedBox(height: 10),
            _buildNotificationTypeCard(
              icon: Icons.email_outlined,
              title: 'Email',
              isSelected: false,
            ),
            const SizedBox(height: 10),
            _buildNotificationTypeCard(
              icon: Icons.push_pin_outlined,
              title: 'Push Notifications',
              isSelected: false,
            ),
            const SizedBox(height: 24),
            // Notify me when section
            const Text(
              'Notify me when',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Toggle items
            _buildToggleItem(
              title: 'The charger becomes available',
              value: true,
              onChanged: (value) {},
            ),
            _buildDivider(),
            _buildToggleItem(
              title: 'The charging session is interrupted',
              value: true,
              onChanged: (value) {},
            ),
            _buildDivider(),
            _buildToggleItem(
              title: 'RFID status is updated',
              value: false,
              onChanged: (value) {},
            ),
            const Spacer(),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeCard({
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
    );
  }
}
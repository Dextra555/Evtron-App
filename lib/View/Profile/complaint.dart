import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../Controller/complaint_controller.dart';
import '../../Theme/colors.dart';

class ComplaintCreatePage extends StatefulWidget {
  const ComplaintCreatePage({super.key});

  @override
  State<ComplaintCreatePage> createState() => _ComplaintCreatePageState();
}

class _ComplaintCreatePageState extends State<ComplaintCreatePage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  String? _selectedComplainOf;
  bool _isUrgent = false;
  bool _anonymous = false;

  final List<ComplaintType> _typeOptions = [
    ComplaintType('Product', Icons.shopping_bag_outlined),
    ComplaintType('Service', Icons.room_service_outlined),
    ComplaintType('Delivery', Icons.local_shipping_outlined),
    ComplaintType('Billing', Icons.receipt_outlined),
    ComplaintType('EV Type Vehicle', Icons.electric_car),
  ];

  final List<ComplaintCategory> _complainOptions = [
    ComplaintCategory('Quality Issue', Icons.star_border),
    ComplaintCategory('Late Delivery', Icons.timer),
    ComplaintCategory('Wrong Item', Icons.change_circle),
    ComplaintCategory('Damaged Product', Icons.broken_image),
    ComplaintCategory('Charging Issue', Icons.ev_station),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
        ),
        title: Text(
          "Raise Complaint",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Field
            Text(
              "Subject",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Brief summary of your issue",
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),


            const SizedBox(height: 16),

            // Description Field
            Text(
              "Description",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              minLines: 3,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Please provide detailed information about your complaint...",
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Submit Complaint",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {

    if (_subjectController.text.isEmpty) {
      _showSnackbar(
        "Please enter a subject",
        isError: true,
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      _showSnackbar(
        "Please enter a description",
        isError: true,
      );
      return;
    }

    final controller =
    Provider.of<ComplaintController>(
      context,
      listen: false,
    );

    final response =
    await controller.submitComplaint(
      subject: _subjectController.text.trim(),
      description:
      _descriptionController.text.trim(),
    );

    if (response != null &&
        response.success) {

      _showSnackbar(
        response.message,
      );

      _subjectController.clear();

      _descriptionController.clear();

    } else {

      _showSnackbar(
        "Failed to submit complaint",
        isError: true,
      );
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class ComplaintType {
  final String name;
  final IconData icon;

  ComplaintType(this.name, this.icon);
}

class ComplaintCategory {
  final String name;
  final IconData icon;

  ComplaintCategory(this.name, this.icon);
}
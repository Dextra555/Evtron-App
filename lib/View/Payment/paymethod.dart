import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import '../../Theme/colors.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onMethodAdded;

  const AddPaymentMethodScreen({
    super.key,
    required this.onMethodAdded,
  });

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  String _selectedType = 'UPI'; // UPI, Card, Wallet

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> newMethod = {};

      if (_selectedType == 'UPI') {
        newMethod = {
          "name": _nameController.text,
          "icon": Icons.account_balance_wallet,
          "number": _upiController.text,
          "type": "upi",
          "color": const Color(0xFF4285F4),
        };
      } else if (_selectedType == 'Card') {
        String maskedNumber = _cardNumberController.text.replaceAll(' ', '');
        maskedNumber = maskedNumber.length > 4
            ? '****${maskedNumber.substring(maskedNumber.length - 4)}'
            : maskedNumber;
        newMethod = {
          "name": _nameController.text,
          "icon": Icons.credit_card,
          "number": "Card • $maskedNumber",
          "type": "card",
          "color": const Color(0xFFE4405F),
        };
      } else {
        newMethod = {
          "name": _nameController.text,
          "icon": Icons.account_balance_wallet,
          "number": "Balance: ₹${_balanceController.text}",
          "type": "wallet",
          "color": const Color(0xFFFF9900),
        };
      }

      widget.onMethodAdded(newMethod);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment method added", style: GoogleFonts.poppins(fontSize: 12)),
          backgroundColor: Appcolor.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: Text(
          "Add Payment Method",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Payment Type Selection
            Text("Payment Type", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(
              children: ['UPI', 'Card', 'Wallet'].map((type) {
                bool isSelected = _selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Appcolor.green : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Name Field (Common for all)
            Text("Method Name", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              validator: (v) => v!.isEmpty ? 'Enter name' : null,
              decoration: InputDecoration(
                hintText: "e.g., Google Pay, HDFC Card",
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Dynamic Fields
            if (_selectedType == 'UPI') ...[
              Text("UPI ID", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextFormField(
                controller: _upiController,
                validator: (v) => v!.isEmpty ? 'Enter UPI ID' : (!v.contains('@') ? 'Invalid UPI ID' : null),
                decoration: InputDecoration(
                  hintText: "username@bankname",
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],

            if (_selectedType == 'Card') ...[
              Text("Card Number", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardNumberController,
                validator: (v) => v!.replaceAll(' ', '').length < 16 ? 'Invalid card number' : null,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                decoration: InputDecoration(
                  hintText: "1234 5678 9012 3456",
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                onChanged: (v) {
                  String formatted = v.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ');
                  if (formatted.endsWith(' ')) formatted = formatted.substring(0, formatted.length - 1);
                  _cardNumberController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Expiry", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _expiryController,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                          decoration: InputDecoration(
                            hintText: "MM/YY",
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                          onChanged: (v) {
                            if (v.length == 2) {
                              _expiryController.text = '$v/';
                              _expiryController.selection = TextSelection.collapsed(offset: _expiryController.text.length);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CVV", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cvvController,
                          validator: (v) => v!.length < 3 ? 'Invalid' : null,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "123",
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            if (_selectedType == 'Wallet') ...[
              Text("Balance (₹)", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextFormField(
                controller: _balanceController,
                validator: (v) => v!.isEmpty ? 'Enter balance' : null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],

            const SizedBox(height: 32),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  "Add Payment Method",
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
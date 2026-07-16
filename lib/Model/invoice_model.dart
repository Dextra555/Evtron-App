import 'dart:convert';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return {};
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

String? _asNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class InvoiceResponse {
  final bool success;
  final InvoiceData data;

  InvoiceResponse({
    required this.success,
    required this.data,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    final dataValue = json['data'];
    Map<String, dynamic> dataJson = {};

    if (dataValue is Map) {
      dataJson = Map<String, dynamic>.from(dataValue);
    } else if (dataValue is String) {
      try {
        final decoded = jsonDecode(dataValue);
        if (decoded is Map) {
          dataJson = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    if (dataJson.isEmpty && json['invoice'] is Map) {
      dataJson = Map<String, dynamic>.from(json['invoice']);
    }

    return InvoiceResponse(
      success: json['success'] ?? false,
      data: InvoiceData.fromJson(dataJson),
    );
  }
}

class InvoiceData {
  final int invoiceId;
  final String invoiceNumber;
  final String invoiceDate;
  final String status;
  final String? tid;
  final UserInfo user;
  final CompanyInfo? company;
  final StationInfo station;
  final String charger;
  final String connector;
  final String vehicle;
  final SessionInfo session;
  final EnergyInfo energy;
  final BillingInfo billing;
  final GstInfo gst;
  final PaymentInfo payment;
  final CostBreakdown costBreakdown;
  final BilledTo billedTo;


  InvoiceData({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.status,
    this.tid,
    required this.user,
    this.company,
    required this.station,
    required this.charger,
    required this.connector,
    required this.vehicle,
    required this.session,
    required this.energy,
    required this.billing,
    required this.gst,
    required this.payment,
    required this.costBreakdown,
    required this.billedTo,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);

    final sessionData = _asMap(data['session']);
    final transactionId = _asNullableString(
      data['tid'] ??
          data['transaction_id'] ??
          data['transactionId'] ??
          sessionData['transaction_id'] ??
          sessionData['transactionId'] ??
          sessionData['tid'],
    );

    return InvoiceData(
      invoiceId: _asInt(data['invoice_id'] ?? data['invoiceId'] ?? data['id']),
      invoiceNumber: _asString(data['invoice_number'] ?? data['invoiceNumber']),
      invoiceDate: _asString(data['invoice_date'] ?? data['invoiceDate']),
      status: _asString(data['status']),
      tid: transactionId,
      user: UserInfo.fromJson(_asMap(data['user'])),
      billedTo: BilledTo.fromJson(_asMap(data['billed_to'])), // Add this
      company: data['company'] != null ? CompanyInfo.fromJson(_asMap(data['company'])) : null,
      station: StationInfo.fromJson(_asMap(data['station'])),
      charger: _asString(data['charger']),
      connector: _asString(data['connector']),
      vehicle: _asString(data['vehicle']), // Changed to String
      session: SessionInfo.fromJson(_asMap(data['session'])),
      energy: EnergyInfo.fromJson(_asMap(data['energy'])),
      billing: BillingInfo.fromJson(_asMap(data['billing'])),
      gst: GstInfo.fromJson(_asMap(data['gst'])),
      payment: PaymentInfo.fromJson(_asMap(data['payment'])),
      costBreakdown: CostBreakdown.fromJson(_asMap(data['cost_breakdown'] ?? data['costBreakdown'])),
    );
  }
}


class UserInfo {
  final String name;
  final String email;
  final String phone;
  final String? businessName;
  final String? address;
  final String? gstin;

  UserInfo({
    required this.name,
    required this.email,
    required this.phone,
    this.businessName,
    this.address,
    this.gstin,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return UserInfo(
      name: _asString(data['name']),
      email: _asString(data['email']),
      phone: _asString(data['phone']),
      businessName: _asNullableString(data['business_name'] ?? data['businessName']),
      address: _asNullableString(data['address']),
      gstin: _asNullableString(data['gstin'] ?? data['user_gstin']),
    );
  }
}

class CompanyInfo {
  final String? name;
  final String? logo;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? email;
  final String? phone;
  final String? website;
  final String? pan;
  final String? cin;
  final String? footer;
  final String? terms;
  final String? jurisdiction;
  final String? computerNote;

  CompanyInfo({
    this.name,
    this.logo,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.email,
    this.phone,
    this.website,
    this.pan,
    this.cin,
    this.footer,
    this.terms,
    this.jurisdiction,
    this.computerNote,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return CompanyInfo(
      name: _asNullableString(data['name']),
      logo: _asNullableString(data['logo']),
      address: _asNullableString(data['address']),
      city: _asNullableString(data['city']),
      state: _asNullableString(data['state']),
      country: _asNullableString(data['country']),
      pincode: _asNullableString(data['pincode']),
      email: _asNullableString(data['email']),
      phone: _asNullableString(data['phone']),
      website: _asNullableString(data['website']),
      pan: _asNullableString(data['pan']),
      cin: _asNullableString(data['cin']),
      footer: _asNullableString(data['footer']),
      terms: _asNullableString(data['terms']),
      jurisdiction: _asNullableString(data['jurisdiction']),
      computerNote: _asNullableString(data['computer_note'] ?? data['computerNote']),
    );
  }
}

class StationInfo {
  final String name;
  final String address;
  final String gstin;

  StationInfo({
    required this.name,
    required this.address,
    required this.gstin,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return StationInfo(
      name: _asString(data['name']),
      address: _asString(data['address']),
      gstin: _asString(data['gstin']),
    );
  }
}

class VehicleInfo {
  final String? manufacturer;
  final String? model;
  final String? registrationNumber;

  VehicleInfo({
    this.manufacturer,
    this.model,
    this.registrationNumber,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return VehicleInfo(
      manufacturer: _asString(data['manufacturer'] ?? data['vehicle_manufacturer']),
      model: _asString(data['model'] ?? data['vehicle_model']),
      registrationNumber: _asString(data['registration_number'] ?? data['registrationNumber']),
    );
  }
}

class SessionInfo {
  final int id;
  final String startTime;
  final String endTime;
  final int durationMinutes;

  SessionInfo({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return SessionInfo(
      id: _asInt(data['id'] ?? data['session_id'] ?? data['sessionId']),
      startTime: _asString(data['start_time'] ?? data['startTime']),
      endTime: _asString(data['end_time'] ?? data['endTime']),
      durationMinutes: _asInt(data['duration_minutes'] ?? data['durationMinutes']),
    );
  }
}

class EnergyInfo {
  final double consumedKwh;
  final double ratePerKwh;

  EnergyInfo({
    required this.consumedKwh,
    required this.ratePerKwh,
  });

  factory EnergyInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return EnergyInfo(
      consumedKwh: _asDouble(data['consumed_kwh'] ?? data['consumedKwh']),
      ratePerKwh: _asDouble(data['rate_per_kwh'] ?? data['ratePerKwh']),
    );
  }
}

class BillingInfo {
  final double subtotal;
  final double taxPercentage;
  final double tax;
  final double total;
  final String currency;

  BillingInfo({
    required this.subtotal,
    required this.taxPercentage,
    required this.tax,
    required this.total,
    required this.currency,
  });

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return BillingInfo(
      subtotal: _asDouble(data['subtotal']),
      taxPercentage: _asDouble(data['tax_percentage'] ?? data['taxPercentage']),
      tax: _asDouble(data['tax']),
      total: _asDouble(data['total']),
      currency: _asString(data['currency'], fallback: 'INR'),
    );
  }
}

class GstInfo {
  final String gstin;
  final String hsnSac;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalGst;

  GstInfo({
    required this.gstin,
    required this.hsnSac,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalGst,
  });

  factory GstInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return GstInfo(
      gstin: _asString(data['gstin']),
      hsnSac: _asString(data['hsn_sac'] ?? data['hsnSac']),
      cgstRate: _asDouble(data['cgst_rate'] ?? data['cgstRate']),
      sgstRate: _asDouble(data['sgst_rate'] ?? data['sgstRate']),
      igstRate: _asDouble(data['igst_rate'] ?? data['igstRate']),
      cgstAmount: _asDouble(data['cgst_amount'] ?? data['cgstAmount']),
      sgstAmount: _asDouble(data['sgst_amount'] ?? data['sgstAmount']),
      igstAmount: _asDouble(data['igst_amount'] ?? data['igstAmount']),
      totalGst: _asDouble(data['total_gst'] ?? data['totalGst']),
    );
  }
}

class PaymentInfo {
  final String method;
  final String? receiptNumber;
  final double walletDebits;

  PaymentInfo({
    required this.method,
    this.receiptNumber,
    required this.walletDebits,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return PaymentInfo(
      method: _asString(data['method']),
      receiptNumber: data['receipt_number'] != null ? _asString(data['receipt_number']) : null,
      walletDebits: _asDouble(data['wallet_debits'] ?? data['walletDebits']),
    );
  }
}

class CostBreakdown {
  final double energyCost;
  final double idleCost;
  final double serviceFee;
  final double parkingFee;
  final double subtotal;
  final double tax;
  final double total;

  CostBreakdown({
    required this.energyCost,
    required this.idleCost,
    required this.serviceFee,
    required this.parkingFee,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return CostBreakdown(
      energyCost: _asDouble(data['energy_cost'] ?? data['energyCost']),
      idleCost: _asDouble(data['idle_cost'] ?? data['idleCost']),
      serviceFee: _asDouble(data['service_fee'] ?? data['serviceFee']),
      parkingFee: _asDouble(data['parking_fee'] ?? data['parkingFee']),
      subtotal: _asDouble(data['subtotal']),
      tax: _asDouble(data['tax']),
      total: _asDouble(data['total']),
    );
  }
}

class BilledTo {
  final String? businessName;
  final String? address;
  final String? gstNumber;

  BilledTo({
    this.businessName,
    this.address,
    this.gstNumber,
  });

  factory BilledTo.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json);
    return BilledTo(
      businessName: _asNullableString(data['business_name']),
      address: _asNullableString(data['address']),
      gstNumber: _asNullableString(data['gst_number']),
    );
  }
}
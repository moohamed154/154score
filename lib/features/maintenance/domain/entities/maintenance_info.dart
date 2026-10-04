import 'package:equatable/equatable.dart';

class MaintenanceInfo extends Equatable {
  final bool isMaintenanceMode;
  final String? message;
  final String? messageAr;
  final String? messageEn;
  final DateTime? updatedAt;

  const MaintenanceInfo({
    required this.isMaintenanceMode,
    this.message,
    this.messageAr,
    this.messageEn,
    this.updatedAt,
  });

  factory MaintenanceInfo.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['maintenance'] is Map<String, dynamic>
            ? json['maintenance'] as Map<String, dynamic>
            : json);

    return MaintenanceInfo(
      isMaintenanceMode: data['maintenance_mode'] == true,
      message: data['message'] as String?,
      messageAr: data['message_ar'] as String?,
      messageEn: data['message_en'] as String?,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  String getDisplayMessage(bool isArabic) {
    if (isArabic) {
      return messageAr ??
          message ??
          'الخوادم تخضع لأعمال الصيانة والتطوير حالياً لتحسين الخدمة. يرجى المحاولة لاحقاً.';
    } else {
      return messageEn ??
          message ??
          'Servers are currently undergoing scheduled maintenance. Please try again shortly.';
    }
  }

  @override
  List<Object?> get props => [
        isMaintenanceMode,
        message,
        messageAr,
        messageEn,
        updatedAt,
      ];
}

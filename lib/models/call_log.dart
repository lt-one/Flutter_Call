/// 通话记录模型
class CallLog {
  final int? id;
  final String phoneNumber;
  final String callType;
  final String location;
  final String connectTime;
  final int callDuration;  // 秒
  final int billingMinutes;
  final double callFee;
  final String callDate;  // MM.DD
  final String callTime;  // HH:MM
  final bool isHdVoice;
  final bool isOutgoing;
  final String? weekday;

  CallLog({
    this.id,
    required this.phoneNumber,
    this.callType = '高清语音',
    this.location = '福建福州',
    required this.connectTime,
    required this.callDuration,
    required this.billingMinutes,
    required this.callFee,
    required this.callDate,
    required this.callTime,
    this.isHdVoice = true,
    this.isOutgoing = true,
    this.weekday,
  });

  /// 从数据库Map创建对象
  factory CallLog.fromMap(Map<String, dynamic> map) {
    return CallLog(
      id: map['id'] as int?,
      phoneNumber: map['phone_number'] as String,
      callType: map['call_type'] as String? ?? '高清语音',
      location: map['location'] as String? ?? '福建福州',
      connectTime: map['connect_time'] as String,
      callDuration: map['call_duration'] as int,
      billingMinutes: map['billing_minutes'] as int,
      callFee: (map['call_fee'] as num).toDouble(),
      callDate: map['call_date'] as String,
      callTime: map['call_time'] as String,
      isHdVoice: (map['is_hd_voice'] as int) == 1,
      isOutgoing: (map['is_outgoing'] as int) == 1,
      weekday: map['weekday'] as String?,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'call_type': callType,
      'location': location,
      'connect_time': connectTime,
      'call_duration': callDuration,
      'billing_minutes': billingMinutes,
      'call_fee': callFee,
      'call_date': callDate,
      'call_time': callTime,
      'is_hd_voice': isHdVoice ? 1 : 0,
      'is_outgoing': isOutgoing ? 1 : 0,
      'weekday': weekday,
    };
  }

  /// 复制对象并修改部分字段
  CallLog copyWith({
    int? id,
    String? phoneNumber,
    String? callType,
    String? location,
    String? connectTime,
    int? callDuration,
    int? billingMinutes,
    double? callFee,
    String? callDate,
    String? callTime,
    bool? isHdVoice,
    bool? isOutgoing,
    String? weekday,
  }) {
    return CallLog(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      callType: callType ?? this.callType,
      location: location ?? this.location,
      connectTime: connectTime ?? this.connectTime,
      callDuration: callDuration ?? this.callDuration,
      billingMinutes: billingMinutes ?? this.billingMinutes,
      callFee: callFee ?? this.callFee,
      callDate: callDate ?? this.callDate,
      callTime: callTime ?? this.callTime,
      isHdVoice: isHdVoice ?? this.isHdVoice,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      weekday: weekday ?? this.weekday,
    );
  }

  /// 格式化通话时长为显示文本
  String get durationText {
    if (callDuration < 60) {
      return '${callDuration}秒';
    } else {
      final minutes = callDuration ~/ 60;
      final seconds = callDuration % 60;
      return seconds > 0 ? '$minutes分$seconds秒' : '$minutes分钟';
    }
  }
}



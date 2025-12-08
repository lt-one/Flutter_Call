import 'package:flutter/material.dart';
import '../models/call_log.dart';
import 'custom_icons.dart';

/// 通话记录列表项
class CallLogItem extends StatelessWidget {
  final CallLog log;
  final VoidCallback? onLongPress;
  final bool isFirst;

  const CallLogItem({
    super.key,
    required this.log,
    this.onLongPress,
    this.isFirst = false,
  });

  String _getWeekday() {
    // 简化版：这里可以根据日期计算星期几
    return log.weekday ?? '星期一';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.only(
              left: 15,
              right: 15,
              top: isFirst ? 10 : 12,
              bottom: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧日历小组件
                _buildDateBadge(),
                const SizedBox(width: 10),
                // 右侧详情
                Expanded(child: _buildDetails()),
              ],
            ),
          ),
        ),
        // 分割线
        Container(
          height: 0.5,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          color: const Color(0xFFEEEEEE),
        ),
      ],
    );
  }

  /// 日历徽章
  Widget _buildDateBadge() {
    return Container(
      width: 44,
      height: 46,
      alignment: Alignment.bottomCenter,
      child: Stack(
        children: [
          // 主体
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFBE0E9)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                // 日期
                Container(
                  height: 23,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    log.callDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // 分割线
                Container(height: 1, color: const Color(0xFFFBE0E9)),
                // 星期
                Container(
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEFEFE),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getWeekday(),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                  ),
                ),
              ],
            ),
          ),
          // 耳朵
          Positioned(
            left: 9,
            top: 0,
            child: Container(
              width: 7,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                border: Border.all(color: const Color(0xFFFBE0E9), width: 1.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            left: 28,
            top: 0,
            child: Container(
              width: 7,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                border: Border.all(color: const Color(0xFFFBE0E9), width: 1.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 详情区域
  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一行：类型 + 主被叫 + 电话号码
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '高清语音',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    createPhoneIcon(
                      size: 16,
                      color: log.isOutgoing ? const Color(0xFF0BB415) : const Color(0xFF5FA8F2),
                      isOutgoing: log.isOutgoing,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      log.isOutgoing ? '主叫' : '被叫',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: log.isOutgoing ? const Color(0xFF0BB415) : const Color(0xFF5FA8F2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              log.phoneNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // 详细信息
        _buildInfoRow('对方号码归属地', log.location),
        _buildInfoRow('接通时间:', log.connectTime),
        _buildInfoRow('通话时长:', log.durationText),
        _buildInfoRow('计费分钟数:', '${log.billingMinutes}分钟'),
        _buildInfoRow('通话费用:', '¥${log.callFee.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}



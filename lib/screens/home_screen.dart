import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/call_log.dart';
import '../services/database_service.dart';
import '../widgets/call_log_item.dart';
import '../widgets/custom_icons.dart';
import 'dart:math' as math;

/// 主界面 - 通话详单查询
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<CallLog> _callLogs = [];
  double _totalFee = 0.0;
  String _topPhoneNumber = '175****8164';
  int _clickCount = 0;
  DateTime? _lastClickTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 状态栏样式通过AnnotatedRegion在build方法中设置
  }

  Future<void> _loadData() async {
    final logs = await _dbService.getAllLogs();
    final fee = await _dbService.getTotalFee();
    final phone = await _dbService.getConfig('top_phone_number');
    
    setState(() {
      _callLogs = logs;
      _totalFee = fee;
      _topPhoneNumber = phone ?? '175****8164';
    });
  }

  /// 处理电话号码点击（三连击触发添加）
  void _onPhoneNumberTap() {
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inSeconds > 1) {
      _clickCount = 0;
    }
    
    _clickCount++;
    _lastClickTime = now;
    
    if (_clickCount == 3) {
      _clickCount = 0;
      _showLogDialog();
    }
  }

  /// 根据日期字符串(MM.DD)计算星期几
  String _getWeekdayFromDate(String dateStr) {
    try {
      final now = DateTime.now();
      final parts = dateStr.split('.');
      if (parts.length == 2) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = now.year;
        final date = DateTime(year, month, day);
        final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
        // DateTime.weekday 返回 1-7 (Monday-Sunday)
        return weekdays[date.weekday - 1];
      }
    } catch (e) {
      // 解析失败时返回空字符串
    }
    return '';
  }

  /// 显示添加/编辑对话框
  void _showLogDialog({CallLog? log}) {
    final isEdit = log != null;
    final now = DateTime.now();
    final defaultDate = now.toString().substring(5, 10).replaceAll('-', '.');
    
    final phoneController = TextEditingController(text: log?.phoneNumber ?? '');
    final locationController = TextEditingController(text: log?.location ?? '福建福州');
    final dateController = TextEditingController(
      text: log?.callDate ?? defaultDate,
    );
    final weekdayController = TextEditingController(
      text: log?.weekday ?? (log == null ? _getWeekdayFromDate(defaultDate) : ''),
    );
    final timeController = TextEditingController(
      text: log?.connectTime ?? TimeOfDay.now().format(context),
    );
    final durationController = TextEditingController(
      text: log?.callDuration.toString() ?? '0',
    );
    final billingController = TextEditingController(
      text: log?.billingMinutes.toString() ?? '1',
    );
    final feeController = TextEditingController(
      text: log?.callFee.toStringAsFixed(2) ?? '0.00',
    );
    bool isOutgoing = log?.isOutgoing ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑通话记录' : '添加通话记录'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: '对方号码'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: '归属地'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: '日期 (MM.DD)'),
                  onChanged: (value) {
                    // 当日期改变时，自动计算并更新星期几
                    // 用户仍可以手动修改星期几字段
                    final weekday = _getWeekdayFromDate(value);
                    if (weekday.isNotEmpty) {
                      setDialogState(() {
                        weekdayController.text = weekday;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weekdayController,
                  decoration: const InputDecoration(
                    labelText: '星期',
                    hintText: '留空自动计算，或手动输入',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: '接通时间 (HH:MM)'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('主叫（关闭为被叫）'),
                  value: isOutgoing,
                  onChanged: (value) {
                    setDialogState(() {
                      isOutgoing = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: '通话时长(秒)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: billingController,
                  decoration: const InputDecoration(labelText: '计费分钟数'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feeController,
                  decoration: const InputDecoration(labelText: '通话费用'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // 如果星期几为空，根据日期自动计算
                  String weekday = weekdayController.text.trim();
                  if (weekday.isEmpty) {
                    weekday = _getWeekdayFromDate(dateController.text);
                  }
                  
                  final newLog = CallLog(
                    id: log?.id,
                    phoneNumber: phoneController.text,
                    location: locationController.text,
                    connectTime: timeController.text,
                    callDuration: int.parse(durationController.text),
                    billingMinutes: int.parse(billingController.text),
                    callFee: double.parse(feeController.text),
                    callDate: dateController.text,
                    callTime: timeController.text,
                    isOutgoing: isOutgoing,
                    weekday: weekday.isNotEmpty ? weekday : null,
                  );

                  if (isEdit) {
                    await _dbService.updateLog(newLog);
                  } else {
                    await _dbService.addLog(newLog);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? '修改成功' : '添加成功')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的数值')),
                    );
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示编辑菜单
  void _showEditMenu(CallLog log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                _showLogDialog(log: log);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _dbService.deleteLog(log.id!);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示更多菜单
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('清空所有记录', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showClearConfirmDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示清空确认对话框
  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空记录'),
        content: const Text('确定要清空所有通话记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.clearAllLogs();
              if (mounted) {
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('通话记录已清空')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 状态栏透明
        statusBarIconBrightness: Brightness.light, // 状态栏图标为白色
        systemNavigationBarColor: Color(0xFFF9F9F9), // 导航栏背景色
        systemNavigationBarIconBrightness: Brightness.dark, // 导航栏图标为深色
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFEE675F),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头部区域（红色渐变）
  Widget _buildHeader() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      // 背景延伸到状态栏区域（不使用SafeArea包裹背景）
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFEB4C46), Color(0xFFEE675F)],
        ),
      ),
      child: Stack(
        children: [
          // 指纹纹路装饰层 - 放在底层，延伸到状态栏区域
          Positioned(
            right: -80,
            top: -50 - statusBarHeight, // 延伸到状态栏区域
            child: createFingerprintPattern(
              width: 350,
              height: 200 + statusBarHeight, // 增加高度以覆盖状态栏区域
            ),
          ),
          // 内容层 - 使用 SafeArea 保护内容不被状态栏遮挡
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 顶部导航栏
                _buildTopBar(),
                // 费用统计
                _buildFeeSection(),
                // Tab栏
                _buildTabBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 中心标题
          Column(
            children: [
              const Text(
                '详单查询',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFBFFFD),
                ),
              ),
              GestureDetector(
                onTap: _onPhoneNumberTap,
                onLongPress: _showEditPhoneDialog,
                child: Text(
                  _topPhoneNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFBFFFD),
                  ),
                ),
              ),
            ],
          ),
          // 左右按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧返回按钮
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF625E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: createArrowIcon(
                    size: 22,
                    color: Colors.black,
                    strokeWidth: 2.0,
                  ),
                ),
              ),
              // 右侧按钮组
              Container(
                margin: const EdgeInsets.only(top: 17),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B5B0),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: createStarIcon(
                          size: 24,
                          color: Colors.black,
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B5B0),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      height: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _showMoreMenu,
                            child: createThreeDotsIcon(
                              size: 30,
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.white.withOpacity(0.5),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                          createHistoryIcon(
                            size: 30,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 费用统计区域
  Widget _buildFeeSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '通话费用总计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFBFFFD),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_totalFee.toStringAsFixed(2)}元',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFBFFFD),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFFBEB), width: 0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '查账单',
              style: TextStyle(fontSize: 12, color: Color(0xFFFFFBEB)),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab标签栏
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTab('通话', isSelected: true),
          _buildTab('流量'),
          _buildTab('短彩信'),
          _buildTab('增值业务'),
        ],
      ),
    );
  }

  Widget _buildTab(String text, {bool isSelected = false}) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            color: const Color(0xFFFBFFFD),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 2,
          width: 25,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFBFFFD) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  /// 内容区域（白色圆角）
  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildMonthSelector(),
          _buildFilterBar(),
          Expanded(
            child: _buildCallLogsList(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 月份选择器
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var month in ['12月', '11月', '10月', '9月', '8月', '7月', '6月'])
            Flexible(
              child: _buildMonthButton(month, month == '12月'),
            ),
          Flexible(
            child: _buildCalendarButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthButton(String month, bool isSelected) {
    // 内部方块大小固定为48，保持正方形
    const double innerBoxSize = 48;
    const double topSectionHeight = 26;
    const double bottomSectionHeight = 15;

    return Container(
      alignment: Alignment.center,
      child: Container(
        width: innerBoxSize,
        height: innerBoxSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFEB4C46) : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Container(
              width: innerBoxSize,
              height: topSectionHeight,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF5F5) : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFFE94947) : const Color(0xFF333333),
                  letterSpacing: -1.0,
                ),
              ),
            ),
            Container(
              width: innerBoxSize,
              height: bottomSectionHeight,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFCFCF5) : null,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '2025',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFFE94947) : const Color(0xFF333333),
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarButton() {
    // 内部方块大小固定为48，保持正方形
    const double innerBoxSize = 48;
    const double topSectionHeight = 26;
    const double bottomSectionHeight = 15;

    return Container(
      alignment: Alignment.center,
      child: Container(
        width: 64, // 日历按钮稍宽以容纳文字
        height: innerBoxSize,
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              width: 60,
              height: topSectionHeight,
              alignment: Alignment.center,
              child: createCalendarIcon(
                size: 25,
                color: const Color(0xFFD8716B),
                bgColor: const Color(0xFFFFDEE3),
              ),
            ),
            Container(
              width: 60,
              height: bottomSectionHeight,
              alignment: Alignment.center,
              child: const Text(
                '按日选择',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFD8716B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 筛选器栏
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('顺序', style: TextStyle(fontSize: 12, color: Color(0xFF3F3F3F))),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: createSortIcons(
                  size: 16,
                  colorUp: const Color(0xFFA3A3A3),
                  colorDown: const Color(0xFF353535),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('呼叫类型', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: createDropdownIcon(
                  size: 8,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('费用', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: createDropdownIcon(
                  size: 8,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Text('号码筛选', style: TextStyle(fontSize: 14, color: Color(0xFFC8C8C8))),
                const SizedBox(width: 5),
                const Text('|', style: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0))),
                const SizedBox(width: 5),
                createSearchIcon(
                  size: 16,
                  color: const Color(0xFF939393),
                  strokeWidth: 1.8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 通话记录列表
  Widget _buildCallLogsList() {
    if (_callLogs.isEmpty) {
      return const Center(
        child: Text('暂无通话记录', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _callLogs.length + 1,
      itemBuilder: (context, index) {
        if (index == _callLogs.length) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 0.5, color: Color(0xFFEEEEEE), indent: 15, endIndent: 15),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  '没有更多了',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
              ),
            ],
          );
        }

        final log = _callLogs[index];
        // 第一个项目减小上边距
        final isFirst = index == 0;
        return Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : 0, bottom: 0),
          child: CallLogItem(
            log: log,
            isFirst: isFirst,
            onLongPress: () => _showEditMenu(log),
          ),
        );
      },
    );
  }

  /// 底部功能栏
  Widget _buildBottomBar() {
    return Container(
      height: 50,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('温馨提示', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
          const Text(' | ', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const Text('安全验证', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
          const Text(' | ', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const Text('满意度调查', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
          const Text(' | ', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const Text('下载详单', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  /// 显示编辑电话号码对话框
  void _showEditPhoneDialog() {
    final controller = TextEditingController(text: _topPhoneNumber);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改顶部号码'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '顶部显示号码'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.setConfig('top_phone_number', controller.text);
              setState(() {
                _topPhoneNumber = controller.text;
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('号码修改成功')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}



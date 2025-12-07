import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/call_log.dart';
import '../services/database_service.dart';
import '../widgets/call_log_item.dart';
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
    
    // 设置主界面状态栏样式（红色背景，白色图标）
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF9F9F9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
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

  /// 显示添加/编辑对话框
  void _showLogDialog({CallLog? log}) {
    final isEdit = log != null;
    final phoneController = TextEditingController(text: log?.phoneNumber ?? '');
    final locationController = TextEditingController(text: log?.location ?? '福建福州');
    final dateController = TextEditingController(
      text: log?.callDate ?? DateTime.now().toString().substring(5, 10).replaceAll('-', '.'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFEE675F),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 构建头部区域（红色渐变）
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFEB4C46), Color(0xFFEE675F)],
        ),
      ),
      child: SafeArea(
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
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 16,
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
                      child: const Icon(
                        Icons.star_border,
                        color: Colors.black,
                        size: 18,
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
                        children: [
                          GestureDetector(
                            onTap: _showMoreMenu,
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.history,
                              color: Colors.black,
                              size: 18,
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '通话费用总计',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFBFFFD),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '${_totalFee.toStringAsFixed(2)}元',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFBFFFD),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        children: [
          for (var month in ['12月', '11月', '10月', '9月', '8月', '7月', '6月'])
            Expanded(
              child: _buildMonthButton(month, month == '12月'),
            ),
          Expanded(
            child: _buildCalendarButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthButton(String month, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFEB4C46) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Container(
              height: 26,
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
                  color: isSelected ? const Color(0xFFE94947) : const Color(0xFF333333),
                ),
              ),
            ),
            Container(
              height: 15,
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
                  color: isSelected ? const Color(0xFFE94947) : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            height: 26,
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_today,
              size: 20,
              color: Color(0xFFE57D80),
            ),
          ),
          Container(
            height: 15,
            alignment: Alignment.center,
            child: const Text(
              '按日选择',
              style: TextStyle(fontSize: 10, color: Color(0xFFE57D80)),
            ),
          ),
        ],
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
          const Row(
            children: [
              Text('顺序', style: TextStyle(fontSize: 12, color: Color(0xFF3F3F3F))),
              SizedBox(width: 2),
              Icon(Icons.unfold_more, size: 16, color: Color(0xFFA3A3A3)),
            ],
          ),
          const Row(
            children: [
              Text('呼叫类型', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
            ],
          ),
          const Row(
            children: [
              Text('费用', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Text('号码筛选', style: TextStyle(fontSize: 14, color: Color(0xFFC8C8C8))),
                SizedBox(width: 5),
                Text('|', style: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0))),
                SizedBox(width: 5),
                Icon(Icons.search, size: 16, color: Color(0xFF939393)),
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
      itemCount: _callLogs.length + 1,
      itemBuilder: (context, index) {
        if (index == _callLogs.length) {
          return const Column(
            children: [
              Divider(height: 0.5, color: Color(0xFFEEEEEE), indent: 15, endIndent: 15),
              Padding(
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
        return CallLogItem(
          log: log,
          onLongPress: () => _showEditMenu(log),
        );
      },
    );
  }

  /// 底部功能栏
  Widget _buildBottomBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(top: 10),
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('温馨提示', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(' | ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text('安全验证', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(' | ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text('满意度调查', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(' | ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text('下载详单', style: TextStyle(fontSize: 12, color: Colors.grey)),
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


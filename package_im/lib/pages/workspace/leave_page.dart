import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';

/// 请假页面
class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  // 请假类型
  String _selectedLeaveType = '事假';
  final List<String> _leaveTypes = ['事假', '病假', '年假', '调休', '婚假', '产假', '陪产假', '其他'];
  
  // 日期时间
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  
  // 请假时长类型
  String _durationType = '全天';
  final List<String> _durationTypes = ['全天', '上午', '下午', '自定义时间'];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// 选择日期
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// 选择时间
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  /// 计算请假天数
  double _calculateDays() {
    if (_startDate == null || _endDate == null) return 0;
    
    if (_durationType == '全天') {
      return _endDate!.difference(_startDate!).inDays + 1.0;
    } else if (_durationType == '上午' || _durationType == '下午') {
      final days = _endDate!.difference(_startDate!).inDays;
      return days + 0.5;
    } else {
      // 自定义时间
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime.hour,
        _startTime.minute,
      );
      final end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime.hour,
        _endTime.minute,
      );
      final hours = end.difference(start).inHours;
      return (hours / 8.0);
    }
  }

  /// 提交请假申请
  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_startDate == null || _endDate == null) {
      EasyLoading.showError('请选择请假日期');
      return;
    }
    
    if (_reasonController.text.trim().isEmpty) {
      EasyLoading.showError('请填写请假原因');
      return;
    }

    try {
      EasyLoading.show(status: '提交中...');
      
      // TODO: 调用API提交请假申请
      await Future.delayed(const Duration(seconds: 2));
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('请假申请已提交');
      
      // 延迟返回
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      EasyLoading.showError('提交失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击空白处隐藏键盘
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('请假申请'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 请假类型选择
              _buildSectionTitle('请假类型'),
              _buildLeaveTypeSelector(),
              const SizedBox(height: 24),
              
              // 请假时间
              _buildSectionTitle('请假时间'),
              _buildDateSelector(),
              const SizedBox(height: 16),
              
              // 时长类型
              _buildDurationTypeSelector(),
              
              // 自定义时间选择
              if (_durationType == '自定义时间') ...[
                const SizedBox(height: 16),
                _buildTimeSelector(),
              ],
              
              const SizedBox(height: 16),
              
              // 请假天数显示
              _buildDaysDisplay(),
              const SizedBox(height: 24),
              
              // 请假原因
              _buildSectionTitle('请假原因'),
              _buildReasonInput(),
              const SizedBox(height: 32),
              
              // 提交按钮
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 构建请假类型选择器
  Widget _buildLeaveTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _leaveTypes.map((type) {
        final isSelected = _selectedLeaveType == type;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedLeaveType = type;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建日期选择器
  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateCard(
            label: '开始日期',
            date: _startDate,
            onTap: () => _selectDate(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateCard(
            label: '结束日期',
            date: _endDate,
            onTap: () => _selectDate(context, false),
          ),
        ),
      ],
    );
  }

  /// 构建日期卡片
  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('yyyy-MM-dd').format(date)
                      : '选择日期',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: date != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建时长类型选择器
  Widget _buildDurationTypeSelector() {
    return Row(
      children: _durationTypes.map((type) {
        final isSelected = _durationType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _durationType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建时间选择器
  Widget _buildTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeCard(
            label: '开始时间',
            time: _startTime,
            onTap: () => _selectTime(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeCard(
            label: '结束时间',
            time: _endTime,
            onTap: () => _selectTime(context, false),
          ),
        ),
      ],
    );
  }

  /// 构建时间卡片
  Widget _buildTimeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建请假天数显示
  Widget _buildDaysDisplay() {
    final days = _calculateDays();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            '请假时长：',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Text(
            days > 0 ? '$days 天' : '请选择日期',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建请假原因输入框
  Widget _buildReasonInput() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 5,
      maxLength: 200,
      decoration: InputDecoration(
        hintText: '请输入请假原因...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请填写请假原因';
        }
        if (value.trim().length < 5) {
          return '请假原因至少5个字';
        }
        return null;
      },
    );
  }

  /// 构建提交按钮
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitLeave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          '提交申请',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

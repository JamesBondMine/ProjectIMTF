import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_im/pages/schedule/schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 日程页面
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<Schedule> _schedules = [];
  final ScrollController _scrollController = ScrollController();
  bool _isCalendarExpanded = true;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _loadSchedules();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听滚动
  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final isScrollingDown = currentOffset < _lastScrollOffset;
    
    // 向上滚动超过50px时折叠日历
    if (currentOffset > 50 && _isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = false;
      });
    } 
    // 只有在向下滚动到顶部(offset接近0)时才展开日历
    else if (currentOffset <= 10 && isScrollingDown && !_isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = true;
      });
    }
    
    _lastScrollOffset = currentOffset;
  }

  /// 初始化日期格式化
  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('zh_CN', null);
  }

  /// 加载日程
  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? schedulesJson = prefs.getString('schedules');
    if (schedulesJson != null) {
      final List<dynamic> decoded = json.decode(schedulesJson);
      setState(() {
        _schedules = decoded.map((e) => Schedule.fromJson(e)).toList();
      });
    }
  }

  /// 保存日程
  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_schedules.map((e) => e.toJson()).toList());
    await prefs.setString('schedules', encoded);
  }

  /// 获取选中日期的日程
  List<Schedule> _getSchedulesForDate(DateTime date) {
    return _schedules.where((schedule) {
      return schedule.date.year == date.year &&
          schedule.date.month == date.month &&
          schedule.date.day == date.day;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 获取某个月份有日程的日期
  Set<int> _getDaysWithSchedules(DateTime month) {
    final Set<int> days = {};
    for (final schedule in _schedules) {
      if (schedule.date.year == month.year && schedule.date.month == month.month) {
        days.add(schedule.date.day);
      }
    }
    return days;
  }

  /// 显示添加/编辑日程对话框
  void _showScheduleDialog({Schedule? schedule}) {
    final isEdit = schedule != null;
    final titleController = TextEditingController(text: schedule?.title ?? '');
    final descController = TextEditingController(text: schedule?.description ?? '');
    DateTime selectedDate = schedule?.date ?? _selectedDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(schedule?.date ?? _selectedDate);
    String selectedColor = schedule?.color ?? '0xFF7B1FA2';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? '编辑日程' : '新建日程'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    
                    // 描述
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: '描述（可选）',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),
                    
                    // 日期选择
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('日期'),
                      subtitle: Text(DateFormat('yyyy年MM月dd日').format(selectedDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          locale: const Locale('zh', 'CN'),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                    ),
                    const Divider(),
                    
                    // 时间选择
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('时间'),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                    const Divider(),
                    
                    // 颜色选择
                    const SizedBox(height: 8),
                    const Text('标签颜色', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        '0xFF7B1FA2', // 紫色（主题色）
                        '0xFF1989FA', // 蓝色
                        '0xFFFF6B6B', // 红色
                        '0xFFFFBE0B', // 黄色
                        '0xFF4CAF50', // 绿色
                        '0xFFFF6D00', // 橙色
                      ].map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(int.parse(color)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
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
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入标题')),
                      );
                      return;
                    }

                    final newSchedule = Schedule(
                      id: schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      date: selectedDate,
                      color: selectedColor,
                    );

                    setState(() {
                      if (isEdit) {
                        final index = _schedules.indexWhere((s) => s.id == schedule.id);
                        _schedules[index] = newSchedule;
                      } else {
                        _schedules.add(newSchedule);
                      }
                    });

                    _saveSchedules();
                    Navigator.pop(context);
                  },
                  child: Text(
                    isEdit ? '保存' : '添加',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 删除日程
  void _deleteSchedule(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除日程'),
          content: const Text('确定要删除这个日程吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _schedules.removeWhere((s) => s.id == schedule.id);
                });
                _saveSchedules();
                Navigator.pop(context);
              },
              child: Text(
                '删除',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildStickyHeader(),
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isCalendarExpanded ? _buildCalendar() : const SizedBox.shrink(),
            ),
          ),
          _buildScheduleListSliver(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建粘性头部（支持折叠状态）
  Widget _buildStickyHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                '日程',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        title: _isCalendarExpanded
            ? null
            : GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Row(
                  children: [
                    Text(
                      DateFormat('MM月dd日', 'zh_CN').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more, size: 20),
                  ],
                ),
              ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  /// 构建日历
  Widget _buildCalendar() {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = 周日, 6 = 周六
    final daysWithSchedules = _getDaysWithSchedules(_focusedMonth);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 月份切换
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Text(
                DateFormat('yyyy年MM月', 'zh_CN').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // 星期标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          
          // 日期网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox();
              }

              final day = index - firstWeekday + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;
              final hasSchedule = daysWithSchedules.contains(day);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : isToday
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasSchedule && !isSelected)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 2,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建日程列表（Sliver版本）
  Widget _buildScheduleListSliver() {
    final schedules = _getSchedulesForDate(_selectedDate);

    if (schedules.isEmpty) {
      return SliverFillRemaining(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无日程',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角按钮添加日程',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildScheduleItem(schedules[index]);
          },
          childCount: schedules.length,
        ),
      ),
    );
  }

  /// 构建日程项
  Widget _buildScheduleItem(Schedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: Color(int.parse(schedule.color)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          schedule.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(schedule.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (schedule.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                schedule.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (value) {
            if (value == 'edit') {
              _showScheduleDialog(schedule: schedule);
            } else if (value == 'delete') {
              _deleteSchedule(schedule);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

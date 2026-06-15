import 'dart:async';

import 'package:flutter/material.dart';
import '../models/golf_event.dart';
import '../services/app_schedule_service.dart';
import '../services/weather_api_service.dart';

class AddScheduleScreen extends StatefulWidget {
  final GolfEvent? editingEvent;

  const AddScheduleScreen({super.key, this.editingEvent});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _courseNameController;
  late TextEditingController _addressController;
  late TextEditingController _titleController;
  late int _notifyHours;
  bool _weatherAlert = true;
  bool _isLoading = false;
  Timer? _courseSearchDebounce;
  List<CourseSearchResult> _courseSuggestions = [];
  CourseSearchResult? _selectedCourse;
  bool _isSearchingCourses = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.editingEvent?.startDate ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(
        widget.editingEvent?.startDate ?? DateTime.now());
    _courseNameController =
        TextEditingController(text: widget.editingEvent?.location ?? '');
    _courseNameController.addListener(_onCourseNameChanged);
    _addressController =
        TextEditingController(text: widget.editingEvent?.address ?? '');
    _titleController =
        TextEditingController(text: widget.editingEvent?.title ?? '');
    _notifyHours = 24;
  }

  @override
  void dispose() {
    _courseSearchDebounce?.cancel();
    _courseNameController.dispose();
    _addressController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onCourseNameChanged() {
    final keyword = _courseNameController.text.trim();
    if (_selectedCourse != null && _selectedCourse!.name != keyword) {
      _selectedCourse = null;
    }

    _courseSearchDebounce?.cancel();
    if (keyword.isEmpty) {
      setState(() {
        _courseSuggestions = [];
        _isSearchingCourses = false;
      });
      return;
    }

    _courseSearchDebounce = Timer(const Duration(milliseconds: 260), () {
      _searchCourseSuggestions(keyword);
    });
  }

  Future<void> _searchCourseSuggestions(String keyword) async {
    if (!mounted) return;
    setState(() => _isSearchingCourses = true);

    final results =
        await WeatherApiService.instance.searchCourseSuggestions(keyword);

    if (!mounted || _courseNameController.text.trim() != keyword) return;
    setState(() {
      _courseSuggestions = results;
      _isSearchingCourses = false;
    });
  }

  void _selectCourseSuggestion(CourseSearchResult course) {
    _courseSearchDebounce?.cancel();
    _courseNameController.removeListener(_onCourseNameChanged);
    _courseNameController.text = course.name;
    _courseNameController.selection = TextSelection.collapsed(
      offset: course.name.length,
    );
    _courseNameController.addListener(_onCourseNameChanged);
    setState(() {
      _selectedCourse = course;
      _courseSuggestions = [];
      _isSearchingCourses = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveSchedule() async {
    final courseName = _courseNameController.text.trim();
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : courseName;
    final address = _addressController.text.trim();

    if (courseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('골프장을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      CourseSearchResult? course;
      String? courseId = widget.editingEvent?.courseId;
      double? lat = widget.editingEvent?.lat;
      double? lng = widget.editingEvent?.lng;
      var weatherAlertForSave = _weatherAlert;

      if (_weatherAlert) {
        course = _selectedCourse?.name == courseName
            ? _selectedCourse
            : await WeatherApiService.instance.searchCourse(courseName);
        courseId = course?.courseId ??
            await WeatherApiService.instance.searchCourseId(courseName);

        if (courseId == null || courseId.isEmpty) {
          weatherAlertForSave = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$courseName는 DB에 없어 날씨 알림 없이 커스텀 일정으로 저장합니다'),
              ),
            );
          }
        }

        lat = course?.lat ?? lat;
        lng = course?.lng ?? lng;
      }

      if (lat == null || lng == null) {
        final geocoded = await WeatherApiService.instance.geocodeBestEffort(
          courseName: courseName,
          address: address,
        );
        lat = geocoded?.lat ?? lat;
        lng = geocoded?.lng ?? lng;
      }

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (widget.editingEvent != null) {
        // 수정
        await AppScheduleService().updateSchedule(
          widget.editingEvent!.id,
          {
            'title': title,
            'locationName': courseName,
            'startAt': startDateTime.millisecondsSinceEpoch,
            'notifyBeforeHours': _notifyHours,
            'weatherAlertEnabled': weatherAlertForSave,
            'courseId': courseId,
            'address': address.isEmpty ? null : address,
            'lat': lat,
            'lng': lng,
          },
        );
      } else {
        // 신규
        await AppScheduleService().addGolfSchedule(
          title: title,
          locationName: courseName,
          address: address.isEmpty ? null : address,
          lat: lat,
          lng: lng,
          startAt: startDateTime,
          notifyBeforeHours: _notifyHours,
          weatherAlertEnabled: weatherAlertForSave,
          courseId: courseId,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E2A24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editingEvent != null ? '일정 수정' : '새 일정 추가',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '라운드 정보를 입력하면 골프장 날씨와 알림을 함께 확인할 수 있습니다.',
                style: TextStyle(color: Color(0xB3F4FBF8), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // 날짜
              _buildSectionLabel('날짜 *'),
              _buildDateButton(),
              const SizedBox(height: 16),

              // 시간
              _buildSectionLabel('시간 *'),
              _buildTimeButton(),
              const SizedBox(height: 16),

              // 골프장
              _buildSectionLabel('골프장 *'),
              _buildCourseNameField(),
              const SizedBox(height: 16),

              // 주소
              _buildSectionLabel('주소/위치 메모'),
              _buildTextField(_addressController, '예: 경기도 용인시 처인구 ...'),
              const SizedBox(height: 16),

              // 제목
              _buildSectionLabel('제목'),
              _buildTextField(_titleController, '예: 주말 라운드'),
              const SizedBox(height: 16),

              // 알림
              _buildSectionLabel('알림'),
              _buildNotifyChips(),
              const SizedBox(height: 16),

              // 날씨 알림
              Row(
                children: [
                  Checkbox(
                    value: _weatherAlert,
                    onChanged: (v) =>
                        setState(() => _weatherAlert = v ?? false),
                    activeColor: const Color(0xFF2E7D6B),
                  ),
                  const Text(
                    '날씨 위험 알림 받기',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D6B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.editingEvent != null ? '일정 수정' : '일정 저장',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          color: Color(0xB3F4FBF8), fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildCourseNameField() {
    return Column(
      children: [
        _buildTextField(_courseNameController, '예: 레이크사이드CC'),
        if (_isSearchingCourses)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Color(0xFF143630),
              color: Color(0xFF2E7D6B),
            ),
          ),
        if (_courseSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF143630),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x1FF4FBF8)),
            ),
            child: Column(
              children: _courseSuggestions.map((course) {
                final subtitle = course.nameShort?.trim();
                return InkWell(
                  onTap: () => _selectCourseSuggestion(course),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          color: Color(0xFF7DDEC3),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF4FBF8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (subtitle != null &&
                                  subtitle.isNotEmpty &&
                                  subtitle != course.name)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0x99F4FBF8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0x802E7D6B),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateButton() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF143630),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x14F4FBF8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedDate.month}월 ${_selectedDate.day}일 (${[
                '월',
                '화',
                '수',
                '목',
                '금',
                '토',
                '일'
              ][_selectedDate.weekday - 1]})',
              style: const TextStyle(color: Color(0xFFF4FBF8), fontSize: 15),
            ),
            const Icon(Icons.calendar_today,
                color: Color(0xFF2E7D6B), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF143630),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x14F4FBF8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Color(0xFFF4FBF8), fontSize: 15),
            ),
            const Icon(Icons.access_time, color: Color(0xFF2E7D6B), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x73F4FBF8)),
        filled: true,
        fillColor: const Color(0xFF143630),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x14F4FBF8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x14F4FBF8)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildNotifyChips() {
    return Wrap(
      spacing: 8,
      children: [6, 12, 24, 48, 168, 240].map((hours) {
        final selected = _notifyHours == hours;
        final label = hours < 24 ? '$hours시간 전' : '${hours ~/ 24}일 전';
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          selectedColor: const Color(0xFF2E7D6B),
          backgroundColor: const Color(0xFF243447),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontSize: 12,
          ),
          onSelected: (_) => setState(() => _notifyHours = hours),
        );
      }).toList(),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../l10n/l10n.dart';
import '../models/golf_event.dart';
import '../services/app_schedule_service.dart';
import '../services/calendar_import_service.dart';
import '../services/weather_api_service.dart';

class AddScheduleScreen extends StatefulWidget {
  final GolfEvent? editingEvent;

  /// true면 화면 진입 직후 캘린더 가져오기를 자동 실행 (일정 탭 바로가기용)
  final bool autoImportFromCalendar;

  const AddScheduleScreen({
    super.key,
    this.editingEvent,
    this.autoImportFromCalendar = false,
  });

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
  PortalGolfPlace? _portalPlace; // 캘린더 가져오기에서 포털 검색으로 찾은 DB 외 골프장
  bool _isSearchingCourses = false;
  bool _isImportingCalendar = false;

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

    if (widget.autoImportFromCalendar && widget.editingEvent == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _importFromCalendar();
      });
    }
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
        SnackBar(content: Text(context.l10n.schedEnterCourseName)),
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
                content: Text(context.l10n.schedCourseNotInDb(courseName)),
              ),
            );
          }
        }

        lat = course?.lat ?? lat;
        lng = course?.lng ?? lng;
      }

      // 포털 검색으로 찾은 골프장이면 좌표를 그대로 사용 (이름이 바뀌지 않은 경우만)
      if ((lat == null || lng == null) &&
          _portalPlace != null &&
          _portalPlace!.name == courseName) {
        lat = _portalPlace!.lat;
        lng = _portalPlace!.lng;
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
          SnackBar(content: Text(context.l10n.schedErrorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importFromCalendar() async {
    setState(() => _isImportingCalendar = true);

    try {
      final result = await CalendarImportService.instance.findGolfEvents();
      if (!mounted) return;

      if (!result.permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.schedCalendarPermissionNeeded),
          ),
        );
        return;
      }

      if (result.candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.schedNoCalendarCandidates)),
        );
        return;
      }

      final selected = await _showCalendarCandidates(result.candidates);
      if (selected == null || !mounted) return;

      _applyCalendarCandidate(selected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.schedCalendarImportFailed('$e'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingCalendar = false);
      }
    }
  }

  Future<CalendarGolfImportCandidate?> _showCalendarCandidates(
    List<CalendarGolfImportCandidate> candidates,
  ) {
    final t = GwTheme.of(context);
    return showModalBottomSheet<CalendarGolfImportCandidate>(
      context: context,
      backgroundColor: t.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            builder: (context, controller) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.schedCalendarCandidatesTitle,
                            style: TextStyle(
                              color: t.fg,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: t.fg2),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      context.l10n.schedCalendarCandidatesDesc,
                      style: TextStyle(color: t.fg2, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        final matched = candidate.matchedCourse != null;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, candidate),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: matched ? t.successBorder : t.cardBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      matched
                                          ? Icons.check_circle_outline
                                          : Icons.calendar_today_outlined,
                                      color: matched ? t.success : t.accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        candidate.displayCourseName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: t.fg,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatCalendarDate(candidate.startAt),
                                  style: TextStyle(
                                    color: t.fg2,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  candidate.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: t.fg3,
                                    fontSize: 12,
                                  ),
                                ),
                                if (candidate.displayAddress != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    candidate.displayAddress!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: t.fg3,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (!matched) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    candidate.portalPlace != null
                                        ? context.l10n.schedPortalFoundCourse
                                        : context.l10n.schedVerifyCourseName,
                                    style: TextStyle(
                                      color: candidate.portalPlace != null
                                          ? t.accent
                                          : t.warn,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _applyCalendarCandidate(CalendarGolfImportCandidate candidate) {
    final course = candidate.matchedCourse;
    final courseName = course?.name ?? candidate.displayCourseName;

    _courseSearchDebounce?.cancel();
    _courseNameController.removeListener(_onCourseNameChanged);
    _courseNameController.text = courseName;
    _courseNameController.selection = TextSelection.collapsed(
      offset: courseName.length,
    );
    _courseNameController.addListener(_onCourseNameChanged);

    setState(() {
      _selectedDate = DateTime(
        candidate.startAt.year,
        candidate.startAt.month,
        candidate.startAt.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(candidate.startAt);
      _selectedCourse = course;
      _portalPlace = candidate.portalPlace;
      _courseSuggestions = [];
      _isSearchingCourses = false;
      _titleController.text = candidate.title;
      _addressController.text = candidate.displayAddress ?? '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.schedCalendarApplied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editingEvent != null
              ? context.l10n.schedEditSchedule
              : context.l10n.schedAddNewSchedule,
          style: TextStyle(
              color: t.fg, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.schedIntro,
                style: TextStyle(color: t.fg2, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildCalendarImportButton(),
              const SizedBox(height: 20),

              // 날짜
              _buildSectionLabel(context.l10n.schedDateLabel),
              _buildDateButton(),
              const SizedBox(height: 16),

              // 시간
              _buildSectionLabel(context.l10n.schedTimeLabel),
              _buildTimeButton(),
              const SizedBox(height: 16),

              // 골프장
              _buildSectionLabel(context.l10n.schedCourseLabel),
              _buildCourseNameField(),
              const SizedBox(height: 16),

              // 주소
              _buildSectionLabel(context.l10n.schedAddressLabel),
              _buildTextField(_addressController, context.l10n.schedAddressHint),
              const SizedBox(height: 16),

              // 제목
              _buildSectionLabel(context.l10n.schedTitleLabel),
              _buildTextField(_titleController, context.l10n.schedTitleHint),
              const SizedBox(height: 16),

              // 알림
              _buildSectionLabel(context.l10n.schedNotifyLabel),
              _buildNotifyChips(),
              const SizedBox(height: 16),

              // 날씨 알림
              Row(
                children: [
                  Checkbox(
                    value: _weatherAlert,
                    onChanged: (v) =>
                        setState(() => _weatherAlert = v ?? false),
                    activeColor: t.accent,
                  ),
                  Text(
                    context.l10n.schedWeatherAlertToggle,
                    style: TextStyle(color: t.fg2),
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
                    backgroundColor: t.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: t.accentInk),
                        )
                      : Text(
                          widget.editingEvent != null
                              ? context.l10n.schedEditSchedule
                              : context.l10n.schedSaveSchedule,
                          style: TextStyle(
                              color: t.accentInk,
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
    final t = GwTheme.of(context);
    return Text(
      label,
      style: TextStyle(
          color: t.fg2, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildCalendarImportButton() {
    final t = GwTheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed:
            _isLoading || _isImportingCalendar ? null : _importFromCalendar,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.accent,
          side: BorderSide(color: t.accent.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: t.surface,
        ),
        icon: _isImportingCalendar
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.accent,
                ),
              )
            : const Icon(Icons.event_available_outlined, size: 19),
        label: Text(
          _isImportingCalendar
              ? context.l10n.schedCheckingCalendar
              : context.l10n.schedImportFromCalendar,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildCourseNameField() {
    final t = GwTheme.of(context);
    return Column(
      children: [
        _buildTextField(_courseNameController, context.l10n.schedCourseHint),
        if (_isSearchingCourses)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: t.surface,
              color: t.accent,
            ),
          ),
        if (_courseSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.cardBorder),
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
                        Icon(
                          Icons.flag_outlined,
                          color: t.accent,
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
                                style: TextStyle(
                                  color: t.fg,
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
                                    style: TextStyle(
                                      color: t.fg2,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle_outline,
                          color: t.accent.withValues(alpha: 0.5),
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
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat(context.l10n.schedDateFmt, context.l10n.localeName)
                  .format(_selectedDate),
              style: TextStyle(color: t.fg, fontSize: 15),
            ),
            Icon(Icons.calendar_today, color: t.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: t.fg, fontSize: 15),
            ),
            Icon(Icons.access_time, color: t.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    final t = GwTheme.of(context);
    return TextField(
      controller: controller,
      style: TextStyle(color: t.fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.fg3),
        filled: true,
        fillColor: t.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.cardBorder),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildNotifyChips() {
    final t = GwTheme.of(context);
    return Wrap(
      spacing: 8,
      children: [6, 12, 24, 48, 168, 240].map((hours) {
        final selected = _notifyHours == hours;
        final label = hours < 24
            ? context.l10n.schedHoursBefore(hours)
            : context.l10n.schedDaysBefore(hours ~/ 24);
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          selectedColor: t.accent,
          backgroundColor: t.surface2,
          labelStyle: TextStyle(
            color: selected ? t.accentInk : t.fg3,
            fontSize: 12,
          ),
          onSelected: (_) => setState(() => _notifyHours = hours),
        );
      }).toList(),
    );
  }

  String _formatCalendarDate(DateTime date) {
    return DateFormat(
      context.l10n.schedCalendarDateFmt,
      context.l10n.localeName,
    ).format(date);
  }
}

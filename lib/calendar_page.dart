import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final supabase = Supabase.instance.client;

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  String _viewMode = 'month'; // 'month', 'week', 'day'
  Map<String, List<Map<String, dynamic>>> _jobsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    if (supabase.auth.currentUser == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      // Get user's organization
      final userOrgs = await supabase
          .from('users')
          .select('org_id')
          .eq('id', userId)
          .single();

      final orgId = userOrgs['org_id'];

      // Get all jobs for this month
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

      final jobs = await supabase
          .from('jobs')
          .select('id, title, description, start_date, end_date, assigned_to, status, clients(name)')
          .eq('org_id', orgId)
          .gte('start_date', startOfMonth.toIso8601String())
          .lte('start_date', endOfMonth.toIso8601String())
          .order('start_date', ascending: true);

      // Group jobs by date
      final jobsByDate = <String, List<Map<String, dynamic>>>{};
      for (final job in jobs) {
        final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(job['start_date']));
        if (jobsByDate[dateKey] == null) {
          jobsByDate[dateKey] = [];
        }
        jobsByDate[dateKey]!.add(job);
      }

      if (mounted) {
        setState(() {
          _jobs = List<Map<String, dynamic>>.from(jobs);
          _jobsByDate = jobsByDate;
          _loading = false;
        });
      }
    } catch (e) {
      _logger.e('❌ Error loading jobs: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _rescheduleJob({
    required String jobId,
    required DateTime newDate,
  }) async {
    try {
      _logger.i('📅 Rescheduling job $jobId to $newDate');

      await supabase
          .from('jobs')
          .update({'start_date': newDate.toIso8601String()})
          .eq('id', jobId);

      _logger.i('✅ Job rescheduled');
      await _loadJobs();
    } catch (e) {
      _logger.e('❌ Error rescheduling job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rescheduling job: $e')),
      );
    }
  }

  void _showJobDetailsDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job['title'] ?? 'Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client: ${job['clients']['name'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Status: ${job['status']}'),
              const SizedBox(height: 8),
              Text('Assigned to: ${job['assigned_to'] ?? 'Unassigned'}'),
              const SizedBox(height: 8),
              Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(job['start_date']))}',
              ),
              const SizedBox(height: 8),
              if (job['description'] != null) ...[
                Text('Description:'),
                const SizedBox(height: 4),
                Text(job['description']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/job-detail', arguments: job['id']);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    final weeks = <List<int>>[];
    var week = <int>[];

    for (int i = 0; i < firstWeekday - 1; i++) {
      week.add(0);
    }

    for (int day = 1; day <= daysInMonth; day++) {
      week.add(day);
      if (week.length == 7) {
        weeks.add(week);
        week = [];
      }
    }

    if (week.isNotEmpty) {
      while (week.length < 7) {
        week.add(0);
      }
      weeks.add(week);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        ...weeks.map((week) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: week
                    .map((day) => Expanded(
                          child: _buildDayCell(day),
                        ))
                    .toList(),
              ),
            )),
      ],
    );
  }

  Widget _buildDayCell(int day) {
    if (day == 0) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[50],
        ),
      );
    }

    final cellDate = DateTime(_selectedDate.year, _selectedDate.month, day);
    final dateKey = DateFormat('yyyy-MM-dd').format(cellDate);
    final jobsForDay = _jobsByDate[dateKey] ?? [];
    final isSelected = day == _selectedDate.day;
    final isToday = cellDate.day == DateTime.now().day &&
        cellDate.month == DateTime.now().month &&
        cellDate.year == DateTime.now().year;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = cellDate);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          color: isSelected
              ? const Color(0xFF007BFF).withOpacity(0.1)
              : isToday
                  ? const Color(0xFF007BFF).withOpacity(0.05)
                  : Colors.white,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isToday ? const Color(0xFF007BFF) : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: jobsForDay
                      .take(2)
                      .map((job) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: GestureDetector(
                              onTap: () => _showJobDetailsDialog(job),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(job['status']),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  job['title'] ?? 'Job',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            if (jobsForDay.length > 2)
              Text(
                '+${jobsForDay.length - 2} more',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return const Color(0xFF007BFF);
      default:
        return Colors.grey;
    }
  }

  Widget _buildWeekView() {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((day) {
              final dateKey = DateFormat('yyyy-MM-dd').format(day);
              final jobsForDay = _jobsByDate[dateKey] ?? [];

              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  color: day.day == _selectedDate.day ? Colors.blue[50] : Colors.white,
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('E, MMM d').format(day),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...jobsForDay.map((job) => GestureDetector(
                          onTap: () => _showJobDetailsDialog(job),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(job['status']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              job['title'] ?? 'Job',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return const Scaffold(body: SizedBox());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Calendar'),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              setState(() => _viewMode = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'month', child: Text('Month View')),
              const PopupMenuItem(value: 'week', child: Text('Week View')),
              const PopupMenuItem(value: 'day', child: Text('Day View')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate =
                                      DateTime(_selectedDate.year, _selectedDate.month - 1);
                                });
                                _loadJobs();
                              },
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate =
                                      DateTime(_selectedDate.year, _selectedDate.month + 1);
                                });
                                _loadJobs();
                              },
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_viewMode == 'month') _buildMonthView(),
                        if (_viewMode == 'week') _buildWeekView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

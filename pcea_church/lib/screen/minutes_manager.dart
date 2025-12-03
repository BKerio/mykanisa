import 'package:flutter/material.dart';

/// COLORS
const primaryBlue = Color(0xFF1E2A78); // deep blue from logo
const flameRed = Color(0xFFE53935); // flame
const flameYellow = Color(0xFFFFC107); // fire top
const darkBlack = Colors.black;

// ===================== IN-MEMORY DATA MODELING =====================

class Meeting {
  String id;
  String title;
  String description;
  DateTime scheduledAt;

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledAt,
  });
}

class MinuteItem {
  String id;
  String meetingId;
  String title;
  int orderIndex;
  String? notes;

  MinuteItem({
    required this.id,
    required this.meetingId,
    required this.title,
    required this.orderIndex,
    this.notes,
  });
}

class Attendee {
  String id;
  String meetingId;
  String name;
  String status; // 'present', 'absent', 'apologies'

  Attendee({
    required this.id,
    required this.meetingId,
    required this.name,
    required this.status,
  });
}

class ActionPoint {
  String id;
  String meetingId;
  String description;
  String assignee;
  DateTime? dueDate;
  bool isDone;

  ActionPoint({
    required this.id,
    required this.meetingId,
    required this.description,
    required this.assignee,
    this.dueDate,
    this.isDone = false,
  });
}

// ===================== IN-MEMORY REPOSITORY (MOCK DATA ACCESS) =====================

class MinutesRepository {
  static final MinutesRepository _instance = MinutesRepository._internal();
  factory MinutesRepository() => _instance;
  MinutesRepository._internal();

  final List<Meeting> _meetings = [];
  final List<MinuteItem> _minuteItems = [];
  final List<Attendee> _attendees = [];
  final List<ActionPoint> _actionPoints = [];
  int _idCounter = 1;

  String _generateId() => 'id_${_idCounter++}';

  void initialize() {
    if (_meetings.isNotEmpty) return;

    // Add Meetings
    _meetings.add(
      Meeting(
        id: 'm1',
        title: 'Session Planning Meeting',
        description: 'Reviewing quarterly goals and finances.',
        scheduledAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );
    _meetings.add(
      Meeting(
        id: 'm2',
        title: 'Pastoral Committee Review',
        description: 'Discussing church outreach programs.',
        scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    );

    // Data for Meeting 2 (m2)
    _minuteItems.add(
      MinuteItem(
        id: 'mi1',
        meetingId: 'm2',
        title: 'Opening Prayer',
        orderIndex: 1,
        notes: 'Pastor led the opening prayer.',
      ),
    );
    _minuteItems.add(
      MinuteItem(
        id: 'mi2',
        meetingId: 'm2',
        title: 'Outreach Strategy',
        orderIndex: 2,
        notes: 'Agreed to launch Project Hope next month.',
      ),
    );

    _attendees.add(
      Attendee(
        id: 'a1',
        meetingId: 'm2',
        name: 'Elder Mwangi',
        status: 'present',
      ),
    );
    _attendees.add(
      Attendee(
        id: 'a2',
        meetingId: 'm2',
        name: 'Deaconess Anne',
        status: 'apologies',
      ),
    );

    _actionPoints.add(
      ActionPoint(
        id: 'ap1',
        meetingId: 'm2',
        description: 'Draft initial budget for Project Hope.',
        assignee: 'Elder Mwangi',
        dueDate: DateTime.now().add(const Duration(days: 14)),
        isDone: false,
      ),
    );
  }

  // --- Meeting CRUD ---
  Future<List<Meeting>> getMeetings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _meetings.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return _meetings;
  }

  Future<void> addMeeting(
    String title,
    String description,
    DateTime scheduledAt,
  ) async {
    _meetings.add(
      Meeting(
        id: _generateId(),
        title: title,
        description: description,
        scheduledAt: scheduledAt,
      ),
    );
  }

  // --- Minute Item CRUD ---
  Future<int> getNextMinuteOrder(String meetingId) async {
    final items = _minuteItems.where((i) => i.meetingId == meetingId).toList();
    if (items.isEmpty) return 1;
    return items.map((i) => i.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<List<MinuteItem>> getMinuteItems(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final items = _minuteItems.where((i) => i.meetingId == meetingId).toList();
    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  Future<void> addMinuteItem(
    String meetingId,
    String title,
    int orderIndex,
  ) async {
    _minuteItems.add(
      MinuteItem(
        id: _generateId(),
        meetingId: meetingId,
        title: title,
        orderIndex: orderIndex,
      ),
    );
  }

  Future<void> updateMinuteNotes(String itemId, String notes) async {
    final item = _minuteItems.firstWhere((i) => i.id == itemId);
    item.notes = notes;
  }

  // --- Attendee CRUD ---
  Future<List<Attendee>> getAttendees(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _attendees.where((a) => a.meetingId == meetingId).toList();
  }

  Future<void> addAttendee(String meetingId, String name, String status) async {
    _attendees.add(
      Attendee(
        id: _generateId(),
        meetingId: meetingId,
        name: name,
        status: status,
      ),
    );
  }

  Future<void> updateAttendeeStatus(String attendeeId, String status) async {
    final attendee = _attendees.firstWhere((a) => a.id == attendeeId);
    attendee.status = status;
  }

  // --- Action Point CRUD ---
  Future<List<ActionPoint>> getActionPoints(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _actionPoints.where((a) => a.meetingId == meetingId).toList();
  }

  Future<void> addActionPoint(
    String meetingId,
    String description,
    String assignee,
    DateTime? dueDate,
  ) async {
    _actionPoints.add(
      ActionPoint(
        id: _generateId(),
        meetingId: meetingId,
        description: description,
        assignee: assignee,
        dueDate: dueDate,
      ),
    );
  }

  Future<void> toggleActionDone(String actionId, bool current) async {
    final action = _actionPoints.firstWhere((a) => a.id == actionId);
    action.isDone = !current;
  }
}

final MinutesRepository repository = MinutesRepository();

// ===================== APPLICATION STARTUP =====================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  repository.initialize();
  runApp(const MeetingMinutesApp());
}

class LogoBadge extends StatelessWidget {
  final double size;
  final String tagline;
  final Color textColor;

  const LogoBadge({
    super.key,
    this.size = 40,
    this.tagline = 'FAITH · LOVE · HOPE',
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder for Logo image
    return Row(
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(color: flameYellow, shape: BoxShape.circle),
          child: Center(
            child: Icon(Icons.church, size: size * 0.6, color: primaryBlue),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          tagline,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// ===================== ROOT APP (Starting at Meeting List) =====================

class MeetingMinutesApp extends StatelessWidget {
  const MeetingMinutesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Faith · Love · Hope Minutes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: flameRed,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: flameRed,
          foregroundColor: Colors.white,
        ),
      ),
      // Start directly on the Meeting List Page
      home: const MeetingListPage(),
    );
  }
}

/// ===================== MEETING LIST PAGE =====================

class MeetingListPage extends StatefulWidget {
  const MeetingListPage({super.key});

  @override
  State<MeetingListPage> createState() => _MeetingListPageState();
}

class _MeetingListPageState extends State<MeetingListPage> {
  late Future<List<Meeting>> _futureMeetings;

  @override
  void initState() {
    super.initState();
    _futureMeetings = _loadMeetings();
  }

  Future<List<Meeting>> _loadMeetings() async {
    return repository.getMeetings();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureMeetings = _loadMeetings();
    });
  }

  void _openAddMeetingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddMeetingDialog(onCreated: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Placeholder for logo
            Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: flameYellow,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.church, size: 20, color: primaryBlue),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Church Minutes'),
          ],
        ),
      ),
      body: FutureBuilder<List<Meeting>>(
        future: _futureMeetings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading meetings: ${snapshot.error}'),
            );
          }
          final meetings = snapshot.data ?? [];

          if (meetings.isEmpty) {
            return const Center(
              child: Text('No meetings yet. Tap + to schedule one.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final m = meetings[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      m.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    subtitle: Text(
                      '${m.scheduledAt.toLocal()}'.split('.').first,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MeetingDetailPage(meeting: m),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMeetingDialog,
        icon: const Icon(Icons.add),
        label: const Text('Schedule meeting'),
      ),
    );
  }
}

/// Dialog to create / schedule a new meeting
class AddMeetingDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const AddMeetingDialog({super.key, required this.onCreated});

  @override
  State<AddMeetingDialog> createState() => _AddMeetingDialogState();
}

class _AddMeetingDialogState extends State<AddMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _scheduledAt = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _scheduledAt,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await repository.addMeeting(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _scheduledAt,
    );

    widget.onCreated();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Meeting'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Session 1, Elders Meeting...',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'When: ${_scheduledAt.toLocal()}'.split('.').first,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

/// ===================== MEETING DETAIL PAGE =====================

class MeetingDetailPage extends StatelessWidget {
  final Meeting meeting;

  const MeetingDetailPage({super.key, required this.meeting});

  String get meetingId => meeting.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(meeting.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: flameRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${meeting.scheduledAt.toLocal()}'.split('.').first,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OnboardingCard(meetingId: meetingId, meeting: meeting),
            const SizedBox(height: 16),
            MinutesAndActionsCard(meetingId: meetingId),
          ],
        ),
      ),
    );
  }
}

/// ===================== CARD 1: ONBOARD MEETING (Agenda) =====================

class OnboardingCard extends StatefulWidget {
  final String meetingId;
  final Meeting meeting;

  const OnboardingCard({
    super.key,
    required this.meetingId,
    required this.meeting,
  });

  @override
  State<OnboardingCard> createState() => _OnboardingCardState();
}

class _OnboardingCardState extends State<OnboardingCard> {
  late Future<List<MinuteItem>> _futureMinutes;

  @override
  void initState() {
    super.initState();
    _futureMinutes = _loadMinutes();
  }

  Future<List<MinuteItem>> _loadMinutes() async {
    return repository.getMinuteItems(widget.meetingId);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureMinutes = _loadMinutes();
    });
  }

  void _addMinuteItemDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          AddMinuteItemDialog(meetingId: widget.meetingId, onAdded: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: primaryBlue.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                LogoBadge(size: 36, tagline: 'Onboard Meeting'),
                Icon(Icons.playlist_add_check_rounded, color: flameYellow),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Add the agenda / minute items before the meeting starts.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<MinuteItem>>(
              future: _futureMinutes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: CircularProgressIndicator(color: flameYellow),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No agenda items yet. Add the topics you will discuss.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                return Column(
                  children: items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.brightness_1,
                            size: 10,
                            color: flameYellow,
                          ),
                          title: Text(
                            '${item.orderIndex}. ${item.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: flameYellow,
                  foregroundColor: darkBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _addMinuteItemDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add agenda / minute topic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== CARD 2: MINUTES & ACTIONS =====================

class MinutesAndActionsCard extends StatefulWidget {
  final String meetingId;

  const MinutesAndActionsCard({super.key, required this.meetingId});

  @override
  State<MinutesAndActionsCard> createState() => _MinutesAndActionsCardState();
}

class _MinutesAndActionsCardState extends State<MinutesAndActionsCard> {
  late Future<List<Attendee>> _futureAttendees;
  late Future<List<MinuteItem>> _futureMinutes;
  late Future<List<ActionPoint>> _futureActions;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _futureAttendees = repository.getAttendees(widget.meetingId);
      _futureMinutes = repository.getMinuteItems(widget.meetingId);
      _futureActions = repository.getActionPoints(widget.meetingId);
    });
  }

  void _addAttendeeDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          AddAttendeeDialog(meetingId: widget.meetingId, onAdded: _refreshAll),
    );
  }

  void _addActionDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          AddActionDialog(meetingId: widget.meetingId, onAdded: _refreshAll),
    );
  }

  void _editMinuteNotesDialog(MinuteItem item) {
    showDialog(
      context: context,
      builder: (_) => EditMinuteNotesDialog(item: item, onSaved: _refreshAll),
    );
  }

  Future<void> _changeStatus(String attendeeId, String newStatus) async {
    await repository.updateAttendeeStatus(attendeeId, newStatus);
    _refreshAll();
  }

  Future<void> _toggleDone(String id, bool current) async {
    await repository.toggleActionDone(id, current);
    _refreshAll();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'apologies':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE0E0E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                LogoBadge(
                  size: 36,
                  tagline: 'Minutes & Actions',
                  textColor: primaryBlue,
                ),
                Icon(Icons.edit_note, color: primaryBlue),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Mark attendance, capture notes for each agenda item,\n'
              'and record clear action points with owners.',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),

            /// Big action buttons (full width)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BigActionButton(
                  color: Colors.white,
                  icon: Icons.person_add_alt_1,
                  label: 'Add member',
                  subtitle: 'Add an attendee & status',
                  onTap: _addAttendeeDialog,
                ),
                const SizedBox(height: 10),
                _BigActionButton(
                  color: Colors.white,
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Minutes notes',
                  subtitle: 'Tap an agenda item below',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Scroll down and tap an agenda item to add notes.',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _BigActionButton(
                  color: Colors.white,
                  icon: Icons.flag,
                  label: 'Action point',
                  subtitle: 'Add a task & owner',
                  onTap: _addActionDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Attendees
            const Text(
              'Attendees',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<Attendee>>(
              future: _futureAttendees,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    ),
                  );
                }
                final attendees = snapshot.data ?? [];
                if (attendees.isEmpty) {
                  return const Text(
                    'No attendees yet. Use "Add member" above.',
                    style: TextStyle(color: Colors.black54),
                  );
                }
                return Column(
                  children: attendees.map((a) {
                    final color = _statusColor(a.status);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        foregroundColor: primaryBlue,
                        child: Text(
                          a.name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        a.name,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) => _changeStatus(a.id, val),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'present',
                            child: Text('Present'),
                          ),
                          PopupMenuItem(value: 'absent', child: Text('Absent')),
                          PopupMenuItem(
                            value: 'apologies',
                            child: Text('Absent with apologies'),
                          ),
                        ],
                        child: Chip(
                          label: Text(a.status),
                          labelStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: color.withOpacity(0.1),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),

            /// Minutes list (agenda items + notes)
            const Text(
              'Minutes (agenda items & notes)',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<MinuteItem>>(
              future: _futureMinutes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Text(
                    'No agenda items. Add them in the blue card above.',
                    style: TextStyle(color: Colors.black54),
                  );
                }
                return Column(
                  children: items.map((item) {
                    final notes = item.notes ?? '';
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          '${item.orderIndex}. ${item.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        subtitle: notes.isNotEmpty
                            ? Text(
                                notes,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            : const Text('Tap to add minutes for this item'),
                        onTap: () => _editMinuteNotesDialog(item),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),

            /// Action points
            const Text(
              'Action points',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<ActionPoint>>(
              future: _futureActions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    ),
                  );
                }
                final actions = snapshot.data ?? [];
                if (actions.isEmpty) {
                  return const Text(
                    'No action points yet. Use the "Action point" button above.',
                    style: TextStyle(color: Colors.black54),
                  );
                }
                return Column(
                  children: actions.map((a) {
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        value: a.isDone,
                        onChanged: (_) => _toggleDone(a.id, a.isDone),
                        title: Text(
                          a.description,
                          style: TextStyle(
                            decoration: a.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text('Owner(s): ${a.assignee}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Big expressive buttons (full-width)

class _BigActionButton extends StatelessWidget {
  final Color color;
  final Color? foregroundColor;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? primaryBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              offset: Offset(0, 3),
              color: Colors.black26,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: fg.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== SHARED MEETING DIALOGS =====================

class AddAttendeeDialog extends StatefulWidget {
  final String meetingId;
  final VoidCallback onAdded;

  const AddAttendeeDialog({
    super.key,
    required this.meetingId,
    required this.onAdded,
  });

  @override
  State<AddAttendeeDialog> createState() => _AddAttendeeDialogState();
}

class _AddAttendeeDialogState extends State<AddAttendeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _status = 'present';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await repository.addAttendee(
      widget.meetingId,
      _nameController.text.trim(),
      _status,
    );

    widget.onAdded();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'present', child: Text('Present')),
                DropdownMenuItem(value: 'absent', child: Text('Absent')),
                DropdownMenuItem(
                  value: 'apologies',
                  child: Text('Absent with apologies'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Auto-numbered minute items
class AddMinuteItemDialog extends StatefulWidget {
  final String meetingId;
  final VoidCallback onAdded;

  const AddMinuteItemDialog({
    super.key,
    required this.meetingId,
    required this.onAdded,
  });

  @override
  State<AddMinuteItemDialog> createState() => _AddMinuteItemDialogState();
}

class _AddMinuteItemDialogState extends State<AddMinuteItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final nextOrder = await repository.getNextMinuteOrder(widget.meetingId);

    await repository.addMinuteItem(
      widget.meetingId,
      _titleController.text.trim(),
      nextOrder,
    );

    widget.onAdded();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add agenda / minute item'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Topic',
            hintText: 'e.g. Finance report, Outreach plans...',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class EditMinuteNotesDialog extends StatefulWidget {
  final MinuteItem item;
  final VoidCallback onSaved;

  const EditMinuteNotesDialog({
    super.key,
    required this.item,
    required this.onSaved,
  });

  @override
  State<EditMinuteNotesDialog> createState() => _EditMinuteNotesDialogState();
}

class _EditMinuteNotesDialogState extends State<EditMinuteNotesDialog> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await repository.updateMinuteNotes(
      widget.item.id,
      _notesController.text.trim(),
    );
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Notes: ${widget.item.title}'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _notesController,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Write minutes here...'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Action dialog with member tagging (multi-select)
class AddActionDialog extends StatefulWidget {
  final String meetingId;
  final VoidCallback onAdded;

  const AddActionDialog({
    super.key,
    required this.meetingId,
    required this.onAdded,
  });

  @override
  State<AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;

  late Future<List<Attendee>> _futureAttendees;
  final List<String> _selectedMembers = [];

  @override
  void initState() {
    super.initState();
    _futureAttendees = repository.getAttendees(widget.meetingId);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (date == null) return;
    setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one assignee.')),
      );
      return;
    }

    await repository.addActionPoint(
      widget.meetingId,
      _descriptionController.text.trim(),
      _selectedMembers.join(', '),
      _dueDate,
    );

    widget.onAdded();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add action point'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'What needs to be done?',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'Assign to members',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              FutureBuilder<List<Attendee>>(
                future: _futureAttendees,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final attendees = snapshot.data ?? [];
                  if (attendees.isEmpty) {
                    return const Text(
                      'No attendees recorded for this meeting yet.',
                      style: TextStyle(color: Colors.black54),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: attendees.map((a) {
                      final name = a.name;
                      final selected = _selectedMembers.contains(name);
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedMembers.add(name);
                            } else {
                              _selectedMembers.remove(name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'No due date'
                          : 'Due: ${_dueDate!.toLocal()}'.split(' ').first,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick due date'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

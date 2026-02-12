# دليل شرح كل الفانكشنز في مشروع Taskatk 📚

## الفهرس
1. [main.dart](#1-maindart)
2. [Screens](#2-screens)
3. [Services](#3-services)
4. [Models](#4-models)
5. [Widgets](#5-widgets)
6. [Helpers](#6-helpers)

---

# 1. main.dart

## `main()`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```
**الشرح:**
- `WidgetsFlutterBinding.ensureInitialized()` → لازم تتنادى قبل أي async operation في الـ main
- `Firebase.initializeApp()` → بتهيئ Firebase عشان نقدر نستخدم Auth و Firestore و Storage
- `runApp()` → بتشغل التطبيق وبتاخد الـ root widget

---

# 2. Screens

---

## 2.1 splash_screen.dart

### `initState()`
```dart
@override
void initState() {
  super.initState();
  Future.delayed(const Duration(seconds: 3), _navigateToNextScreen);
}
```
**الشرح:**
- بتتنادى أول ما الـ widget يتعمله initialize
- بتعمل delay 3 ثواني وبعدين بتنادي `_navigateToNextScreen`

---

### `_navigateToNextScreen()`
```dart
void _navigateToNextScreen() {
  final user = FirebaseAuth.instance.currentUser;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => user != null ? const HomeScreen() : const LoginScreen(),
    ),
  );
}
```
**الشرح:**
- `FirebaseAuth.instance.currentUser` → بتجيب اليوزر الحالي لو موجود
- `Navigator.pushReplacement` → بتروح للشاشة الجديدة وبتشيل الـ Splash من الـ stack
- لو اليوزر موجود → HomeScreen
- لو مفيش يوزر → LoginScreen

---

## 2.2 login_screen.dart

### `_login()`
```dart
Future<void> _login() async {
  // 1. التحقق من صحة المدخلات
  if (!_formKey.currentState!.validate()) return;

  // 2. تفعيل حالة التحميل
  setState(() => _isLoading = true);

  // 3. محاولة تسجيل الدخول
  final result = await _authService.signIn(
    _emailController.text.trim(),
    _passwordController.text,
  );

  // 4. إيقاف حالة التحميل
  setState(() => _isLoading = false);

  // 5. التعامل مع النتيجة
  if (result.isSuccess) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? 'Login failed')),
    );
  }
}
```
**الشرح:**
- `_formKey.currentState!.validate()` → بتتحقق من كل الـ validators في الـ Form
- `setState(() => _isLoading = true)` → بتغير الـ state عشان يظهر loading
- `_authService.signIn()` → بتنادي Firebase Auth لتسجيل الدخول
- `Navigator.pushReplacement()` → بتروح للـ HomeScreen وبتشيل Login من الـ stack

---

### `_togglePasswordVisibility()`
```dart
void _togglePasswordVisibility() {
  setState(() => _isPasswordVisible = !_isPasswordVisible);
}
```
**الشرح:**
- بتعكس قيمة `_isPasswordVisible`
- الـ TextField بيستخدم القيمة دي في `obscureText`

---

### `dispose()`
```dart
@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}
```
**الشرح:**
- مهم جداً تنضف الـ controllers لما الـ widget يتشال من الـ tree
- بيمنع memory leaks

---

## 2.3 register_screen.dart

### `_register()`
```dart
Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final result = await _authService.signUp(
    _emailController.text.trim(),
    _passwordController.text,
    _nameController.text.trim(),
  );

  setState(() => _isLoading = false);

  if (result.isSuccess) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } else {
    _showError(result.errorMessage ?? 'Registration failed');
  }
}
```
**الشرح:**
- نفس flow الـ login بس بتستخدم `signUp` بدل `signIn`
- بتاخد الاسم كمان وبتحفظه في Firebase

---

### `_validatePassword(String? value)`
```dart
String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null; // صحيح
}
```
**الشرح:**
- Validator بيرجع `null` لو القيمة صحيحة
- بيرجع String فيها رسالة الخطأ لو في مشكلة

---

### `_validateConfirmPassword(String? value)`
```dart
String? _validateConfirmPassword(String? value) {
  if (value != _passwordController.text) {
    return 'Passwords do not match';
  }
  return null;
}
```
**الشرح:**
- بتقارن الباسورد التاني بالأول
- لازم يكونوا متطابقين

---

## 2.4 home_screen.dart

### `initState()`
```dart
@override
void initState() {
  super.initState();
  _searchController.addListener(_onSearchChanged);
  _loadStreakData();
}
```
**الشرح:**
- `addListener` → كل ما الـ search text يتغير، هينادي `_onSearchChanged`
- `_loadStreakData()` → بتجيب بيانات الـ Streak من الـ service

---

### `_loadStreakData()`
```dart
Future<void> _loadStreakData() async {
  final streakData = await _streakService.getStreakData();
  if (mounted) {
    setState(() => _streakData = streakData);
  }
}
```
**الشرح:**
- `await _streakService.getStreakData()` → بتجيب الـ streak من SharedPreferences
- `if (mounted)` → مهم! بتتأكد إن الـ widget لسه موجود قبل ما تعمل setState
- لو الـ widget اتشال وعملت setState هيحصل error

---

### `_onSearchChanged()`
```dart
void _onSearchChanged() {
  setState(() {
    _searchQuery = _searchController.text.toLowerCase();
  });
}
```
**الشرح:**
- بتتنادى كل ما اليوزر يكتب في الـ search
- `toLowerCase()` → عشان البحث يكون case-insensitive

---

### `_filterTasks(List<TaskModel> tasks)`
```dart
List<TaskModel> _filterTasks(List<TaskModel> tasks) {
  return tasks.where((task) {
    // 1. فلتر البحث
    if (_searchQuery.isNotEmpty) {
      if (!task.title.toLowerCase().contains(_searchQuery) &&
          !(task.description?.toLowerCase().contains(_searchQuery) ?? false)) {
        return false;
      }
    }

    // 2. فلتر التاريخ
    switch (_dateFilter) {
      case 'Today':
        if (!task.isToday) return false;
        break;
      case 'Upcoming':
        if (!task.isUpcoming) return false;
        break;
      case 'Completed':
        if (!task.isCompleted) return false;
        break;
      case 'Pick Date':
        if (_selectedDateFilter != null) {
          // مقارنة التواريخ
        }
        break;
    }

    // 3. فلتر الأولوية
    if (_priorityFilter != null && task.priority != _priorityFilter) {
      return false;
    }

    // 4. فلتر الفئة
    if (_categoryFilter != null && task.category != _categoryFilter) {
      return false;
    }

    return true;
  }).toList()
    ..sort((a, b) {
      // ترتيب: الأولوية العالية أولاً، ثم التاريخ
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.dateTime.compareTo(b.dateTime);
    });
}
```
**الشرح:**
- `where()` → بتفلتر الـ list وبترجع بس العناصر اللي بترجع true
- `..sort()` → cascade operator، بتعمل sort على نفس الـ list
- الـ sort بيرتب:
  - أولاً: بالأولوية (10 قبل 1)
  - ثانياً: بالتاريخ (الأقرب أولاً)

---

### `_addTask(Set<int> usedPriorities)`
```dart
Future<void> _addTask(Set<int> usedPriorities) async {
  // 1. فتح الـ Bottom Sheet وانتظار النتيجة
  final task = await AddTaskBottomSheet.show(
    context,
    usedPriorities: usedPriorities,
  );

  // 2. لو اليوزر أضاف مهمة
  if (task != null) {
    final result = await _taskService.createTask(task);

    // 3. لو في error
    if (mounted && !result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed')),
      );
    }
  }
}
```
**الشرح:**
- `AddTaskBottomSheet.show()` → static method بتفتح الـ bottom sheet
- بترجع `TaskModel` لو اليوزر أضاف مهمة، أو `null` لو cancel
- `usedPriorities` → الأولويات المستخدمة عشان نقفلها

---

### `_toggleTaskComplete(TaskModel task)`
```dart
Future<void> _toggleTaskComplete(TaskModel task) async {
  // 1. تغيير حالة المهمة في Firebase
  await _taskService.toggleTaskCompletion(task);

  // 2. تحديث الـ Streak لو المهمة اتكملت
  if (!task.isCompleted) {
    final updatedStreak = await _streakService.onTaskCompleted(_allTasks);
    if (mounted) {
      setState(() => _streakData = updatedStreak);
    }
  }
}
```
**الشرح:**
- `toggleTaskCompletion` → بتعكس حالة الـ isCompleted
- لو المهمة كانت غير مكتملة (يعني هتكمل دلوقتي) → بنحدث الـ Streak

---

### `_openTaskDetail(TaskModel task, Set<int> usedPriorities)`
```dart
Future<void> _openTaskDetail(TaskModel task, Set<int> usedPriorities) async {
  // 1. فتح شاشة التفاصيل وانتظار النتيجة
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (context) => TaskDetailScreen(
        task: task,
        usedPriorities: usedPriorities,
      ),
    ),
  );

  // 2. التعامل مع النتيجة
  if (result != null && mounted) {
    final action = result['action'] as String;
    final updatedTask = result['task'] as TaskModel;

    if (action == 'delete') {
      await _taskService.deleteTask(updatedTask.id!);
    } else if (action == 'update') {
      await _taskService.updateTask(updatedTask);
    }
  }
}
```
**الشرح:**
- `Navigator.push<Map<String, dynamic>>` → بتفتح شاشة وبتستنى ترجع Map
- النتيجة فيها:
  - `action`: 'delete' أو 'update'
  - `task`: المهمة المعدلة

---

### `_pickFilterDate()`
```dart
Future<void> _pickFilterDate() async {
  final date = await showDatePicker(
    context: context,
    initialDate: _selectedDateFilter ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      );
    },
  );

  if (date != null && mounted) {
    setState(() {
      _selectedDateFilter = date;
      _dateFilter = 'Pick Date';
    });
  }
}
```
**الشرح:**
- `showDatePicker()` → بتفتح date picker dialog
- `builder` → بنغير الثيم عشان يكون بلون التطبيق
- لو اليوزر اختار تاريخ → بنحفظه ونغير الفلتر لـ 'Pick Date'

---

### `_buildStreakBanner(ResponsiveHelper responsive)`
```dart
Widget _buildStreakBanner(ResponsiveHelper responsive) {
  // لو مفيش streak أو الـ streak صفر → مش هنعرض حاجة
  if (_streakData == null || _streakData!.currentStreak == 0) {
    return const SizedBox.shrink();
  }

  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.local_fire_department),
        Text('${_streakData!.currentStreak} Day Streak!'),
        Text('Best: ${_streakData!.longestStreak}'),
      ],
    ),
  );
}
```
**الشرح:**
- `SizedBox.shrink()` → widget فاضي مبياخدش مساحة
- `LinearGradient` → تدرج لوني من البرتقالي للأحمر

---

### `_showCategoryFilterMenu(ResponsiveHelper responsive)`
```dart
void _showCategoryFilterMenu(ResponsiveHelper responsive) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // عنوان
          Text('Filter by Category'),

          // خيار "الكل"
          ListTile(
            title: Text('All Categories'),
            trailing: _categoryFilter == null ? Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _categoryFilter = null);
            },
          ),

          // كل الفئات
          ...TaskCategory.values.map((category) {
            return ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              title: Text(category.label),
              onTap: () {
                Navigator.pop(context);
                setState(() => _categoryFilter = category);
              },
            );
          }),
        ],
      ),
    ),
  );
}
```
**الشرح:**
- `showModalBottomSheet` → بتفتح bottom sheet
- `mainAxisSize: MainAxisSize.min` → الـ Column تاخد أقل مساحة ممكنة
- `...TaskCategory.values.map()` → spread operator، بيفرد الـ list جوه الـ Column

---

## 2.5 statistics_screen.dart

### `_loadData()`
```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);

  // جلب البيانات بالتوازي
  final results = await Future.wait([
    _taskService.getStatistics(),
    _streakService.getStreakData(),
  ]);

  if (mounted) {
    setState(() {
      _statistics = results[0] as TaskStatistics;
      _streakData = results[1] as StreakData;
      _isLoading = false;
    });
  }
}
```
**الشرح:**
- `Future.wait()` → بتشغل كل الـ Futures بالتوازي وبتستنى كلهم يخلصوا
- أسرع من إنك تستنى كل واحد لوحده
- `results[0]` و `results[1]` → النتايج بنفس ترتيب الـ Futures

---

### `_buildWeeklyChart(ResponsiveHelper responsive)`
```dart
Widget _buildWeeklyChart(ResponsiveHelper responsive) {
  return BarChart(
    BarChartData(
      barGroups: List.generate(7, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: (_statistics?.weeklyData[index] ?? 0).toDouble(),
              color: AppColors.primary,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return Text(days[value.toInt()]);
            },
          ),
        ),
      ),
    ),
  );
}
```
**الشرح:**
- `BarChart` → من مكتبة fl_chart
- `List.generate(7, ...)` → بتعمل list من 7 عناصر (أيام الأسبوع)
- `BarChartGroupData` → بيانات عمود واحد
- `getTitlesWidget` → بترجع الـ widget اللي هيظهر تحت كل عمود

---

### `_buildCategoryBreakdown(ResponsiveHelper responsive)`
```dart
Widget _buildCategoryBreakdown(ResponsiveHelper responsive) {
  final categoryData = _statistics?.categoryData ?? {};
  final total = categoryData.values.fold(0, (sum, count) => sum + count);

  if (total == 0) {
    return Text('No completed tasks yet');
  }

  return PieChart(
    PieChartData(
      sections: categoryData.entries.map((entry) {
        final percentage = (entry.value / total * 100);
        return PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          color: entry.key.color,
          radius: 80,
        );
      }).toList(),
    ),
  );
}
```
**الشرح:**
- `fold()` → بتجمع كل القيم (مجموع المهام المكتملة)
- `PieChart` → دائرة بيانية
- `percentage.toStringAsFixed(0)` → بتحول لـ string بدون أرقام عشرية

---

## 2.6 profile_screen.dart

### `_pickAndUploadImage()`
```dart
Future<void> _pickAndUploadImage() async {
  // 1. عرض خيارات اختيار الصورة
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.camera_alt),
          title: Text('Take a Photo'),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          leading: Icon(Icons.photo_library),
          title: Text('Choose from Gallery'),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
        if (_profile?.photoUrl != null)
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Remove Photo'),
            onTap: () => Navigator.pop(context, null),
          ),
      ],
    ),
  );

  // 2. لو اختار حذف الصورة
  if (source == null && _profile?.photoUrl != null) {
    setState(() => _isUploading = true);
    final result = await _profileService.deleteProfileImage();
    setState(() => _isUploading = false);
    if (result.isSuccess) _loadData();
    return;
  }

  if (source == null) return;

  // 3. اختيار الصورة
  final pickedFile = await _imagePicker.pickImage(
    source: source,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 80,
  );

  if (pickedFile == null) return;

  // 4. رفع الصورة
  setState(() => _isUploading = true);
  final result = await _profileService.uploadProfileImage(File(pickedFile.path));
  setState(() => _isUploading = false);

  if (result.isSuccess) {
    _loadData();
  } else {
    _showError(result.errorMessage ?? 'Failed to upload');
  }
}
```
**الشرح:**
- `showModalBottomSheet<ImageSource>` → بترجع ImageSource (camera/gallery) أو null
- `_imagePicker.pickImage()` → بتفتح الكاميرا أو المعرض
- `maxWidth/maxHeight` → بتصغر الصورة عشان الرفع يكون أسرع
- `imageQuality: 80` → جودة 80% (توفير في الحجم)

---

### `_editDisplayName()`
```dart
Future<void> _editDisplayName() async {
  final controller = TextEditingController(text: _profile?.displayName ?? '');

  // 1. عرض dialog لتعديل الاسم
  final newName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: 'Enter your name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text('Save'),
        ),
      ],
    ),
  );

  // 2. لو cancel أو فاضي
  if (newName == null || newName.isEmpty) return;

  // 3. تحديث الاسم
  final result = await _profileService.updateDisplayName(newName);
  if (result.isSuccess) {
    _loadData();
  } else {
    _showError(result.errorMessage ?? 'Failed');
  }
}
```
**الشرح:**
- `showDialog<String>` → بترجع الاسم الجديد أو null
- `controller.text.trim()` → بتشيل المسافات من الأول والآخر
- `Navigator.pop(context, value)` → بتقفل الـ dialog وبترجع قيمة

---

### `_logout()`
```dart
Future<void> _logout() async {
  // 1. تأكيد الخروج
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Logout'),
        ),
      ],
    ),
  );

  // 2. لو مأكدش
  if (confirm != true) return;

  // 3. تسجيل الخروج
  await _authService.signOut();

  // 4. الرجوع لشاشة Login
  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
```
**الشرح:**
- `showDialog<bool>` → بترجع true لو أكد، false لو cancel
- `Navigator.pushAndRemoveUntil(..., (route) => false)` → بتروح للشاشة الجديدة وبتشيل كل الشاشات اللي قبلها

---

## 2.7 task_detail_screen.dart

### `_saveChanges()`
```dart
void _saveChanges() {
  if (_titleController.text.trim().isEmpty) {
    _showError('Title is required');
    return;
  }

  // إنشاء المهمة المعدلة
  final updatedTask = widget.task.copyWith(
    title: _titleController.text.trim(),
    description: _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim(),
    dateTime: DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ),
    priority: _selectedPriority,
    category: _selectedCategory,
    recurrence: _selectedRecurrence,
  );

  // إرجاع النتيجة
  Navigator.pop(context, {
    'action': 'update',
    'task': updatedTask,
  });
}
```
**الشرح:**
- `copyWith()` → بتعمل نسخة من المهمة مع تعديل القيم المحددة
- `Navigator.pop(context, {...})` → بترجع Map للشاشة اللي قبلها

---

### `_deleteTask()`
```dart
Future<void> _deleteTask() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Task'),
      content: Text('Are you sure you want to delete this task?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Delete'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    Navigator.pop(context, {
      'action': 'delete',
      'task': widget.task,
    });
  }
}
```
**الشرح:**
- بتسأل اليوزر للتأكيد
- لو أكد → بترجع action: 'delete'

---

# 3. Services

---

## 3.1 auth_service.dart

### `signIn(String email, String password)`
```dart
Future<AuthResult> signIn(String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AuthResult.success();
  } on FirebaseAuthException catch (e) {
    return AuthResult.failure(_getErrorMessage(e.code));
  } catch (e) {
    return AuthResult.failure('An error occurred');
  }
}
```
**الشرح:**
- `signInWithEmailAndPassword` → Firebase method لتسجيل الدخول
- `FirebaseAuthException` → بتمسك أخطاء Firebase المحددة
- `_getErrorMessage(e.code)` → بتحول كود الخطأ لرسالة مفهومة

---

### `signUp(String email, String password, String name)`
```dart
Future<AuthResult> signUp(String email, String password, String name) async {
  try {
    // 1. إنشاء الحساب
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. تحديث اسم المستخدم
    await credential.user?.updateDisplayName(name);

    // 3. إنشاء document في Firestore
    await _firestore.collection('users').doc(credential.user?.uid).set({
      'displayName': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return AuthResult.success();
  } on FirebaseAuthException catch (e) {
    return AuthResult.failure(_getErrorMessage(e.code));
  }
}
```
**الشرح:**
- `createUserWithEmailAndPassword` → بتعمل حساب جديد
- `updateDisplayName` → بتحفظ الاسم في Firebase Auth
- `FieldValue.serverTimestamp()` → بتحط الوقت من السيرفر (أدق)

---

### `signOut()`
```dart
Future<void> signOut() async {
  await _auth.signOut();
}
```
**الشرح:**
- بتسجل خروج اليوزر من Firebase Auth
- بعدها `currentUser` هيكون null

---

### `_getErrorMessage(String code)`
```dart
String _getErrorMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'No user found with this email';
    case 'wrong-password':
      return 'Wrong password';
    case 'email-already-in-use':
      return 'Email is already registered';
    case 'weak-password':
      return 'Password is too weak';
    case 'invalid-email':
      return 'Invalid email address';
    default:
      return 'Authentication failed';
  }
}
```
**الشرح:**
- بتحول أكواد Firebase لرسائل مفهومة للمستخدم

---

## 3.2 task_service.dart

### `createTask(TaskModel task)`
```dart
Future<TaskResult> createTask(TaskModel task) async {
  try {
    if (_userId == null) {
      return TaskResult.failure('User not logged in');
    }

    // إضافة المهمة لـ Firestore
    final docRef = await _tasksCollection.add(task.toFirestore());

    // إنشاء نسخة مع الـ ID
    final createdTask = task.copyWith(id: docRef.id);

    return TaskResult.success(createdTask);
  } catch (e) {
    return TaskResult.failure('Failed to create task: $e');
  }
}
```
**الشرح:**
- `_tasksCollection.add()` → بتضيف document جديد وبترجع reference
- `docRef.id` → الـ ID اللي Firebase عمله للـ document
- `copyWith(id: docRef.id)` → بنضيف الـ ID للمهمة

---

### `getTasksStream()`
```dart
Stream<List<TaskModel>> getTasksStream() {
  if (_userId == null) return Stream.value([]);

  return _tasksCollection
      .orderBy('dateTime', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  });
}
```
**الشرح:**
- `Stream.value([])` → بترجع stream فيه list فاضية
- `snapshots()` → بترجع Stream بيتحدث كل ما البيانات تتغير (real-time)
- `map()` → بتحول الـ QuerySnapshot لـ List<TaskModel>

---

### `toggleTaskCompletion(TaskModel task)`
```dart
Future<TaskResult> toggleTaskCompletion(TaskModel task) async {
  try {
    final isNowCompleted = !task.isCompleted;
    final completedAt = isNowCompleted ? DateTime.now() : null;

    // تحديث في Firestore
    await _tasksCollection.doc(task.id).update({
      'isCompleted': isNowCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt)
          : null,
    });

    // لو المهمة اتكملت ومتكررة → إنشاء المهمة التالية
    if (isNowCompleted && task.recurrence != TaskRecurrence.none) {
      await _createNextOccurrence(task);
    }

    return TaskResult.success(task.copyWith(
      isCompleted: isNowCompleted,
      completedAt: completedAt,
    ));
  } catch (e) {
    return TaskResult.failure('Failed: $e');
  }
}
```
**الشرح:**
- `!task.isCompleted` → بتعكس القيمة
- `Timestamp.fromDate()` → بتحول DateTime لـ Firestore Timestamp
- `_createNextOccurrence()` → للمهام المتكررة

---

### `_createNextOccurrence(TaskModel task)`
```dart
Future<void> _createNextOccurrence(TaskModel task) async {
  final nextDate = task.getNextOccurrence();
  if (nextDate == null) return;

  final newTask = TaskModel(
    title: task.title,
    description: task.description,
    dateTime: nextDate,
    priority: task.priority,
    isCompleted: false,
    category: task.category,
    recurrence: task.recurrence,
  );

  await createTask(newTask);
}
```
**الشرح:**
- `getNextOccurrence()` → بتحسب التاريخ التالي حسب نوع التكرار
- بتعمل مهمة جديدة بنفس البيانات بس بتاريخ جديد

---

### `getStatistics()`
```dart
Future<TaskStatistics> getStatistics() async {
  try {
    final snapshot = await _tasksCollection.get();
    final tasks = snapshot.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList();

    // حساب بداية الأسبوع
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    // تجهيز المتغيرات
    int completedThisWeek = 0;
    final weeklyData = <int, int>{};
    final categoryData = <TaskCategory, int>{};

    // تهيئة القيم الافتراضية
    for (int i = 0; i < 7; i++) {
      weeklyData[i] = 0;
    }
    for (final category in TaskCategory.values) {
      categoryData[category] = 0;
    }

    // حساب الإحصائيات
    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        categoryData[task.category] =
            (categoryData[task.category] ?? 0) + 1;

        if (task.completedAt!.isAfter(weekStart)) {
          completedThisWeek++;
          final dayOfWeek = task.completedAt!.weekday - 1;
          weeklyData[dayOfWeek] = (weeklyData[dayOfWeek] ?? 0) + 1;
        }
      }
    }

    return TaskStatistics(
      totalTasks: tasks.length,
      completedTasks: tasks.where((t) => t.isCompleted).length,
      pendingTasks: tasks.where((t) => !t.isCompleted).length,
      completedThisWeek: completedThisWeek,
      weeklyData: weeklyData,
      categoryData: categoryData,
    );
  } catch (e) {
    return TaskStatistics.empty();
  }
}
```
**الشرح:**
- `snapshot.get()` → بتجيب كل الـ documents مرة واحدة
- `now.weekday` → رقم اليوم في الأسبوع (1 = الإثنين)
- بتحسب عدد المهام المكتملة لكل يوم ولكل فئة

---

### `getUsedPriorities(List<TaskModel> tasks)`
```dart
Set<int> getUsedPriorities(List<TaskModel> tasks) {
  return tasks
      .where((task) => !task.isCompleted)
      .map((task) => task.priority)
      .toSet();
}
```
**الشرح:**
- `where()` → بتفلتر المهام غير المكتملة بس
- `map()` → بتاخد الـ priority من كل مهمة
- `toSet()` → بتحول لـ Set (بدون تكرار)

---

## 3.3 streak_service.dart

### `getStreakData()`
```dart
Future<StreakData> getStreakData() async {
  final prefs = await SharedPreferences.getInstance();

  final currentStreak = prefs.getInt('current_streak') ?? 0;
  final longestStreak = prefs.getInt('longest_streak') ?? 0;
  final lastDateStr = prefs.getString('last_completion_date');

  DateTime? lastCompletionDate;
  if (lastDateStr != null) {
    lastCompletionDate = DateTime.parse(lastDateStr);
  }

  final badges = _getDefaultBadges().map((badge) {
    return badge.copyWith(
      isUnlocked: currentStreak >= badge.requiredStreak ||
          longestStreak >= badge.requiredStreak,
    );
  }).toList();

  return StreakData(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastCompletionDate: lastCompletionDate,
    badges: badges,
  );
}
```
**الشرح:**
- `SharedPreferences.getInstance()` → بتجيب instance للتخزين المحلي
- `getInt()`, `getString()` → بتجيب القيم المحفوظة
- البادجات بتتفتح لو الـ streak وصل للرقم المطلوب

---

### `onTaskCompleted(List<TaskModel> allTasks)`
```dart
Future<StreakData> onTaskCompleted(List<TaskModel> allTasks) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // جلب آخر تاريخ إكمال
  final lastDateStr = prefs.getString('last_completion_date');
  DateTime? lastDate;
  if (lastDateStr != null) {
    lastDate = DateTime.parse(lastDateStr);
  }

  int currentStreak = prefs.getInt('current_streak') ?? 0;
  int longestStreak = prefs.getInt('longest_streak') ?? 0;

  if (lastDate == null) {
    // أول مهمة
    currentStreak = 1;
  } else {
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final difference = today.difference(lastDay).inDays;

    if (difference == 0) {
      // نفس اليوم - مش هنزود الـ streak
    } else if (difference == 1) {
      // يوم جديد متتالي
      currentStreak++;
    } else {
      // فات أكتر من يوم - الـ streak يبدأ من جديد
      currentStreak = 1;
    }
  }

  // تحديث أفضل streak
  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  // حفظ القيم
  await prefs.setInt('current_streak', currentStreak);
  await prefs.setInt('longest_streak', longestStreak);
  await prefs.setString('last_completion_date', today.toIso8601String());

  return getStreakData();
}
```
**الشرح:**
- `difference.inDays` → الفرق بالأيام
- لو الفرق 0 → نفس اليوم، مش بنزود
- لو الفرق 1 → يوم متتالي، بنزود الـ streak
- لو أكتر من 1 → الـ streak اتكسر، بنبدأ من 1

---

### `_getDefaultBadges()`
```dart
List<AchievementBadge> _getDefaultBadges() {
  return [
    AchievementBadge(
      id: 'starter',
      title: 'Getting Started',
      description: 'Complete tasks for 3 days',
      icon: '⭐',
      requiredStreak: 3,
    ),
    AchievementBadge(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Complete tasks for 7 days',
      icon: '🔥',
      requiredStreak: 7,
    ),
    // ... باقي البادجات
  ];
}
```
**الشرح:**
- بترجع list بالبادجات الافتراضية
- كل بادج له اسم ووصف وأيقونة وعدد الأيام المطلوبة

---

## 3.4 profile_service.dart

### `getProfile()`
```dart
Future<UserProfile?> getProfile() async {
  try {
    final user = _auth.currentUser;
    if (user == null) return null;

    // محاولة جلب من Firestore
    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }

    // لو مفيش document، نرجع من Auth
    return UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  } catch (e) {
    return null;
  }
}
```
**الشرح:**
- أولاً بنحاول نجيب من Firestore (فيها بيانات أكتر)
- لو مفيش، بنرجع البيانات الأساسية من Firebase Auth

---

### `uploadProfileImage(File imageFile)`
```dart
Future<ProfileResult> uploadProfileImage(File imageFile) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      return ProfileResult.failure('Not logged in');
    }

    // 1. رفع الصورة لـ Storage
    final ref = _storage.ref().child('profile_images/${user.uid}/profile.jpg');
    await ref.putFile(imageFile);

    // 2. جلب الـ URL
    final downloadUrl = await ref.getDownloadURL();

    // 3. تحديث في Auth
    await user.updatePhotoURL(downloadUrl);

    // 4. تحديث في Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ProfileResult.success();
  } catch (e) {
    return ProfileResult.failure('Failed to upload: $e');
  }
}
```
**الشرح:**
- `ref.putFile()` → بترفع الملف لـ Firebase Storage
- `ref.getDownloadURL()` → بتجيب الـ URL العام للصورة
- بنحدث في Auth و Firestore عشان البيانات تكون متزامنة

---

### `updateDisplayName(String displayName)`
```dart
Future<ProfileResult> updateDisplayName(String displayName) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      return ProfileResult.failure('Not logged in');
    }

    // تحديث في Auth
    await user.updateDisplayName(displayName);

    // تحديث في Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ProfileResult.success();
  } catch (e) {
    return ProfileResult.failure('Failed: $e');
  }
}
```
**الشرح:**
- `updateDisplayName()` → بتحدث الاسم في Firebase Auth
- بنحدث في Firestore كمان عشان البيانات تكون متسقة

---

# 4. Models

---

## 4.1 task_model.dart

### `TaskModel.fromFirestore(DocumentSnapshot doc)`
```dart
factory TaskModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return TaskModel(
    id: doc.id,
    title: data['title'] ?? '',
    description: data['description'],
    dateTime: (data['dateTime'] as Timestamp).toDate(),
    priority: data['priority'] ?? 1,
    isCompleted: data['isCompleted'] ?? false,
    completedAt: data['completedAt'] != null
        ? (data['completedAt'] as Timestamp).toDate()
        : null,
    category: TaskCategory.values.firstWhere(
      (c) => c.name == data['category'],
      orElse: () => TaskCategory.personal,
    ),
    recurrence: TaskRecurrence.values.firstWhere(
      (r) => r.name == data['recurrence'],
      orElse: () => TaskRecurrence.none,
    ),
  );
}
```
**الشرح:**
- `doc.data() as Map` → بتحول الـ document لـ Map
- `(data['dateTime'] as Timestamp).toDate()` → بتحول Firestore Timestamp لـ DateTime
- `firstWhere(..., orElse: ...)` → بتدور على القيمة، لو ملقتش بترجع القيمة الافتراضية

---

### `toFirestore()`
```dart
Map<String, dynamic> toFirestore() {
  return {
    'title': title,
    'description': description,
    'dateTime': Timestamp.fromDate(dateTime),
    'priority': priority,
    'isCompleted': isCompleted,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    'category': category.name,
    'recurrence': recurrence.name,
  };
}
```
**الشرح:**
- بتحول الـ TaskModel لـ Map عشان نحفظه في Firestore
- `Timestamp.fromDate()` → بتحول DateTime لـ Firestore Timestamp
- `category.name` → بتاخد اسم الـ enum كـ String

---

### `copyWith(...)`
```dart
TaskModel copyWith({
  String? id,
  String? title,
  String? description,
  DateTime? dateTime,
  int? priority,
  bool? isCompleted,
  DateTime? completedAt,
  TaskCategory? category,
  TaskRecurrence? recurrence,
}) {
  return TaskModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    dateTime: dateTime ?? this.dateTime,
    priority: priority ?? this.priority,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
    category: category ?? this.category,
    recurrence: recurrence ?? this.recurrence,
  );
}
```
**الشرح:**
- بتعمل نسخة من الـ object مع تغيير بعض القيم
- `??` → لو القيمة الجديدة null، استخدم القيمة القديمة
- مفيدة عشان الـ objects في Dart بتكون immutable

---

### `getNextOccurrence()`
```dart
DateTime? getNextOccurrence() {
  switch (recurrence) {
    case TaskRecurrence.daily:
      return dateTime.add(const Duration(days: 1));
    case TaskRecurrence.weekly:
      return dateTime.add(const Duration(days: 7));
    case TaskRecurrence.monthly:
      return DateTime(
        dateTime.year,
        dateTime.month + 1,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
      );
    case TaskRecurrence.none:
      return null;
  }
}
```
**الشرح:**
- بتحسب التاريخ التالي حسب نوع التكرار
- يومي → +1 يوم
- أسبوعي → +7 أيام
- شهري → نفس اليوم في الشهر الجاي

---

### Getters

```dart
bool get isToday {
  final now = DateTime.now();
  return dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day;
}

bool get isUpcoming {
  return dateTime.isAfter(DateTime.now()) && !isCompleted;
}

bool get isOverdue {
  return dateTime.isBefore(DateTime.now()) && !isCompleted;
}

Color get priorityColor {
  if (priority <= 3) return const Color(0xFF5F33E1);
  if (priority <= 6) return const Color(0xFFFFA726);
  if (priority <= 8) return const Color(0xFFFF5722);
  return const Color(0xFFE53935);
}
```
**الشرح:**
- `isToday` → بتقارن السنة والشهر واليوم
- `isUpcoming` → في المستقبل ومش مكتملة
- `isOverdue` → فات وقتها ومش مكتملة
- `priorityColor` → لون حسب مستوى الأولوية

---

# 5. Widgets

---

## 5.1 add_task_bottom_sheet.dart

### `show(BuildContext context, {Set<int> usedPriorities})`
```dart
static Future<TaskModel?> show(
  BuildContext context, {
  Set<int> usedPriorities = const {},
}) {
  return showModalBottomSheet<TaskModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTaskBottomSheet(
      usedPriorities: usedPriorities,
    ),
  );
}
```
**الشرح:**
- `static` → تقدر تناديها من غير ما تعمل instance
- `isScrollControlled: true` → الـ bottom sheet يقدر يكون أطول من نص الشاشة
- `backgroundColor: Colors.transparent` → عشان الـ border radius يظهر صح

---

### `_submit()`
```dart
void _submit() {
  // التحقق من العنوان
  if (_titleController.text.trim().isEmpty) return;

  // دمج التاريخ والوقت
  final dateTime = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  // إنشاء المهمة
  final task = TaskModel(
    title: _titleController.text.trim(),
    description: _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim(),
    dateTime: dateTime,
    priority: _selectedPriority,
    category: _selectedCategory,
    recurrence: _selectedRecurrence,
  );

  // إرجاع المهمة وقفل الـ bottom sheet
  Navigator.pop(context, task);
}
```
**الشرح:**
- بتجمع التاريخ والوقت في DateTime واحد
- `trim()` → بتشيل المسافات
- `Navigator.pop(context, task)` → بتقفل الـ bottom sheet وبترجع المهمة

---

## 5.2 task_card.dart

### `build(BuildContext context)`
```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          // شريط الفئة
          Container(
            width: 4,
            height: 48,
            color: task.category.color,
          ),

          // Checkbox
          GestureDetector(
            onTap: onToggleComplete,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary),
                color: task.isCompleted ? AppColors.primary : Colors.transparent,
              ),
              child: task.isCompleted
                  ? Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          ),

          // التفاصيل
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(task.title),
                    if (task.recurrence != TaskRecurrence.none)
                      Icon(Icons.repeat),
                  ],
                ),
                Row(
                  children: [
                    Text(_formatDateTime(task.dateTime)),
                    Container(
                      child: Text(task.category.label),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // بادج الأولوية
          Container(
            color: task.priorityColor.withAlpha(25),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: task.priorityColor),
                Text('${task.priority}'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```
**الشرح:**
- `GestureDetector` → بيمسك الـ tap events
- شريط الفئة على اليسار بلون الفئة
- الـ checkbox دائري، ملون لو مكتملة
- أيقونة التكرار بتظهر لو المهمة متكررة
- بادج الأولوية بلون مختلف حسب المستوى

---

## 5.3 priority_picker_dialog.dart

### `show(BuildContext context, {int initialPriority, Set<int> unavailablePriorities})`
```dart
static Future<int?> show(
  BuildContext context, {
  int initialPriority = 1,
  Set<int> unavailablePriorities = const {},
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Select Priority'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(10, (index) {
          final priority = index + 1;
          final isUnavailable = unavailablePriorities.contains(priority);
          final isSelected = priority == initialPriority;

          return GestureDetector(
            onTap: isUnavailable
                ? null
                : () => Navigator.pop(context, priority),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isUnavailable
                        ? Colors.grey.shade200
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnavailable
                      ? Colors.grey
                      : AppColors.primary,
                ),
              ),
              child: Stack(
                children: [
                  Center(child: Text('$priority')),
                  if (isUnavailable)
                    Icon(Icons.lock, size: 12),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  );
}
```
**الشرح:**
- `Wrap` → بيرص العناصر وينزل لسطر جديد لو مفيش مكان
- `List.generate(10, ...)` → بتعمل 10 عناصر (الأولويات)
- الأولويات المستخدمة (`unavailablePriorities`) مقفولة ومش بتستجيب للـ tap
- `Stack` → عشان نحط أيقونة القفل فوق الرقم

---

# 6. Helpers

---

## 6.1 responsive_helper.dart

### `responsive<T>({required T mobile, T? tablet, T? desktop})`
```dart
T responsive<T>({
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  if (isDesktop) return desktop ?? tablet ?? mobile;
  if (isTablet) return tablet ?? mobile;
  return mobile;
}
```
**الشرح:**
- Generic method بتقبل أي نوع
- بترجع القيمة المناسبة حسب حجم الشاشة
- لو مفيش قيمة للـ tablet/desktop، بتستخدم اللي قبلها

---

### `fontSize({double mobile, double? tablet, double? desktop})`
```dart
double fontSize({
  double mobile = 14,
  double? tablet,
  double? desktop,
}) {
  return responsive<double>(
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}
```
**الشرح:**
- Shortcut للـ responsive خاصة بحجم الخط
- القيمة الافتراضية 14

---

### `spacing({double mobile, double? tablet, double? desktop})`
```dart
double spacing({
  double mobile = 8,
  double? tablet,
  double? desktop,
}) {
  return responsive<double>(
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}
```
**الشرح:**
- Shortcut للمسافات (padding, margin)
- القيمة الافتراضية 8

---

### Getters
```dart
bool get isMobile => _width < mobileBreakpoint;
bool get isTablet => _width >= mobileBreakpoint && _width < tabletBreakpoint;
bool get isDesktop => _width >= tabletBreakpoint;

double get contentMaxWidth {
  if (isDesktop) return 1200;
  if (isTablet) return 800;
  return double.infinity;
}

double get iconSize => responsive<double>(mobile: 24, tablet: 28, desktop: 32);
```
**الشرح:**
- `isMobile` → أقل من 600
- `isTablet` → من 600 لـ 900
- `isDesktop` → أكتر من 900
- `contentMaxWidth` → أقصى عرض للمحتوى

---

### Extension
```dart
extension ResponsiveExtension on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
```
**الشرح:**
- بتضيف getter على BuildContext
- بدل ما تكتب `ResponsiveHelper(context)`، تكتب `context.responsive`

**الاستخدام:**
```dart
final responsive = context.responsive;
Text(
  'Hello',
  style: TextStyle(
    fontSize: responsive.fontSize(mobile: 14, tablet: 16),
  ),
);
```

---

## 6.2 validators.dart

### `validateEmail(String? value)`
```dart
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email';
  }

  return null;
}
```
**الشرح:**
- `RegExp` → Regular Expression للتحقق من صيغة الإيميل
- `hasMatch()` → بتشوف لو الـ string بيطابق الـ pattern
- بترجع `null` لو صحيح، أو رسالة الخطأ

---

### `validatePassword(String? value)`
```dart
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }

  return null;
}
```
**الشرح:**
- بتتأكد إن الباسورد موجود وطوله 6 أحرف على الأقل

---

# ملخص الفانكشنز الأساسية

| الملف | الفانكشن | الوظيفة |
|-------|----------|---------|
| auth_service | signIn | تسجيل دخول |
| auth_service | signUp | إنشاء حساب |
| auth_service | signOut | تسجيل خروج |
| task_service | createTask | إنشاء مهمة |
| task_service | getTasksStream | جلب المهام (real-time) |
| task_service | toggleTaskCompletion | تبديل حالة الإكمال |
| task_service | deleteTask | حذف مهمة |
| task_service | getStatistics | جلب الإحصائيات |
| streak_service | getStreakData | جلب بيانات الـ Streak |
| streak_service | onTaskCompleted | تحديث الـ Streak |
| profile_service | getProfile | جلب البروفايل |
| profile_service | uploadProfileImage | رفع صورة |
| profile_service | updateDisplayName | تحديث الاسم |
| TaskModel | fromFirestore | تحويل من Firestore |
| TaskModel | toFirestore | تحويل لـ Firestore |
| TaskModel | copyWith | نسخ مع تعديل |
| ResponsiveHelper | responsive | قيمة حسب حجم الشاشة |

---

**تم إعداد هذا الدليل بواسطة Claude AI** 🤖

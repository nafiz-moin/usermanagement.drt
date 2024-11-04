import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class User {
  final int? id;
  final String name;
  final int age;

  User({this.id, required this.name, required this.age});

  // Convert a User into a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  // Convert a Map into a User object
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      age: map['age'],
    );
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  DatabaseService._();
  static DatabaseService get instance => _instance;

  late Database _database;

  Future<void> initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'user.db'),
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)",
        );
      },
      version: 1,
    );
  }

  Future<List<User>> getUsers() async {
    final List<Map<String, dynamic>> maps = await _database.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> insertUser(User user) async {
    await _database.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class UserController extends GetxController {
  final DatabaseService _databaseService = DatabaseService.instance;

  var users = <User>[].obs;

  @override
  void onInit() {
    super.onInit();
    _databaseService.initDatabase().then((_) => fetchUsers());
  }

  Future<void> fetchUsers() async {
    users.value = await _databaseService.getUsers();
  }

  Future<void> addUser(String name, int age) async {
    await _databaseService.insertUser(User(name: name, age: age));
    fetchUsers();
  }
}

class UserManagement extends StatelessWidget {
  final UserController userController = Get.put(UserController());

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(nameController, "Name"),
            const SizedBox(height: 10),
            _buildTextField(ageController, "Age", isNumber: true),
            const SizedBox(height: 10),
            _buildAddUserButton(),
            const SizedBox(height: 20),
            const Text(
              "User List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _buildAddUserButton() {
    return ElevatedButton(
      onPressed: () {
        final name = nameController.text.trim();
        final age = int.tryParse(ageController.text.trim()) ?? 0;

        if (name.isNotEmpty && age > 0) {
          userController.addUser(name, age);
          nameController.clear();
          ageController.clear();
          Get.snackbar("Success", "User added successfully.",
              snackPosition: SnackPosition.BOTTOM);
        } else {
          Get.snackbar("Invalid Input", "Please enter a valid name and age.",
              snackPosition: SnackPosition.BOTTOM);
        }
      },
      child: const Text("Add User"),
    );
  }

  Widget _buildUserList() {
    return Obx(() {
      if (userController.users.isEmpty) {
        return const Center(child: Text("No users found"));
      }
      return ListView.builder(
        itemCount: userController.users.length,
        itemBuilder: (context, index) {
          final user = userController.users[index];
          return Card(
            child: ListTile(
              title: Text(user.name),
              subtitle: Text('Age: ${user.age}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Future delete functionality can be added here
                },
              ),
            ),
          );
        },
      );
    });
  }
}

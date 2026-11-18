import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/appliance_model.dart';
import '../models/bill_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _webUsersKey = 'wattwise_web_users';
  static const _webBillsKey = 'wattwise_web_bills';
  static const _webAppliancesKey = 'wattwise_web_appliances';
  static const _webNextIdKey = 'wattwise_web_next_id';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wattwise_shared.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            tariff_rate_per_kwh REAL NOT NULL DEFAULT 8.0,
            household_size INTEGER NOT NULL DEFAULT 3,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE bills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            billing_month TEXT NOT NULL,
            billing_month_sort_key TEXT NOT NULL,
            billing_period TEXT NOT NULL,
            total_units_kwh REAL NOT NULL,
            total_amount REAL NOT NULL,
            source_type TEXT NOT NULL DEFAULT 'manual',
            file_path TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE appliances (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            rated_power_watts REAL NOT NULL,
            quantity INTEGER NOT NULL,
            daily_usage_hours REAL NOT NULL,
            days_per_month INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  // -------------------- WEB STORAGE HELPERS --------------------

  Future<int> _nextWebId(SharedPreferences prefs) async {
    final current = prefs.getInt(_webNextIdKey) ?? 1;
    await prefs.setInt(_webNextIdKey, current + 1);
    return current;
  }

  Future<List<Map<String, dynamic>>> _readWebList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _writeWebList(
      String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  // -------------------- USER AUTH & PROFILE (Member 1) --------------------

  Future<UserModel> registerUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    double tariffRatePerKwh = 8.0,
    int householdSize = 3,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim().toLowerCase();

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final users = await _readWebList(_webUsersKey);
      final exists = users.any((u) =>
          (u['email'] as String).toLowerCase() == cleanEmail ||
          (u['username'] as String).toLowerCase() == cleanUsername);
      if (exists) {
        throw Exception(
            'An account with this email or username already exists.');
      }
      final id = await _nextWebId(prefs);
      final user = UserModel(
        id: id,
        fullName: fullName.trim(),
        username: cleanUsername,
        email: cleanEmail,
        passwordHash: hashPassword(password),
        tariffRatePerKwh: tariffRatePerKwh,
        householdSize: householdSize,
        createdAt: DateTime.now().toIso8601String(),
      );
      users.add(user.toMap());
      await _writeWebList(_webUsersKey, users);
      return user;
    }

    final db = await database;
    final existing = await db.query(
      'users',
      where: 'LOWER(email) = ? OR LOWER(username) = ?',
      whereArgs: [cleanEmail, cleanUsername],
    );
    if (existing.isNotEmpty) {
      throw Exception('An account with this email or username already exists.');
    }

    final user = UserModel(
      fullName: fullName.trim(),
      username: cleanUsername,
      email: cleanEmail,
      passwordHash: hashPassword(password),
      tariffRatePerKwh: tariffRatePerKwh,
      householdSize: householdSize,
      createdAt: DateTime.now().toIso8601String(),
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<UserModel?> loginUser({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim().toLowerCase();
    final hash = hashPassword(password);

    if (kIsWeb) {
      final users = await _readWebList(_webUsersKey);
      for (final u in users) {
        final email = (u['email'] as String).toLowerCase();
        final username = (u['username'] as String).toLowerCase();
        if ((email == cleanId || username == cleanId) &&
            u['password_hash'] == hash) {
          return UserModel.fromMap(u);
        }
      }
      return null;
    }

    final db = await database;
    final rows = await db.query(
      'users',
      where: '(LOWER(email) = ? OR LOWER(username) = ?) AND password_hash = ?',
      whereArgs: [cleanId, cleanId, hash],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserById(int userId) async {
    if (kIsWeb) {
      final users = await _readWebList(_webUsersKey);
      for (final u in users) {
        if (u['id'] == userId) return UserModel.fromMap(u);
      }
      return null;
    }

    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel> updateUserProfile(UserModel user) async {
    if (kIsWeb) {
      final users = await _readWebList(_webUsersKey);
      final idx = users.indexWhere((u) => u['id'] == user.id);
      if (idx != -1) {
        users[idx] = user.toMap();
        await _writeWebList(_webUsersKey, users);
      }
      return user;
    }

    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }

  // -------------------- BILLS (Member 1 -> Shared DB) --------------------

  Future<BillModel> insertBill(BillModel bill) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final id = await _nextWebId(prefs);
      final saved = bill.copyWith(id: id);
      final bills = await _readWebList(_webBillsKey);
      bills.add(saved.toMap());
      await _writeWebList(_webBillsKey, bills);
      return saved;
    }

    final db = await database;
    final id = await db.insert('bills', bill.toMap());
    return bill.copyWith(id: id);
  }

  Future<void> updateBill(BillModel bill) async {
    if (kIsWeb) {
      final bills = await _readWebList(_webBillsKey);
      final idx = bills.indexWhere((b) => b['id'] == bill.id);
      if (idx != -1) {
        bills[idx] = bill.toMap();
        await _writeWebList(_webBillsKey, bills);
      }
      return;
    }

    final db = await database;
    await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future<void> deleteBill(int billId) async {
    if (kIsWeb) {
      final bills = await _readWebList(_webBillsKey);
      bills.removeWhere((b) => b['id'] == billId);
      await _writeWebList(_webBillsKey, bills);
      return;
    }

    final db = await database;
    await db.delete('bills', where: 'id = ?', whereArgs: [billId]);
  }

  Future<List<BillModel>> getBillsForUser(int userId) async {
    if (kIsWeb) {
      final bills = await _readWebList(_webBillsKey);
      final userBills = bills
          .where((b) => b['user_id'] == userId)
          .map(BillModel.fromMap)
          .toList()
        ..sort(
            (a, b) => a.billingMonthSortKey.compareTo(b.billingMonthSortKey));
      return userBills;
    }

    final db = await database;
    final rows = await db.query(
      'bills',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'billing_month_sort_key ASC, id ASC',
    );
    return rows.map(BillModel.fromMap).toList();
  }

  // -------------------- APPLIANCES (Member 2 -> Shared DB) --------------------

  Future<ApplianceModel> insertAppliance(ApplianceModel appliance) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final id = await _nextWebId(prefs);
      final saved = appliance.copyWith(id: id);
      final list = await _readWebList(_webAppliancesKey);
      list.add(saved.toMap());
      await _writeWebList(_webAppliancesKey, list);
      return saved;
    }

    final db = await database;
    final id = await db.insert('appliances', appliance.toMap());
    return appliance.copyWith(id: id);
  }

  Future<void> updateAppliance(ApplianceModel appliance) async {
    if (kIsWeb) {
      final list = await _readWebList(_webAppliancesKey);
      final idx = list.indexWhere((a) => a['id'] == appliance.id);
      if (idx != -1) {
        list[idx] = appliance.toMap();
        await _writeWebList(_webAppliancesKey, list);
      }
      return;
    }

    final db = await database;
    await db.update(
      'appliances',
      appliance.toMap(),
      where: 'id = ?',
      whereArgs: [appliance.id],
    );
  }

  Future<void> deleteAppliance(int applianceId) async {
    if (kIsWeb) {
      final list = await _readWebList(_webAppliancesKey);
      list.removeWhere((a) => a['id'] == applianceId);
      await _writeWebList(_webAppliancesKey, list);
      return;
    }

    final db = await database;
    await db.delete('appliances', where: 'id = ?', whereArgs: [applianceId]);
  }

  Future<List<ApplianceModel>> getAppliancesForUser(int userId) async {
    if (kIsWeb) {
      final list = await _readWebList(_webAppliancesKey);
      return list
          .where((a) => a['user_id'] == userId)
          .map(ApplianceModel.fromMap)
          .toList()
          .reversed
          .toList();
    }

    final db = await database;
    final rows = await db.query(
      'appliances',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(ApplianceModel.fromMap).toList();
  }

  // -------------------- DEMO DATA SEEDER --------------------

  Future<UserModel> ensureDemoUserWithSampleData() async {
    final existing = await loginUser(
      identifier: 'demo@wattwise.app',
      password: 'wattwise123',
    );
    if (existing != null) {
      return existing;
    }

    final demoUser = await registerUser(
      fullName: 'Aarav Sharma',
      username: 'demo',
      email: 'demo@wattwise.app',
      password: 'wattwise123',
      tariffRatePerKwh: 8.5,
      householdSize: 4,
    );

    final uid = demoUser.id!;
    await seedSampleDataForUser(uid);
    return demoUser;
  }

  Future<void> seedSampleDataForUser(int userId) async {
    final existingBills = await getBillsForUser(userId);
    if (existingBills.isEmpty) {
      final sampleBills = [
        BillModel(
          userId: userId,
          billingMonth: 'Jun 2026',
          billingMonthSortKey: '2026-06',
          billingPeriod: '01/06/2026 - 30/06/2026',
          totalUnitsKwh: 325,
          totalAmount: 2762.50,
          sourceType: 'manual',
          createdAt: DateTime.now().toIso8601String(),
        ),
        BillModel(
          userId: userId,
          billingMonth: 'Jul 2026',
          billingMonthSortKey: '2026-07',
          billingPeriod: '01/07/2026 - 31/07/2026',
          totalUnitsKwh: 310,
          totalAmount: 2635.00,
          sourceType: 'manual',
          createdAt: DateTime.now().toIso8601String(),
        ),
        BillModel(
          userId: userId,
          billingMonth: 'Aug 2026',
          billingMonthSortKey: '2026-08',
          billingPeriod: '01/08/2026 - 31/08/2026',
          totalUnitsKwh: 330,
          totalAmount: 2805.00,
          sourceType: 'ocr_image',
          createdAt: DateTime.now().toIso8601String(),
        ),
        BillModel(
          userId: userId,
          billingMonth: 'Sep 2026',
          billingMonthSortKey: '2026-09',
          billingPeriod: '01/09/2026 - 30/09/2026',
          totalUnitsKwh: 438,
          totalAmount: 3898.20,
          sourceType: 'ocr_pdf',
          createdAt: DateTime.now().toIso8601String(),
        ),
        BillModel(
          userId: userId,
          billingMonth: 'Oct 2026',
          billingMonthSortKey: '2026-10',
          billingPeriod: '01/10/2026 - 31/10/2026',
          totalUnitsKwh: 345,
          totalAmount: 2932.50,
          sourceType: 'ocr_image',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
      for (final b in sampleBills) {
        await insertBill(b);
      }
    }

    final existingAppliances = await getAppliancesForUser(userId);
    if (existingAppliances.isEmpty) {
      final sampleAppliances = [
        ApplianceModel(
          userId: userId,
          name: 'Split Air Conditioner (1.5 Ton)',
          category: 'Cooling',
          ratedPowerWatts: 1500,
          quantity: 1,
          dailyUsageHours: 4.5,
          daysPerMonth: 25,
        ),
        ApplianceModel(
          userId: userId,
          name: 'Refrigerator (Double Door)',
          category: 'Kitchen',
          ratedPowerWatts: 180,
          quantity: 1,
          dailyUsageHours: 24.0,
          daysPerMonth: 30,
        ),
        ApplianceModel(
          userId: userId,
          name: 'Ceiling Fan',
          category: 'Cooling',
          ratedPowerWatts: 75,
          quantity: 3,
          dailyUsageHours: 8.0,
          daysPerMonth: 30,
        ),
        ApplianceModel(
          userId: userId,
          name: 'Water Heater (Geyser)',
          category: 'Heating',
          ratedPowerWatts: 2000,
          quantity: 1,
          dailyUsageHours: 0.8,
          daysPerMonth: 28,
        ),
        ApplianceModel(
          userId: userId,
          name: 'LED Television (43")',
          category: 'Entertainment',
          ratedPowerWatts: 90,
          quantity: 1,
          dailyUsageHours: 4.0,
          daysPerMonth: 30,
        ),
        ApplianceModel(
          userId: userId,
          name: 'Washing Machine',
          category: 'Laundry',
          ratedPowerWatts: 500,
          quantity: 1,
          dailyUsageHours: 1.0,
          daysPerMonth: 20,
        ),
        ApplianceModel(
          userId: userId,
          name: 'LED Bulb (9W)',
          category: 'Lighting',
          ratedPowerWatts: 9,
          quantity: 8,
          dailyUsageHours: 5.0,
          daysPerMonth: 30,
        ),
      ];
      for (final a in sampleAppliances) {
        await insertAppliance(a);
      }
    }
  }
}

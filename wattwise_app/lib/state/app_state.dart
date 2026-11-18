import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appliance_model.dart';
import '../models/bill_model.dart';
import '../models/insight_model.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';
import '../services/energy_calculator.dart';
import '../services/insights_engine.dart';

class AppState extends ChangeNotifier {
  static const _sessionUserIdKey = 'wattwise_logged_in_user_id';

  final DatabaseHelper _db = DatabaseHelper.instance;

  UserModel? _currentUser;
  List<BillModel> _bills = [];
  List<ApplianceModel> _appliances = [];
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  List<BillModel> get bills => List.unmodifiable(_bills);
  List<ApplianceModel> get appliances => List.unmodifiable(_appliances);

  BillModel? get latestBill => _bills.isNotEmpty ? _bills.last : null;

  double get effectiveTariffRate {
    if (latestBill != null && latestBill!.effectiveRatePerKwh > 0) {
      return latestBill!.effectiveRatePerKwh;
    }
    return _currentUser?.tariffRatePerKwh ?? 8.0;
  }

  double get totalEstimatedApplianceKwh =>
      EnergyCalculator.totalEstimatedKwh(_appliances);

  Map<String, double> get consumptionByCategory =>
      EnergyCalculator.consumptionByCategory(_appliances);

  BillComparisonResult? get latestBillComparison {
    if (latestBill == null) return null;
    return EnergyCalculator.compareWithBill(
      bill: latestBill!,
      appliances: _appliances,
    );
  }

  List<MonthlyTrendPoint> get monthlyTrends =>
      InsightsEngine.buildMonthlyTrends(_bills);

  List<ConsumptionAnomaly> get anomalies => InsightsEngine.detectAnomalies(
        bills: _bills,
        appliances: _appliances,
      );

  List<EnergyRecommendation> get recommendations =>
      InsightsEngine.generateRecommendations(
        appliances: _appliances,
        bills: _bills,
        tariffRatePerKwh: effectiveTariffRate,
      );

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_sessionUserIdKey);
      if (userId != null) {
        final user = await _db.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          await _loadUserData();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    if (_currentUser?.id == null) return;
    final uid = _currentUser!.id!;
    _bills = await _db.getBillsForUser(uid);
    _appliances = await _db.getAppliancesForUser(uid);
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    final user = await _db.loginUser(
      identifier: identifier,
      password: password,
    );
    if (user == null) return false;

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionUserIdKey, user.id!);
    await _loadUserData();
    notifyListeners();
    return true;
  }

  Future<void> loginDemoUser() async {
    final demoUser = await _db.ensureDemoUserWithSampleData();
    _currentUser = demoUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionUserIdKey, demoUser.id!);
    await _loadUserData();
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    double tariffRatePerKwh = 8.0,
    int householdSize = 3,
  }) async {
    final user = await _db.registerUser(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
      tariffRatePerKwh: tariffRatePerKwh,
      householdSize: householdSize,
    );
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionUserIdKey, user.id!);
    await _loadUserData();
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
    _currentUser = null;
    _bills = [];
    _appliances = [];
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required double tariffRatePerKwh,
    required int householdSize,
  }) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      fullName: fullName.trim(),
      tariffRatePerKwh: tariffRatePerKwh,
      householdSize: householdSize,
    );
    _currentUser = await _db.updateUserProfile(updated);
    notifyListeners();
  }

  Future<void> seedSampleDataForCurrentUser() async {
    if (_currentUser?.id == null) return;
    await _db.seedSampleDataForUser(_currentUser!.id!);
    await _loadUserData();
    notifyListeners();
  }

  // -------------------- BILL ACTIONS --------------------

  Future<void> addBill(BillModel bill) async {
    await _db.insertBill(bill);
    await _loadUserData();
    notifyListeners();
  }

  Future<void> deleteBill(int billId) async {
    await _db.deleteBill(billId);
    await _loadUserData();
    notifyListeners();
  }

  // -------------------- APPLIANCE ACTIONS --------------------

  Future<void> addAppliance(ApplianceModel appliance) async {
    await _db.insertAppliance(appliance);
    await _loadUserData();
    notifyListeners();
  }

  Future<void> updateAppliance(ApplianceModel appliance) async {
    await _db.updateAppliance(appliance);
    await _loadUserData();
    notifyListeners();
  }

  Future<void> deleteAppliance(int applianceId) async {
    await _db.deleteAppliance(applianceId);
    await _loadUserData();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}

import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// In-memory database with persistent storage (shared_preferences).
class PatientDatabase {
  PatientDatabase._();
  static final PatientDatabase instance = PatientDatabase._();

  // Core patient + condition history
  final List<Patient> _patients = [];
  final List<PatientConditionRecord> _conditionHistory = [];

  // Doctor-accepted prescriptions queued for PHARMACIST verification
  final List<FinalPrescription> _toVerifyQueue = [];

  // Pharmacist-verified plans (approved or edited doses)
  final List<VerifiedPlan> _verifiedPlans = [];

  // Storage keys
  static const String _patientsKey = 'patients';
  static const String _conditionHistoryKey = 'conditionHistory';
  static const String _verifiedPlansKey = 'verifiedPlans';

  // Initialize (load from storage)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load patients
    final patientsJson = prefs.getString(_patientsKey);
    if (patientsJson != null) {
      final List<dynamic> decoded = jsonDecode(patientsJson);
      _patients.addAll(decoded.map((p) => Patient.fromJson(p as Map<String, dynamic>)));
    }

    // Load condition history
    final historyJson = prefs.getString(_conditionHistoryKey);
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _conditionHistory.addAll(decoded.map((h) => PatientConditionRecord.fromJson(h as Map<String, dynamic>)));
    }

    // Load verified plans
    final plansJson = prefs.getString(_verifiedPlansKey);
    if (plansJson != null) {
      final List<dynamic> decoded = jsonDecode(plansJson);
      _verifiedPlans.addAll(decoded.map((p) => VerifiedPlan.fromJson(p as Map<String, dynamic>)));
    }
  }

  // Save to storage
  Future<void> _savePatients() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_patients.map((p) => p.toJson()).toList());
    await prefs.setString(_patientsKey, json);
  }

  Future<void> _saveConditionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_conditionHistory.map((h) => h.toJson()).toList());
    await prefs.setString(_conditionHistoryKey, json);
  }

  Future<void> _saveVerifiedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_verifiedPlans.map((p) => p.toJson()).toList());
    await prefs.setString(_verifiedPlansKey, json);
  }

  // ---------- Patients ----------
  List<Patient> get patients => List.unmodifiable(_patients);
  
  Future<void> addPatient(Patient p) async {
    _patients.add(p);
    await _savePatients();
  }

  // Helper: fetch patient by id
  Patient? patientById(String id) =>
      _patients.cast<Patient?>().firstWhere((p) => p?.id == id, orElse: () => null);

  // ---------- Condition history ----------
  Future<void> addConditionRecord(PatientConditionRecord r) async {
    _conditionHistory.add(r);
    await _saveConditionHistory();
  }

  List<PatientConditionRecord> historyForPatient(String id) =>
      _conditionHistory.where((r) => r.patientId == id).toList();

  // ---------- Pharmacist queues ----------
  List<FinalPrescription> get toVerifyQueue => List.unmodifiable(_toVerifyQueue);

  void enqueueForVerification(FinalPrescription rx) => _toVerifyQueue.add(rx);

  void removeFromQueue(String id) =>
      _toVerifyQueue.removeWhere((e) => e.id == id);

  // ---------- Verified plans ----------
  List<VerifiedPlan> get verifiedPlans => List.unmodifiable(_verifiedPlans);

  Future<void> addVerifiedPlan(VerifiedPlan vp) async {
    _verifiedPlans.add(vp);
    await _saveVerifiedPlans();
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for caching data locally for offline support
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  /// Initialize cache service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Cache user profile
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await _prefs?.setString('cached_user_profile', jsonEncode(profile));
  }

  /// Get cached user profile
  Map<String, dynamic>? getCachedUserProfile() {
    final cachedData = _prefs?.getString('cached_user_profile');
    if (cachedData != null) {
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Cache projects list
  Future<void> cacheProjects(List<Map<String, dynamic>> projects) async {
    await _prefs?.setString('cached_projects', jsonEncode(projects));
    await _prefs?.setString('cached_projects_timestamp', DateTime.now().toIso8601String());
  }

  /// Get cached projects
  List<Map<String, dynamic>>? getCachedProjects() {
    final cachedData = _prefs?.getString('cached_projects');
    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Check if projects cache is fresh (less than 1 hour old)
  bool isProjectsCacheFresh() {
    final timestamp = _prefs?.getString('cached_projects_timestamp');
    if (timestamp == null) return false;
    
    final cachedTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(cachedTime).inHours < 1;
  }

  /// Cache dashboard stats
  Future<void> cacheDashboardStats(Map<String, dynamic> stats) async {
    await _prefs?.setString('cached_dashboard_stats', jsonEncode(stats));
    await _prefs?.setString('cached_stats_timestamp', DateTime.now().toIso8601String());
  }

  /// Get cached dashboard stats
  Map<String, dynamic>? getCachedDashboardStats() {
    final cachedData = _prefs?.getString('cached_dashboard_stats');
    if (cachedData != null) {
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Check if stats cache is fresh (less than 30 minutes old)
  bool isStatsCacheFresh() {
    final timestamp = _prefs?.getString('cached_stats_timestamp');
    if (timestamp == null) return false;
    
    final cachedTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(cachedTime).inMinutes < 30;
  }

  /// Cache last viewed project
  Future<void> cacheLastViewedProject(Map<String, dynamic> project) async {
    await _prefs?.setString('last_viewed_project', jsonEncode(project));
  }

  /// Get last viewed project
  Map<String, dynamic>? getLastViewedProject() {
    final cachedData = _prefs?.getString('last_viewed_project');
    if (cachedData != null) {
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Cache user subscriptions
  Future<void> cacheSubscriptions(List<Map<String, dynamic>> subscriptions) async {
    await _prefs?.setString('cached_subscriptions', jsonEncode(subscriptions));
  }

  /// Get cached subscriptions
  List<Map<String, dynamic>>? getCachedSubscriptions() {
    final cachedData = _prefs?.getString('cached_subscriptions');
    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _prefs?.remove('cached_user_profile');
    await _prefs?.remove('cached_projects');
    await _prefs?.remove('cached_projects_timestamp');
    await _prefs?.remove('cached_dashboard_stats');
    await _prefs?.remove('cached_stats_timestamp');
    await _prefs?.remove('last_viewed_project');
    await _prefs?.remove('cached_subscriptions');
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    await _prefs?.remove(key);
  }

  /// Store generic cached data
  Future<void> setCachedData(String key, dynamic data) async {
    await _prefs?.setString(key, jsonEncode(data));
  }

  /// Get generic cached data
  dynamic getCachedData(String key) {
    final cachedData = _prefs?.getString(key);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return null;
  }

  /// Check if cache exists
  bool hasCachedData(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}

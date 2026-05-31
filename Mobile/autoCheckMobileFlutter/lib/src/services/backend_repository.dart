import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../models/api_contract.dart';
import '../models/submission.dart';
import 'app_logger.dart';

/// Назначение: HTTP-репозиторий для реального AutoCheck backend.
///
/// Ответственность/SRP: хранит JWT, выполняет REST/multipart-запросы,
/// снимает ApiResponse envelope `{data,error,meta}` и преобразует DTO в
/// доменные модели экранов. Виджеты не знают о `http` и OpenAPI-полях.
///
/// Дата создания: 31-05-2026.
/// Автор: Команда.
///
/// Публичные методы: [login], [register], [assignments], [createAssignment],
/// [submissions], [createSubmission], [results], [aiReview], [rerun],
/// [updateVerdict], [report], [stats], [statistics].
class BackendRepository {
  BackendRepository._();

  static final instance = BackendRepository._();

  static const _baseUrl = String.fromEnvironment(
    'AUTOCHECK_API_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  String? _token;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get _authHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> login(String email, String password) async {
    AppLogger.info('BackendRepository', 'POST /auth/login', {'email': email});
    final data = _asMap(await _request('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    }));
    _token = data['token']?.toString();
  }

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
    required UserRole role,
  }) async {
    AppLogger.info('BackendRepository', 'POST /auth/register', {'email': email, 'role': role.name});
    final data = _asMap(await _request('POST', '/auth/register', body: {
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role == UserRole.expert ? 'EXPERT' : 'CANDIDATE',
    }));
    _token = data['token']?.toString();
  }

  Future<DashboardStats> stats() async {
    AppLogger.info('BackendRepository', 'GET /reports/stats');
    final data = _asMap(await _request('GET', '/reports/stats'));
    final submissions = await this.submissions();
    final awaiting = submissions
        .where((item) => item.status == SubmissionStatus.pending || item.status == SubmissionStatus.running)
        .length;
    return DashboardStats(
      averageScore: _num(data['averageScore']).round(),
      awaiting: awaiting,
      passRate: _num(data['passRate']),
      total: _int(data['totalSubmissions']),
    );
  }

  Future<StatisticsData> statistics() async {
    AppLogger.info('BackendRepository', 'GET /reports/stats for statistics');
    final data = _asMap(await _request('GET', '/reports/stats'));
    final stats = DashboardStats(
      averageScore: _num(data['averageScore']).round(),
      awaiting: 0,
      passRate: _num(data['passRate']),
      total: _int(data['totalSubmissions']),
    );
    final dailyCounts = data['dailyCounts'] is List
        ? (data['dailyCounts'] as List).map((item) {
            final map = _asMap(item);
            return DailyCount(
              count: _int(map['count']),
              date: map['date']?.toString() ?? '',
            );
          }).toList()
        : const <DailyCount>[];
    final topCandidates = data['topCandidates'] is List
        ? (data['topCandidates'] as List).map((item) {
            final map = _asMap(item);
            return TopCandidate(
              bestScore: _num(map['bestScore']),
              fullName: map['fullName']?.toString() ?? 'Кандидат',
              id: map['candidateId']?.toString() ?? map['fullName']?.toString() ?? 'candidate',
            );
          }).toList()
        : const <TopCandidate>[];

    return StatisticsData(
      dailyCounts: dailyCounts,
      stats: stats,
      topCandidates: topCandidates,
    );
  }

  Future<List<Assignment>> assignments() async {
    AppLogger.info('BackendRepository', 'GET /assignments');
    final data = _asMapList(await _request('GET', '/assignments'));
    return data.map(_assignmentFromJson).toList();
  }

  Future<Assignment> createAssignment({
    required List<CheckerConfig> checkerConfig,
    required String description,
    required String instructionsMarkdown,
    required AssignmentStatus status,
    required List<String> technologies,
    required String title,
  }) async {
    AppLogger.info('BackendRepository', 'POST /assignments', {'title': title, 'status': status.name});
    final weights = <String, int>{
      for (final item in checkerConfig)
        if (item.enabled) checkerRawName(item.checker): item.weight,
    };
    final data = _asMap(await _request('POST', '/assignments', body: {
      'title': title,
      'description': [
        description,
        if (technologies.isNotEmpty) 'Технологии: ${technologies.join(', ')}',
        if (instructionsMarkdown.isNotEmpty) instructionsMarkdown,
      ].where((item) => item.trim().isNotEmpty).join('\n\n'),
      'checkerWeights': weights,
    }));
    return _assignmentFromJson(data);
  }

  Future<List<Submission>> submissions({String? assignmentId}) async {
    AppLogger.info('BackendRepository', 'GET /submissions', {'assignmentId': assignmentId});
    final path = assignmentId == null || assignmentId.isEmpty
        ? '/submissions'
        : '/submissions?assignmentId=${Uri.encodeQueryComponent(assignmentId)}';
    final data = _asMapList(await _request('GET', path));
    return data.map((item) => ApiSubmissionDto.fromJson(item).toDomain()).toList();
  }

  Future<Submission> submissionById(String id) async {
    AppLogger.info('BackendRepository', 'GET /submissions/{id}', {'submissionId': id});
    final data = _asMap(await _request('GET', '/submissions/$id'));
    return ApiSubmissionDto.fromJson(data).toDomain();
  }

  Future<Submission> createSubmission({
    required String assignmentId,
    required String candidateEmail,
    required String candidateFullName,
    PlatformFile? file,
    String? gitUrl,
  }) async {
    AppLogger.info('BackendRepository', 'POST /submissions', {
      'assignmentId': assignmentId,
      'candidateEmail': candidateEmail,
      'source': gitUrl == null ? 'zip' : 'git',
    });
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/submissions'))
      ..headers.addAll(_authHeaders)
      ..fields['assignmentId'] = assignmentId
      ..fields['candidateEmail'] = candidateEmail
      ..fields['candidateFullName'] = candidateFullName;

    if (gitUrl != null && gitUrl.trim().isNotEmpty) {
      request.fields['gitUrl'] = gitUrl.trim();
    }

    if (file != null) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Файл не загружен в память. Выберите ZIP ещё раз.');
      }
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = _asMap(_unwrap(response.statusCode, response.body));
    return ApiSubmissionDto.fromJson(data).toDomain();
  }

  Future<List<CheckResult>> results(String submissionId) async {
    AppLogger.info('BackendRepository', 'GET /submissions/{id}/results', {'submissionId': submissionId});
    final data = _asMapList(await _request('GET', '/submissions/$submissionId/results'));
    return data.map((item) => ApiCheckResultDto.fromJson(item).toDomain()).toList();
  }

  Future<AiReview> aiReview(String submissionId) async {
    AppLogger.info('BackendRepository', 'GET /submissions/{id}/ai-review', {'submissionId': submissionId});
    final data = _asMap(await _request('GET', '/submissions/$submissionId/ai-review'));
    return ApiAiReviewDto(
      available: data['available'] == true,
      recommendations: _stringList(data['recommendations']),
      strengths: _stringList(data['strengths']),
      summary: data['summary']?.toString(),
      weaknesses: _stringList(data['weaknesses']),
    ).toDomain();
  }

  Future<List<TimelineEvent>> timeline(Submission submission) async {
    AppLogger.info('BackendRepository', 'Client timeline derived from Submission', {'submissionId': submission.id});
    return [
      TimelineEvent(label: 'Решение загружено', time: submission.createdAt, tone: TimelineTone.done),
      TimelineEvent(label: 'Задача поставлена в очередь', time: submission.createdAt, tone: TimelineTone.done),
      TimelineEvent(
        label: 'Запущены чекеры',
        time: submission.createdAt.add(const Duration(minutes: 2)),
        tone: submission.status == SubmissionStatus.pending ? TimelineTone.active : TimelineTone.done,
      ),
      TimelineEvent(
        label: 'Результаты рассчитаны',
        time: submission.completedAt ?? submission.createdAt,
        tone: submission.score == null ? TimelineTone.muted : TimelineTone.done,
      ),
      TimelineEvent(
        label: 'Вердикт эксперта',
        time: submission.completedAt ?? submission.createdAt,
        tone: submission.verdict == Verdict.none ? TimelineTone.muted : TimelineTone.done,
      ),
    ];
  }

  Future<Submission> rerun(String id) async {
    AppLogger.info('BackendRepository', 'POST /submissions/{id}/rerun', {'submissionId': id});
    final data = _asMap(await _request('POST', '/submissions/$id/rerun'));
    return ApiSubmissionDto.fromJson(data).toDomain();
  }

  Future<Submission> updateVerdict(String id, Verdict verdict, String comment) async {
    AppLogger.info('BackendRepository', 'PUT /submissions/{id}/verdict', {
      'submissionId': id,
      'verdict': verdict.name,
    });
    final data = _asMap(await _request('PUT', '/submissions/$id/verdict', body: {
      'verdict': verdict == Verdict.accepted ? 'ACCEPTED' : 'REJECTED',
      'comment': comment,
    }));
    return ApiSubmissionDto.fromJson(data).toDomain();
  }

  Future<String> report(String id) async {
    AppLogger.info('BackendRepository', 'GET /submissions/{id}/report', {'submissionId': id});
    final data = await _request('GET', '/submissions/$id/report');
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<Object?> _request(String method, String path, {Map<String, Object?>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = switch (method) {
      'GET' => await http.get(uri, headers: _jsonHeaders),
      'POST' => await http.post(uri, headers: _jsonHeaders, body: body == null ? null : jsonEncode(body)),
      'PUT' => await http.put(uri, headers: _jsonHeaders, body: body == null ? null : jsonEncode(body)),
      _ => throw UnsupportedError('Unsupported method $method'),
    };
    return _unwrap(response.statusCode, response.body);
  }

  Object? _unwrap(int statusCode, String body) {
    final decoded = body.isEmpty ? null : jsonDecode(body);
    final envelope = decoded is Map && (decoded.containsKey('data') || decoded.containsKey('error'));
    final decodedMap = envelope ? _asMap(decoded) : null;
    final error = decodedMap?['error'];

    if (statusCode >= 400 || error != null) {
      if (error is Map) {
        throw Exception(_asMap(error)['message']?.toString() ?? 'Backend request failed');
      }
      throw Exception('Backend request failed: HTTP $statusCode');
    }

    if (envelope) {
      return decodedMap?['data'];
    }
    return decoded;
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw Exception('Backend вернул неожиданный формат объекта');
}

List<Map<String, Object?>> _asMapList(Object? value) {
  if (value is List) {
    return value.map(_asMap).toList();
  }
  throw Exception('Backend вернул неожиданный формат списка');
}

Assignment _assignmentFromJson(Map<String, Object?> json) {
  final weights = json['checkerWeights'] is Map ? _asMap(json['checkerWeights']) : const <String, Object?>{};
  return Assignment(
    checkerConfig: defaultCheckerConfig.map((item) {
      final rawName = checkerRawName(item.checker);
      final weight = _int(weights[rawName]);
      return item.copyWith(enabled: weight > 0, weight: weight);
    }).toList(),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    description: json['description']?.toString() ?? '',
    id: json['id'].toString(),
    instructionsMarkdown: json['description']?.toString() ?? '',
    status: AssignmentStatus.published,
    technologies: const [],
    title: json['title']?.toString() ?? 'Задание',
  );
}

int _int(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

double _num(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

List<String>? _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return null;
}

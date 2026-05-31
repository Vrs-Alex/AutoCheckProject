enum SubmissionStatus {
  pending,
  running,
  passed,
  failed,
  error,
}

enum Verdict {
  accepted,
  rejected,
  none,
}

enum UserRole {
  expert,
  candidate,
}

enum AssignmentStatus {
  draft,
  published,
}

enum SourceType {
  zip,
  git,
}

enum CheckerName {
  staticAnalysis,
  architecture,
  build,
  tests,
  documentation,
  gitPractices,
}

enum CheckerStatus {
  pending,
  running,
  passed,
  failed,
  error,
}

const _notSet = Object();

class CheckerConfig {
  const CheckerConfig({
    required this.checker,
    required this.enabled,
    required this.weight,
  });

  final CheckerName checker;
  final bool enabled;
  final int weight;

  CheckerConfig copyWith({
    CheckerName? checker,
    bool? enabled,
    int? weight,
  }) {
    return CheckerConfig(
      checker: checker ?? this.checker,
      enabled: enabled ?? this.enabled,
      weight: weight ?? this.weight,
    );
  }
}

class Assignment {
  const Assignment({
    required this.checkerConfig,
    required this.createdAt,
    required this.description,
    required this.id,
    required this.instructionsMarkdown,
    required this.status,
    required this.technologies,
    required this.title,
  });

  final String id;
  final String title;
  final String description;
  final List<String> technologies;
  final List<CheckerConfig> checkerConfig;
  final String instructionsMarkdown;
  final AssignmentStatus status;
  final DateTime createdAt;
}

class Submission {
  const Submission({
    required this.id,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.candidateId,
    required this.candidateEmail,
    required this.candidateName,
    required this.createdAt,
    required this.score,
    required this.status,
    required this.verdict,
    this.fileName,
    this.gitUrl,
    this.completedAt,
    this.sourceType = SourceType.zip,
    this.verdictComment,
  });

  final String id;
  final String assignmentId;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final String assignmentTitle;
  final DateTime createdAt;
  final DateTime? completedAt;
  final SourceType sourceType;
  final String? fileName;
  final String? gitUrl;
  final int? score;
  final SubmissionStatus status;
  final Verdict verdict;
  final String? verdictComment;

  Submission copyWith({
    Object? completedAt = _notSet,
    Object? fileName = _notSet,
    Object? gitUrl = _notSet,
    Object? score = _notSet,
    Object? verdictComment = _notSet,
    SourceType? sourceType,
    SubmissionStatus? status,
    Verdict? verdict,
  }) {
    return Submission(
      id: id,
      assignmentId: assignmentId,
      assignmentTitle: assignmentTitle,
      candidateId: candidateId,
      candidateEmail: candidateEmail,
      candidateName: candidateName,
      createdAt: createdAt,
      completedAt: identical(completedAt, _notSet) ? this.completedAt : completedAt as DateTime?,
      fileName: identical(fileName, _notSet) ? this.fileName : fileName as String?,
      gitUrl: identical(gitUrl, _notSet) ? this.gitUrl : gitUrl as String?,
      score: identical(score, _notSet) ? this.score : score as int?,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      verdict: verdict ?? this.verdict,
      verdictComment: identical(verdictComment, _notSet) ? this.verdictComment : verdictComment as String?,
    );
  }
}

class CheckResult {
  const CheckResult({
    required this.checker,
    required this.durationMs,
    required this.log,
    required this.message,
    required this.score,
    required this.status,
  });

  final String checker;
  final CheckerStatus status;
  final int score;
  final String message;
  final String log;
  final int durationMs;
}

class TimelineEvent {
  const TimelineEvent({
    required this.label,
    required this.time,
    required this.tone,
  });

  final String label;
  final DateTime time;
  final TimelineTone tone;
}

enum TimelineTone {
  done,
  active,
  muted,
}

class AiReview {
  const AiReview({
    required this.good,
    required this.improvements,
    required this.summary,
  });

  final String summary;
  final List<String> good;
  final List<String> improvements;
}

class DashboardStats {
  const DashboardStats({
    required this.averageScore,
    required this.awaiting,
    required this.passRate,
    required this.total,
  });

  final int total;
  final int averageScore;
  final double passRate;
  final int awaiting;
}

class DailyCount {
  const DailyCount({
    required this.count,
    required this.date,
  });

  final String date;
  final int count;
}

class TopCandidate {
  const TopCandidate({
    required this.bestScore,
    required this.fullName,
    required this.id,
  });

  final String id;
  final String fullName;
  final double bestScore;
}

class StatisticsData {
  const StatisticsData({
    required this.dailyCounts,
    required this.stats,
    required this.topCandidates,
  });

  final DashboardStats stats;
  final List<DailyCount> dailyCounts;
  final List<TopCandidate> topCandidates;
}

const defaultCheckerConfig = <CheckerConfig>[
  CheckerConfig(checker: CheckerName.staticAnalysis, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.architecture, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.build, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.tests, enabled: true, weight: 20),
  CheckerConfig(checker: CheckerName.documentation, enabled: true, weight: 10),
  CheckerConfig(checker: CheckerName.gitPractices, enabled: true, weight: 10),
];

String checkerLabel(CheckerName checker) {
  return switch (checker) {
    CheckerName.staticAnalysis => 'Статический анализ',
    CheckerName.architecture => 'Архитектура',
    CheckerName.build => 'Сборка',
    CheckerName.tests => 'Unit-тесты',
    CheckerName.documentation => 'Документация',
    CheckerName.gitPractices => 'Git-практики',
  };
}

String checkerRawName(CheckerName checker) {
  return switch (checker) {
    CheckerName.staticAnalysis => 'STATIC_ANALYSIS',
    CheckerName.architecture => 'ARCHITECTURE',
    CheckerName.build => 'BUILD',
    CheckerName.tests => 'TESTS',
    CheckerName.documentation => 'DOCUMENTATION',
    CheckerName.gitPractices => 'GIT_PRACTICES',
  };
}

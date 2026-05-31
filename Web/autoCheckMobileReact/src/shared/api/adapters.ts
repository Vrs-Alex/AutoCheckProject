import type {
  AiReview,
  Assignment,
  Candidate,
  CheckResult,
  CheckerConfig,
  CheckerName,
  ReportStats,
  Submission,
  SubmissionStatus,
  User,
  Verdict,
} from './types'

type RawUser = {
  id: number | string
  email: string
  fullName: string
  role: 'EXPERT' | 'CANDIDATE' | 'expert' | 'candidate'
}

type RawAssignment = {
  id: number | string
  title: string
  description?: string | null
  checkerWeights?: Partial<Record<RawCheckerName, number>>
  checkerConfig?: CheckerConfig[]
  technologies?: string[]
  instructionsMarkdown?: string
  status?: 'draft' | 'published'
  createdAt: string
  updatedAt?: string
  createdBy?: number | string
}

type RawSubmission = {
  id: number | string
  assignmentId: number | string
  assignmentTitle?: string
  candidateId?: number | string
  candidateFullName?: string
  candidateName?: string
  candidateEmail?: string
  status: RawSubmissionState
  totalScore?: number | null
  score?: number | null
  verdict?: 'ACCEPTED' | 'REJECTED' | Verdict | null
  verdictComment?: string | null
  createdAt?: string
  uploadedAt?: string
  completedAt?: string | null
  sourceType?: 'zip' | 'git'
  gitUrl?: string
  fileName?: string
}

type RawSubmissionState = 'PENDING' | 'RUNNING' | 'DONE' | 'ERROR' | SubmissionStatus

type RawCheckResult = {
  id: number | string
  submissionId?: number | string
  checkerType?: RawCheckerName
  checker?: CheckerName
  status: 'PENDING' | 'RUNNING' | 'PASSED' | 'FAILED' | 'ERROR' | SubmissionStatus
  score?: number | null
  log?: string | null
  message?: string
  details?: string
  startedAt?: string | null
  finishedAt?: string | null
  durationMs?: number
}

type RawAiReview = {
  available: boolean
  summary?: string | null
  strengths?: string[] | null
  weaknesses?: string[] | null
  recommendations?: string[] | null
  good?: string[]
  improvements?: string[]
  remarks?: string[]
  errorMessage?: string
}

type RawStats = {
  totalSubmissions?: number
  totalSubmissions30d?: number
  averageScore: number
  passRate: number
  awaitingReview?: number
  dailyCounts?: { date: string; count: number }[]
  dailySubmissions?: { date: string; count: number; passed: number; failed: number }[]
  topCandidates: { candidateId?: number | string; id?: number | string; fullName: string; bestScore: number; attempts?: number }[]
}

type RawCheckerName =
  | 'STATIC_ANALYSIS'
  | 'ARCHITECTURE'
  | 'BUILD'
  | 'TESTS'
  | 'DOCUMENTATION'
  | 'GIT_PRACTICES'

const checkerToRaw: Record<CheckerName, RawCheckerName> = {
  StaticAnalysis: 'STATIC_ANALYSIS',
  Architecture: 'ARCHITECTURE',
  Build: 'BUILD',
  Tests: 'TESTS',
  Documentation: 'DOCUMENTATION',
  GitPractices: 'GIT_PRACTICES',
}

const rawToChecker: Record<RawCheckerName, CheckerName> = {
  STATIC_ANALYSIS: 'StaticAnalysis',
  ARCHITECTURE: 'Architecture',
  BUILD: 'Build',
  TESTS: 'Tests',
  DOCUMENTATION: 'Documentation',
  GIT_PRACTICES: 'GitPractices',
}

const defaultCheckerOrder: CheckerName[] = ['StaticAnalysis', 'Architecture', 'Build', 'Tests', 'Documentation', 'GitPractices']

export function toApiCheckerWeights(config: CheckerConfig[]) {
  return config
    .filter((item) => item.enabled)
    .reduce<Partial<Record<RawCheckerName, number>>>((acc, item) => {
      acc[checkerToRaw[item.checker]] = item.weight
      return acc
    }, {})
}

export function normalizeUser(raw: RawUser): User {
  return {
    id: String(raw.id),
    email: raw.email,
    fullName: raw.fullName,
    role: raw.role === 'EXPERT' ? 'expert' : raw.role === 'CANDIDATE' ? 'candidate' : raw.role,
  }
}

export function normalizeAssignment(raw: RawAssignment): Assignment {
  const checkerConfig =
    raw.checkerConfig ??
    defaultCheckerOrder.map((checker) => ({
      checker,
      enabled: Boolean(raw.checkerWeights?.[checkerToRaw[checker]]),
      weight: raw.checkerWeights?.[checkerToRaw[checker]] ?? 0,
    }))

  return {
    id: String(raw.id),
    title: raw.title,
    description: raw.description ?? '',
    technologies: raw.technologies ?? [],
    checkerConfig,
    instructionsMarkdown: raw.instructionsMarkdown ?? '',
    status: raw.status ?? 'published',
    createdAt: raw.createdAt,
  }
}

export function normalizeSubmission(raw: RawSubmission): Submission {
  const status = normalizeApiSubmissionStatus(raw.status, raw.totalScore ?? raw.score ?? null)
  return {
    id: String(raw.id),
    assignmentId: String(raw.assignmentId),
    assignmentTitle: raw.assignmentTitle ?? `Задание #${raw.assignmentId}`,
    candidateId: String(raw.candidateId ?? ''),
    candidateName: raw.candidateFullName ?? raw.candidateName ?? 'Кандидат',
    // Backend Submission пока не возвращает email, но UI покажет его,
    // если контракт расширят этим nullable-safe полем.
    candidateEmail: raw.candidateEmail ?? '',
    sourceType: raw.sourceType ?? (raw.gitUrl ? 'git' : 'zip'),
    gitUrl: raw.gitUrl,
    fileName: raw.fileName,
    status,
    score: raw.totalScore ?? raw.score ?? null,
    verdict: normalizeVerdict(raw.verdict),
    uploadedAt: raw.createdAt ?? raw.uploadedAt ?? new Date().toISOString(),
    completedAt: raw.completedAt ?? undefined,
  }
}

export function createTimelineFromSubmission(submission: Submission) {
  return [
    { id: 't1', label: 'Решение загружено', at: submission.uploadedAt, status: 'done' as const },
    { id: 't2', label: 'Задача поставлена в очередь', at: submission.uploadedAt, status: 'done' as const },
    {
      id: 't3',
      label: 'Запущены чекеры',
      at: submission.uploadedAt,
      status: submission.status === 'pending' ? ('active' as const) : ('done' as const),
    },
    {
      id: 't4',
      label: 'Результаты рассчитаны',
      at: submission.completedAt ?? submission.uploadedAt,
      status: submission.score == null ? ('muted' as const) : ('done' as const),
    },
    {
      id: 't5',
      label: 'Вердикт эксперта',
      at: submission.completedAt ?? submission.uploadedAt,
      status: submission.verdict === 'none' ? ('muted' as const) : ('done' as const),
    },
  ]
}

export function normalizeApiSubmissionStatus(status: RawSubmissionState, score: number | null): SubmissionStatus {
  if (status === 'PENDING' || status === 'pending') return 'pending'
  if (status === 'RUNNING' || status === 'running') return 'running'
  if (status === 'ERROR' || status === 'error') return 'error'
  if (status === 'DONE') return score != null && score >= 60 ? 'passed' : 'failed'
  return status
}

export function normalizeCheckResult(raw: RawCheckResult): CheckResult {
  const checker = raw.checker ?? (raw.checkerType ? rawToChecker[raw.checkerType] : 'StaticAnalysis')
  return {
    id: String(raw.id),
    submissionId: String(raw.submissionId ?? ''),
    checker,
    status: normalizeCheckStatus(raw.status),
    score: raw.score ?? 0,
    message: raw.message ?? resultMessage(raw.status),
    details: raw.details ?? raw.log ?? 'Лог чекера отсутствует',
    durationMs: raw.durationMs ?? durationMs(raw.startedAt, raw.finishedAt),
  }
}

export function normalizeAiReview(raw: RawAiReview): AiReview {
  return {
    available: raw.available,
    summary: raw.summary ?? undefined,
    good: raw.good ?? raw.strengths ?? undefined,
    improvements: raw.improvements ?? raw.weaknesses ?? undefined,
    remarks: raw.remarks ?? raw.recommendations ?? undefined,
    errorMessage: raw.errorMessage,
  }
}

export function normalizeStats(raw: RawStats): ReportStats {
  const total = raw.totalSubmissions30d ?? raw.totalSubmissions ?? 0
  const dailySubmissions =
    raw.dailySubmissions ??
    (raw.dailyCounts ?? []).map((item) => {
      const passed = Math.round(item.count * ((raw.passRate ?? 0) / 100))
      return { date: item.date, count: item.count, passed, failed: Math.max(0, item.count - passed) }
    })

  return {
    totalSubmissions30d: total,
    averageScore: roundMetric(raw.averageScore),
    passRate: roundMetric(raw.passRate),
    awaitingReview: raw.awaitingReview ?? 0,
    dailySubmissions,
    topCandidates: raw.topCandidates.map((candidate) => ({
      id: String(candidate.id ?? candidate.candidateId ?? candidate.fullName),
      fullName: candidate.fullName,
      bestScore: candidate.bestScore,
      attempts: candidate.attempts ?? 0,
    })),
  }
}

export function normalizeCandidate(raw: Candidate): Candidate {
  return { ...raw, id: String(raw.id) }
}

function normalizeCheckStatus(status: RawCheckResult['status']): SubmissionStatus {
  if (status === 'PENDING' || status === 'pending') return 'pending'
  if (status === 'RUNNING' || status === 'running') return 'running'
  if (status === 'PASSED' || status === 'passed') return 'passed'
  if (status === 'FAILED' || status === 'failed') return 'failed'
  return 'error'
}

function normalizeVerdict(verdict: RawSubmission['verdict']): Verdict {
  if (!verdict) return 'none'
  if (verdict === 'ACCEPTED' || verdict === 'accepted') return 'accepted'
  return 'rejected'
}

function resultMessage(status: RawCheckResult['status']) {
  if (status === 'PASSED' || status === 'passed') return 'Проверка успешно пройдена'
  if (status === 'FAILED' || status === 'failed') return 'Найдены замечания'
  if (status === 'RUNNING' || status === 'running') return 'Проверка выполняется'
  if (status === 'PENDING' || status === 'pending') return 'Ожидает запуска'
  return 'Ошибка выполнения чекера'
}

function durationMs(startedAt?: string | null, finishedAt?: string | null) {
  if (!startedAt || !finishedAt) return 0
  return Math.max(0, new Date(finishedAt).getTime() - new Date(startedAt).getTime())
}

function roundMetric(value: number) {
  return Math.round(value * 10) / 10
}

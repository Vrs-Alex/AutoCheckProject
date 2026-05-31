import { delay, http, HttpResponse } from 'msw'
import type {
  AiReview,
  ApiError,
  Assignment,
  CheckResult,
  CheckerName,
  Submission,
  SubmissionStatus,
  User,
} from '../shared/api/types'
import { db, findSubmission, replaceSubmission, upsertAssignment } from './db'

const api = '/api/v1'
const checkerToRaw: Record<CheckerName, string> = {
  StaticAnalysis: 'STATIC_ANALYSIS',
  Architecture: 'ARCHITECTURE',
  Build: 'BUILD',
  Tests: 'TESTS',
  Documentation: 'DOCUMENTATION',
  GitPractices: 'GIT_PRACTICES',
}

const rawToChecker: Record<string, CheckerName> = {
  STATIC_ANALYSIS: 'StaticAnalysis',
  ARCHITECTURE: 'Architecture',
  BUILD: 'Build',
  TESTS: 'Tests',
  DOCUMENTATION: 'Documentation',
  GIT_PRACTICES: 'GitPractices',
}

type JsonResponseBody = Parameters<typeof HttpResponse.json>[0]

// MSW-моки намеренно повторяют финальный Swagger: success body идет напрямую, без { data, meta }.
function ok<T>(data: T, status = 200) {
  return HttpResponse.json(data as JsonResponseBody, { status })
}

function fail(status: number, error: ApiError) {
  const normalized = { ...error, details: error.details ?? error.fields }
  return HttpResponse.json(normalized as JsonResponseBody, { status })
}

function emptyOk() {
  return new HttpResponse(null, { status: 200 })
}

async function withLatency() {
  await delay(320 + Math.round(Math.random() * 420))
}

function getAuthUser(request: Request): User | null {
  const token = request.headers.get('Authorization')?.replace('Bearer ', '')
  const user = db.users.find((item) => token === `mock-${item.role}-token`)
  return user
    ? {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
      }
    : null
}

function requireAuth(request: Request) {
  const user = getAuthUser(request)
  if (!user) {
    return { user: null, response: fail(401, { code: 'UNAUTHORIZED', message: 'Не авторизован' }) }
  }
  return { user, response: null }
}

function toRawUser(user: User | null) {
  if (!user) return null
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    role: user.role === 'expert' ? 'EXPERT' : 'CANDIDATE',
  }
}

function toRawAssignment(assignment: Assignment) {
  const raw = {
    id: assignment.id,
    title: assignment.title,
    description: assignment.description,
    checkerWeights: assignment.checkerConfig
      .filter((item) => item.enabled)
      .reduce<Record<string, number>>((acc, item) => {
        acc[checkerToRaw[item.checker]] = item.weight
        return acc
      }, {}),
    createdBy: 1,
    createdAt: assignment.createdAt,
    updatedAt: assignment.createdAt,
  }
  return raw
}

function toRawSubmission(submission: Submission) {
  const raw: {
    id: string
    assignmentId: string
    assignmentTitle: string
    candidateId: string
    candidateFullName: string
    status: 'PENDING' | 'RUNNING' | 'DONE' | 'ERROR'
    createdAt: string
    totalScore?: number
    verdict?: 'ACCEPTED' | 'REJECTED'
    verdictComment?: string
    completedAt?: string
  } = {
    id: submission.id,
    assignmentId: submission.assignmentId,
    assignmentTitle: submission.assignmentTitle,
    candidateId: submission.candidateId,
    candidateFullName: submission.candidateName,
    status: submission.status === 'pending' ? 'PENDING' : submission.status === 'running' ? 'RUNNING' : submission.status === 'error' ? 'ERROR' : 'DONE',
    createdAt: submission.uploadedAt,
  }
  if (submission.score != null) raw.totalScore = submission.score
  if (submission.verdict !== 'none') raw.verdict = submission.verdict === 'accepted' ? 'ACCEPTED' : 'REJECTED'
  if (submission.completedAt) raw.completedAt = submission.completedAt
  return raw
}

function toRawSubmissionStatus(submission: Submission) {
  const raw: {
    id: string
    status: 'PENDING' | 'RUNNING' | 'DONE' | 'ERROR'
    totalScore?: number
  } = {
    id: submission.id,
    status: submission.status === 'pending' ? 'PENDING' : submission.status === 'running' ? 'RUNNING' : submission.status === 'error' ? 'ERROR' : 'DONE',
  }
  if (submission.score != null) raw.totalScore = submission.score
  return raw
}

function toIsoFromDuration(durationMs: number, offset = 0) {
  return new Date(Date.now() - durationMs + offset).toISOString()
}

function toRawResult(result: CheckResult) {
  return {
    id: result.id,
    checkerType: checkerToRaw[result.checker],
    status:
      result.status === 'pending'
        ? 'PENDING'
        : result.status === 'running'
          ? 'RUNNING'
          : result.status === 'passed'
            ? 'PASSED'
            : result.status === 'failed'
              ? 'FAILED'
              : 'ERROR',
    score: result.score,
    log: result.details,
    startedAt: toIsoFromDuration(result.durationMs),
    finishedAt: toIsoFromDuration(0),
  }
}

function toRawAiReview(review: AiReview) {
  if (!review.available) {
    return { available: false }
  }
  return {
    available: review.available,
    summary: review.summary,
    strengths: review.good,
    weaknesses: review.improvements,
    recommendations: review.remarks,
  }
}

function toRawCandidate(candidate: { id: string; email: string; fullName: string }) {
  const submissions = db.submissions.filter((item) => item.candidateId === candidate.id)
  return {
    id: candidate.id,
    email: candidate.email,
    fullName: candidate.fullName,
    submissionsCount: submissions.length,
    bestScore: Math.max(0, ...submissions.map((item) => item.score ?? 0)) || null,
  }
}

function recalculateSubmission(submission: Submission) {
  const results = db.results.filter((result) => result.submissionId === submission.id)
  if (!results.length || submission.status === 'pending' || submission.status === 'running') {
    return submission
  }
  const score = Math.round(results.reduce((sum, result) => sum + result.score, 0) / results.length)
  return { ...submission, score, status: score >= 60 ? ('passed' as const) : ('failed' as const) }
}

function createSyntheticResults(submission: Submission) {
  const checkers = ['StaticAnalysis', 'Architecture', 'Build', 'Tests', 'Documentation', 'GitPractices'] as const
  return checkers.map((checker, index): CheckResult => {
    const score = Math.max(42, Math.min(98, 92 - index * 7))
    return {
      id: `${submission.id}-${checker}`,
      submissionId: submission.id,
      checker,
      status: score >= 60 ? 'passed' : 'failed',
      score,
      message: score >= 80 ? 'Проверка успешно пройдена' : 'Есть предупреждения',
      details: `[${checker}]: mock-проверка выполнена\nФайл: ${submission.fileName ?? submission.gitUrl}\nОценка: ${score}/100`,
      durationMs: 1000 + index * 550,
    }
  })
}

function scheduleProgress(submissionId: string) {
  window.setTimeout(() => {
    const submission = findSubmission(submissionId)
    if (!submission || submission.status !== 'pending') return
    replaceSubmission({ ...submission, status: 'running' })
  }, 1200)

  window.setTimeout(() => {
    const submission = findSubmission(submissionId)
    if (!submission || submission.status !== 'running') return
    const results = createSyntheticResults(submission)
    db.results = db.results.filter((result) => result.submissionId !== submissionId).concat(results)
    const next = recalculateSubmission({ ...submission, status: 'passed', completedAt: new Date().toISOString() })
    replaceSubmission(next)
    db.aiReviews.set(submissionId, {
      available: true,
      summary: 'Автоматическая проверка завершена. Код собирается, архитектура читаемая, но тесты можно усилить.',
      good: ['Проект успешно собирается', 'Слои domain/data/presentation обнаружены', 'README присутствует'],
      improvements: ['Добавить тесты на ошибки API', 'Убрать дублирование форматирования дат', 'Расширить комментарии публичных методов'],
      remarks: ['AI-анализ сформирован мок-сервером для демонстрации graceful flow'],
    } satisfies AiReview)
  }, 4200)
}

function filterSubmissions(url: URL) {
  const search = url.searchParams.get('search')?.toLowerCase() ?? ''
  const assignmentId = url.searchParams.get('assignmentId') ?? ''
  const statuses = (url.searchParams.get('status')?.split(',').filter(Boolean) ?? []) as SubmissionStatus[]
  const dateFrom = url.searchParams.get('dateFrom') ?? ''
  const dateTo = url.searchParams.get('dateTo') ?? ''
  const page = Number(url.searchParams.get('page') ?? 1)
  const limit = Number(url.searchParams.get('limit') ?? 50)

  let items = [...db.submissions]
  if (search) {
    items = items.filter(
      (item) =>
        item.candidateName.toLowerCase().includes(search) ||
        item.assignmentTitle.toLowerCase().includes(search) ||
        item.candidateEmail.toLowerCase().includes(search),
    )
  }
  if (assignmentId) {
    items = items.filter((item) => item.assignmentId === assignmentId)
  }
  if (statuses.length) {
    items = items.filter((item) => statuses.includes(item.status))
  }
  if (dateFrom) {
    items = items.filter((item) => item.uploadedAt >= new Date(dateFrom).toISOString())
  }
  if (dateTo) {
    items = items.filter((item) => item.uploadedAt <= new Date(dateTo).toISOString())
  }

  return {
    items: items.slice((page - 1) * limit, page * limit),
  }
}

export const handlers = [
  http.post(`${api}/auth/login`, async ({ request }) => {
    await withLatency()
    const body = (await request.json()) as { email: string; password: string }
    const user = db.users.find((item) => item.email === body.email && item.password === body.password)
    if (!user) {
      return fail(422, {
        code: 'VALIDATION_ERROR',
        message: 'Неверный email или пароль',
        details: { email: 'Проверьте демо-логин', password: 'Пароль: password' },
      })
    }
    return ok({
      token: `mock-${user.role}-token`,
      expiresIn: 86_400_000,
    })
  }),

  http.post(`${api}/auth/logout`, async () => {
    await withLatency()
    return emptyOk()
  }),

  http.get(`${api}/auth/profile`, async ({ request }) => {
    await withLatency()
    const { response, user } = requireAuth(request)
    return response ?? ok(toRawUser(user))
  }),

  http.get(`${api}/assignments`, async ({ request }) => {
    await withLatency()
    const { response } = requireAuth(request)
    return response ?? ok(db.assignments.map(toRawAssignment))
  }),

  http.get(`${api}/assignments/:id`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const assignment = db.assignments.find((item) => item.id === params.id)
    return assignment ? ok(toRawAssignment(assignment)) : fail(404, { code: 'NOT_FOUND', message: 'Задание не найдено' })
  }),

  http.post(`${api}/assignments`, async ({ request }) => {
    await withLatency()
    const { response, user } = requireAuth(request)
    if (response) return response
    if (user?.role !== 'expert') return fail(403, { code: 'FORBIDDEN', message: 'Создавать задания может только эксперт' })
    const body = (await request.json()) as {
      title: string
      description?: string | null
      checkerWeights?: Record<string, number>
    }
    const totalWeight = Object.values(body.checkerWeights ?? {}).reduce((sum, item) => sum + item, 0)
    if (!body.title || totalWeight !== 100) {
      return fail(422, {
        code: 'VALIDATION_ERROR',
        message: 'Проверьте форму задания',
        details: {
          ...(body.title ? {} : { title: 'Название обязательно' }),
          ...(totalWeight === 100 ? {} : { checkerWeights: 'Сумма весов должна быть 100%' }),
        },
      })
    }
    const assignment: Assignment = {
      id: `a${db.assignments.length + 1}`,
      createdAt: new Date().toISOString(),
      title: body.title,
      description: body.description ?? '',
      technologies: [],
      instructionsMarkdown: '',
      status: 'published',
      checkerConfig: Object.entries(body.checkerWeights ?? {}).map(([checker, weight]) => ({
        checker: rawToChecker[checker],
        enabled: true,
        weight,
      })),
    }
    upsertAssignment(assignment)
    return ok(toRawAssignment(assignment), 201)
  }),

  http.get(`${api}/submissions`, async ({ request }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const url = new URL(request.url)
    const { items } = filterSubmissions(url)
    return ok(items.map(toRawSubmission))
  }),

  http.post(`${api}/submissions`, async ({ request }) => {
    await withLatency()
    const { response, user } = requireAuth(request)
    if (response) return response
    if (user?.role !== 'expert') return fail(403, { code: 'FORBIDDEN', message: 'Загружать решения через dashboard может только эксперт' })
    const form = await request.formData()
    const assignmentId = String(form.get('assignmentId') ?? '')
    const candidateName = String(form.get('candidateFullName') ?? form.get('candidateName') ?? '')
    const candidateEmail = String(form.get('candidateEmail') ?? '')
    const gitUrl = String(form.get('gitUrl') ?? '')
    const file = form.get('file') as File | null
    const assignment = db.assignments.find((item) => item.id === assignmentId)
    if (!assignment || !candidateName || !candidateEmail || (!gitUrl && !file)) {
      return fail(422, {
        code: 'VALIDATION_ERROR',
        message: 'Проверьте поля загрузки',
        details: { assignmentId: 'Выберите задание', candidateFullName: 'ФИО обязательно', candidateEmail: 'Email обязателен' },
      })
    }
    const candidate = db.candidates.find((item) => item.email === candidateEmail) ?? {
      id: `c${db.candidates.length + 1}`,
      fullName: candidateName,
      email: candidateEmail,
      specialization: 'Mobile Developer',
    }
    if (!db.candidates.find((item) => item.id === candidate.id)) {
      db.candidates.push(candidate)
    }
    const submission: Submission = {
      id: `s${db.submissions.length + 1}`,
      assignmentId,
      assignmentTitle: assignment.title,
      candidateId: candidate.id,
      candidateName,
      candidateEmail,
      sourceType: gitUrl ? 'git' : 'zip',
      gitUrl: gitUrl || undefined,
      fileName: file?.name,
      status: 'pending',
      score: null,
      verdict: 'none',
      uploadedAt: new Date().toISOString(),
    }
    db.submissions.unshift(submission)
    scheduleProgress(submission.id)
    return ok(toRawSubmission(submission), 201)
  }),

  http.get(`${api}/submissions/:id`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const submission = findSubmission(String(params.id))
    return submission ? ok(toRawSubmission(submission)) : fail(404, { code: 'NOT_FOUND', message: 'Проверка не найдена' })
  }),

  http.get(`${api}/submissions/:id/status`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const submission = findSubmission(String(params.id))
    return submission ? ok(toRawSubmissionStatus(submission)) : fail(404, { code: 'NOT_FOUND', message: 'Проверка не найдена' })
  }),

  http.get(`${api}/submissions/:id/results`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    return ok(db.results.filter((result) => result.submissionId === params.id).map(toRawResult))
  }),

  http.post(`${api}/submissions/:id/rerun`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const submission = findSubmission(String(params.id))
    if (!submission) return fail(404, { code: 'NOT_FOUND', message: 'Проверка не найдена' })
    const next = { ...submission, status: 'pending' as const, score: null, verdict: 'none' as const, completedAt: undefined }
    replaceSubmission(next)
    scheduleProgress(next.id)
    return ok(toRawSubmission(next))
  }),

  http.put(`${api}/submissions/:id/verdict`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const body = (await request.json()) as { verdict: 'ACCEPTED' | 'REJECTED' | 'accepted' | 'rejected'; comment?: string | null }
    const submission = findSubmission(String(params.id))
    if (!submission) return fail(404, { code: 'NOT_FOUND', message: 'Проверка не найдена' })
    const next = { ...submission, verdict: body.verdict === 'ACCEPTED' || body.verdict === 'accepted' ? ('accepted' as const) : ('rejected' as const) }
    replaceSubmission(next)
    return ok(toRawSubmission(next))
  }),

  http.get(`${api}/submissions/:id/ai-review`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    return ok(toRawAiReview(db.aiReviews.get(String(params.id)) ?? { available: false, errorMessage: 'AI-анализ недоступен' }))
  }),

  http.get(`${api}/submissions/:id/report`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const submission = findSubmission(String(params.id))
    return submission ? ok(toRawSubmission(submission)) : fail(404, { code: 'NOT_FOUND', message: 'Проверка не найдена' })
  }),

  http.get(`${api}/candidates`, async ({ request }) => {
    await withLatency()
    const { response } = requireAuth(request)
    return response ?? ok(db.candidates.map(toRawCandidate))
  }),

  http.get(`${api}/candidates/:id`, async ({ request, params }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const candidate = db.candidates.find((item) => item.id === params.id)
    return candidate ? ok(toRawCandidate(candidate)) : fail(404, { code: 'NOT_FOUND', message: 'Кандидат не найден' })
  }),

  http.get(`${api}/reports/stats`, async ({ request }) => {
    await withLatency()
    const { response } = requireAuth(request)
    if (response) return response
    const completed = db.submissions.filter((item) => item.score != null)
    const accepted = db.submissions.filter((item) => item.verdict === 'accepted').length
    const averageScore = completed.length
      ? Math.round(completed.reduce((sum, item) => sum + (item.score ?? 0), 0) / completed.length)
      : 0
    const topCandidates = db.candidates.slice(0, 10).map((candidate) => {
      const attempts = db.submissions.filter((item) => item.candidateId === candidate.id)
      return {
        id: candidate.id,
        fullName: candidate.fullName,
        bestScore: Math.max(0, ...attempts.map((item) => item.score ?? 0)),
        attempts: attempts.length,
      }
    })
    return ok({
      totalSubmissions: db.submissions.length,
      averageScore,
      passRate: Math.round((accepted / Math.max(1, db.submissions.length)) * 1000) / 10,
      dailyCounts: Array.from({ length: 30 }, (_, index) => ({
        date: `2026-05-${String(index + 1).padStart(2, '0')}`,
        count: 2 + ((index * 3) % 9),
      })),
      topCandidates: topCandidates.map((candidate) => ({
        candidateId: candidate.id,
        fullName: candidate.fullName,
        bestScore: candidate.bestScore,
      })),
    })
  }),
]

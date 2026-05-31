import type { AiReview, Assignment, Candidate, CheckResult, Submission, TimelineEvent } from '../shared/api/types'

const checkerNames = ['StaticAnalysis', 'Architecture', 'Build', 'Tests', 'Documentation', 'GitPractices'] as const

export const users = [
  {
    id: 'u-expert',
    fullName: 'Алексей Морозов',
    email: 'expert@autocheck.local',
    password: 'password',
    role: 'expert' as const,
  },
  {
    id: 'u-candidate',
    fullName: 'Иван Петров',
    email: 'candidate@autocheck.local',
    password: 'password',
    role: 'candidate' as const,
  },
]

export const assignmentsSeed: Assignment[] = [
  {
    id: 'a1',
    title: 'Flutter Auth Screen',
    description: 'Реализовать экран авторизации кандидата с валидацией и сетевым слоем.',
    technologies: ['Flutter', 'Dart'],
    status: 'published',
    createdAt: '2026-05-25T10:00:00Z',
    instructionsMarkdown: 'Соблюдать clean architecture, обработать loading/error состояния.',
    checkerConfig: [
      { checker: 'StaticAnalysis', enabled: true, weight: 20 },
      { checker: 'Architecture', enabled: true, weight: 20 },
      { checker: 'Build', enabled: true, weight: 20 },
      { checker: 'Tests', enabled: true, weight: 20 },
      { checker: 'Documentation', enabled: true, weight: 10 },
      { checker: 'GitPractices', enabled: true, weight: 10 },
    ],
  },
  {
    id: 'a2',
    title: 'Kotlin Candidate Board',
    description: 'Собрать Android экран списка кандидатов и карточку результата проверки.',
    technologies: ['Kotlin', 'Android'],
    status: 'published',
    createdAt: '2026-05-26T11:20:00Z',
    instructionsMarkdown: 'Нужны ViewModel, Repository и unit-тесты.',
    checkerConfig: [
      { checker: 'StaticAnalysis', enabled: true, weight: 20 },
      { checker: 'Architecture', enabled: true, weight: 25 },
      { checker: 'Build', enabled: true, weight: 20 },
      { checker: 'Tests', enabled: true, weight: 15 },
      { checker: 'Documentation', enabled: true, weight: 10 },
      { checker: 'GitPractices', enabled: true, weight: 10 },
    ],
  },
  {
    id: 'a3',
    title: 'React Native Results',
    description: 'Мобильный экран результатов проверки с раскрытием логов чекеров.',
    technologies: ['React Native', 'TypeScript'],
    status: 'published',
    createdAt: '2026-05-27T09:40:00Z',
    instructionsMarkdown: 'Сделать компонент ResultRow и обработать AI fallback.',
    checkerConfig: [
      { checker: 'StaticAnalysis', enabled: true, weight: 15 },
      { checker: 'Architecture', enabled: true, weight: 25 },
      { checker: 'Build', enabled: true, weight: 20 },
      { checker: 'Tests', enabled: true, weight: 20 },
      { checker: 'Documentation', enabled: true, weight: 10 },
      { checker: 'GitPractices', enabled: true, weight: 10 },
    ],
  },
]

export const candidatesSeed: Candidate[] = [
  { id: 'c1', fullName: 'Иван Петров', email: 'ivan.petrov@test.ru', specialization: 'Flutter Developer' },
  { id: 'c2', fullName: 'Мария Соколова', email: 'maria.sokolova@test.ru', specialization: 'Android Developer' },
  { id: 'c3', fullName: 'Артём Волков', email: 'artem.volkov@test.ru', specialization: 'React Native Developer' },
  { id: 'c4', fullName: 'Дарья Ким', email: 'daria.kim@test.ru', specialization: 'iOS Developer' },
  { id: 'c5', fullName: 'Никита Орлов', email: 'nikita.orlov@test.ru', specialization: 'Mobile QA Automation' },
  { id: 'c6', fullName: 'София Лебедева', email: 'sofia.lebedeva@test.ru', specialization: 'Flutter Developer' },
  { id: 'c7', fullName: 'Павел Егоров', email: 'pavel.egorov@test.ru', specialization: 'Kotlin Developer' },
  { id: 'c8', fullName: 'Елена Смирнова', email: 'elena.smirnova@test.ru', specialization: 'Cross-platform Developer' },
]

function dateAgo(index: number) {
  const date = new Date('2026-05-31T09:00:00Z')
  date.setDate(date.getDate() - index)
  date.setHours(8 + (index % 8), 10 + (index % 40), 0, 0)
  return date.toISOString()
}

export function createSubmissionsSeed() {
  const statuses = ['passed', 'failed', 'running', 'pending', 'error'] as const
  return Array.from({ length: 48 }, (_, index): Submission => {
    const candidate = candidatesSeed[index % candidatesSeed.length]
    const assignment = assignmentsSeed[index % assignmentsSeed.length]
    const status = statuses[index % statuses.length]
    const score =
      status === 'pending' || status === 'running'
        ? null
        : status === 'passed'
          ? 78 + ((index * 5) % 20)
          : status === 'failed'
            ? 34 + ((index * 7) % 24)
            : 0
    return {
      id: `s${index + 1}`,
      assignmentId: assignment.id,
      assignmentTitle: assignment.title,
      candidateId: candidate.id,
      candidateName: candidate.fullName,
      candidateEmail: candidate.email,
      sourceType: index % 3 === 0 ? 'git' : 'zip',
      gitUrl: index % 3 === 0 ? `https://git.example.ru/${candidate.id}/solution-${index + 1}` : undefined,
      fileName: index % 3 === 0 ? undefined : `solution-${index + 1}.zip`,
      status,
      score,
      verdict: score && score >= 80 ? 'accepted' : score && score < 50 ? 'rejected' : 'none',
      uploadedAt: dateAgo(index),
      completedAt: score ? dateAgo(Math.max(0, index - 1)) : undefined,
    }
  })
}

export function createResultsSeed(submissions: Submission[]) {
  const results: CheckResult[] = []
  for (const submission of submissions) {
    checkerNames.forEach((checker, index) => {
      const score =
        submission.score == null
          ? submission.status === 'running' && index < 2
            ? 80 - index * 6
            : 0
          : Math.max(0, Math.min(100, submission.score + (index - 2) * 5))
      results.push({
        id: `${submission.id}-${checker}`,
        submissionId: submission.id,
        checker,
        status: submission.status === 'pending' ? 'pending' : submission.status === 'error' && index === 2 ? 'error' : score >= 60 ? 'passed' : 'failed',
        score,
        message:
          score >= 80
            ? 'Требования выполнены'
            : score >= 60
              ? 'Есть предупреждения'
              : 'Найдены критические замечания',
        details: [
          `[${checker}]: Запуск проверки для ${submission.assignmentTitle}`,
          `Кандидат: ${submission.candidateName}`,
          `Результат: ${score}/100`,
          score >= 80 ? 'Нарушений не обнаружено.' : 'Требуется исправить архитектурные замечания и добавить тесты.',
        ].join('\n'),
        durationMs: 1200 + index * 650,
      })
    })
  }
  return results
}

export function createAiReviewsSeed(submissions: Submission[]) {
  const reviews = new Map<string, AiReview>()
  submissions.forEach((submission, index) => {
    reviews.set(
      submission.id,
      index % 4 === 0
        ? { available: false, errorMessage: 'AI-анализ недоступен: не задан AI_API_KEY' }
        : {
            available: true,
            summary: 'Решение в целом соответствует заданию, но требует усилить тесты и обработку ошибок.',
            good: ['Есть разделение на слои', 'UI-компоненты переиспользуются', 'Сетевой слой не смешан с представлением'],
            improvements: ['Добавить больше unit-тестов', 'Улучшить сообщения об ошибках', 'Описать запуск проекта в README'],
            remarks: ['Некоторые публичные методы без комментариев', 'Часть логов не содержит контекст', 'Не все edge cases покрыты проверками'],
          },
    )
  })
  return reviews
}

export function createTimeline(submission: Submission): TimelineEvent[] {
  return [
    { id: 't1', label: 'Решение загружено', at: submission.uploadedAt, status: 'done' },
    { id: 't2', label: 'Задача поставлена в очередь', at: submission.uploadedAt, status: 'done' },
    { id: 't3', label: 'Запущены чекеры', at: submission.uploadedAt, status: submission.status === 'pending' ? 'active' : 'done' },
    { id: 't4', label: 'Результаты рассчитаны', at: submission.completedAt ?? submission.uploadedAt, status: submission.score == null ? 'muted' : 'done' },
    { id: 't5', label: 'Вердикт эксперта', at: submission.completedAt ?? submission.uploadedAt, status: submission.verdict === 'none' ? 'muted' : 'done' },
  ]
}

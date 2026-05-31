export type UserRole = 'expert' | 'candidate'
export type SubmissionStatus = 'pending' | 'running' | 'passed' | 'failed' | 'error'
export type Verdict = 'accepted' | 'rejected' | 'none'
export type AssignmentStatus = 'draft' | 'published'
export type SourceType = 'zip' | 'git'
export type CheckerName =
  | 'StaticAnalysis'
  | 'Architecture'
  | 'Build'
  | 'Tests'
  | 'Documentation'
  | 'GitPractices'

export type ApiError = {
  code: string
  message: string
  fields?: Record<string, string>
  details?: Record<string, string>
}

export type PaginatedMeta = {
  page: number
  limit: number
  total: number
  totalPages: number
}

export type User = {
  id: string
  fullName: string
  email: string
  role: UserRole
}

export type LoginRequest = {
  email: string
  password: string
}

export type RegisterRequest = LoginRequest & {
  fullName: string
  role: UserRole
}

export type TokenResponse = {
  token: string
  expiresIn?: number
}

export type CheckerConfig = {
  checker: CheckerName
  enabled: boolean
  weight: number
}

export type Assignment = {
  id: string
  title: string
  description: string
  technologies: string[]
  checkerConfig: CheckerConfig[]
  instructionsMarkdown: string
  status: AssignmentStatus
  createdAt: string
}

export type CreateAssignmentRequest = {
  title: string
  description: string
  technologies: string[]
  checkerConfig: CheckerConfig[]
  instructionsMarkdown: string
  status: AssignmentStatus
}

export type Candidate = {
  id: string
  fullName: string
  email: string
  specialization: string
}

export type Submission = {
  id: string
  assignmentId: string
  assignmentTitle: string
  candidateId: string
  candidateName: string
  candidateEmail: string
  sourceType: SourceType
  gitUrl?: string
  fileName?: string
  status: SubmissionStatus
  score: number | null
  verdict: Verdict
  uploadedAt: string
  completedAt?: string
}

export type CreateSubmissionRequest = {
  assignmentId: string
  candidateName: string
  candidateEmail: string
  file?: File | null
  gitUrl?: string
}

export type SubmissionFilters = {
  search?: string
  assignmentId?: string
  statuses?: SubmissionStatus[]
  dateFrom?: string
  dateTo?: string
  page?: number
  limit?: number
  mine?: boolean
}

export type CheckResult = {
  id: string
  submissionId: string
  checker: CheckerName
  status: SubmissionStatus
  score: number
  message: string
  details: string
  durationMs: number
}

export type AiReview = {
  available: boolean
  summary?: string
  good?: string[]
  improvements?: string[]
  remarks?: string[]
  errorMessage?: string
}

export type ReportStats = {
  totalSubmissions30d: number
  averageScore: number
  passRate: number
  awaitingReview: number
  dailySubmissions: { date: string; count: number; passed: number; failed: number }[]
  topCandidates: { id: string; fullName: string; bestScore: number; attempts: number }[]
}

export type TimelineEvent = {
  id: string
  label: string
  at: string
  status: 'done' | 'active' | 'muted'
}

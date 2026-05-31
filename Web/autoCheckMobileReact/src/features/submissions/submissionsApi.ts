import { baseApi } from '../../shared/api/baseApi'
import { normalizeAiReview, normalizeApiSubmissionStatus, normalizeCheckResult, normalizeSubmission } from '../../shared/api/adapters'
import type {
  AiReview,
  CheckResult,
  CreateSubmissionRequest,
  PaginatedMeta,
  Submission,
  SubmissionFilters,
  Verdict,
} from '../../shared/api/types'

type SubmissionList = {
  items: Submission[]
  meta: PaginatedMeta
}

type SubmissionStatusResponse = {
  id: string | number
  status: 'PENDING' | 'RUNNING' | 'DONE' | 'ERROR' | Submission['status']
  totalScore?: number | null
  score?: number | null
}

export const submissionsApi = baseApi.injectEndpoints({
  endpoints: (builder) => ({
    getSubmissions: builder.query<SubmissionList, SubmissionFilters | void>({
      query: (filters) => ({
        url: '/submissions',
        params: {
          assignmentId: filters?.assignmentId,
        },
      }),
      transformResponse: (response: Submission[], _meta, filters) => {
        const page = filters?.page ?? 1
        const limit = filters?.limit ?? 50
        let items = response.map(normalizeSubmission)
        if (filters?.search) {
          const search = filters.search.toLowerCase()
          items = items.filter(
            (item) =>
              item.candidateName.toLowerCase().includes(search) ||
              item.assignmentTitle.toLowerCase().includes(search) ||
              item.candidateEmail.toLowerCase().includes(search),
          )
        }
        if (filters?.statuses?.length) {
          items = items.filter((item) => filters.statuses?.includes(item.status))
        }
        if (filters?.dateFrom) {
          items = items.filter((item) => item.uploadedAt >= new Date(filters.dateFrom as string).toISOString())
        }
        if (filters?.dateTo) {
          items = items.filter((item) => item.uploadedAt <= new Date(filters.dateTo as string).toISOString())
        }
        const total = items.length
        const paged = items.slice((page - 1) * limit, page * limit)
        return {
          items: paged,
          meta: { page, limit, total, totalPages: Math.max(1, Math.ceil(total / limit)) } satisfies PaginatedMeta,
        }
      },
      providesTags: (result) =>
        result
          ? [
              ...result.items.map((submission) => ({ type: 'Submission' as const, id: submission.id })),
              { type: 'Submission', id: 'LIST' },
            ]
          : [{ type: 'Submission', id: 'LIST' }],
    }),
    getSubmissionById: builder.query<Submission, string>({
      query: (id) => `/submissions/${id}`,
      transformResponse: (response: Submission) => normalizeSubmission(response),
      providesTags: (_, __, id) => [{ type: 'Submission', id }],
    }),
    getSubmissionResults: builder.query<CheckResult[], string>({
      query: (id) => `/submissions/${id}/results`,
      transformResponse: (response: CheckResult[]) => response.map(normalizeCheckResult),
      providesTags: (_, __, id) => [{ type: 'CheckResult', id }],
    }),
    getSubmissionStatus: builder.query<Pick<Submission, 'id' | 'status' | 'score'>, string>({
      query: (id) => `/submissions/${id}/status`,
      transformResponse: (response: SubmissionStatusResponse) => {
        const score = response.totalScore ?? response.score ?? null
        return { id: String(response.id), status: normalizeApiSubmissionStatus(response.status, score), score }
      },
      providesTags: (_, __, id) => [{ type: 'Submission', id }],
    }),
    createSubmission: builder.mutation<Submission, CreateSubmissionRequest>({
      query: (request) => {
        const formData = new FormData()
        formData.append('assignmentId', request.assignmentId)
        formData.append('candidateFullName', request.candidateName)
        formData.append('candidateEmail', request.candidateEmail)
        if (request.gitUrl) {
          formData.append('gitUrl', request.gitUrl)
        }
        if (request.file) {
          formData.append('file', request.file)
        }
        return {
          url: '/submissions',
          method: 'POST',
          body: formData,
        }
      },
      transformResponse: (response: Submission) => normalizeSubmission(response),
      invalidatesTags: [{ type: 'Submission', id: 'LIST' }, 'Report'],
    }),
    rerunSubmission: builder.mutation<Submission, string>({
      query: (id) => ({
        url: `/submissions/${id}/rerun`,
        method: 'POST',
      }),
      transformResponse: (response: Submission) => normalizeSubmission(response),
      invalidatesTags: (_, __, id) => [
        { type: 'Submission', id },
        { type: 'CheckResult', id },
        { type: 'AiReview', id },
        'Report',
      ],
    }),
    updateVerdict: builder.mutation<Submission, { id: string; verdict: Exclude<Verdict, 'none'>; comment: string }>({
      query: ({ id, verdict, comment }) => ({
        url: `/submissions/${id}/verdict`,
        method: 'PUT',
        body: { verdict: verdict === 'accepted' ? 'ACCEPTED' : 'REJECTED', comment },
      }),
      transformResponse: (response: Submission) => normalizeSubmission(response),
      invalidatesTags: (_, __, { id }) => [{ type: 'Submission', id }, 'Report'],
    }),
    getAiReview: builder.query<AiReview, string>({
      query: (id) => `/submissions/${id}/ai-review`,
      transformResponse: (response: AiReview) => normalizeAiReview(response),
      providesTags: (_, __, id) => [{ type: 'AiReview', id }],
    }),
    getSubmissionReport: builder.query<string, string>({
      query: (id) => `/submissions/${id}/report`,
      transformResponse: (response: unknown) => JSON.stringify(response ?? {}, null, 2),
    }),
  }),
})

export const {
  useCreateSubmissionMutation,
  useGetAiReviewQuery,
  useGetSubmissionByIdQuery,
  useGetSubmissionReportQuery,
  useGetSubmissionResultsQuery,
  useGetSubmissionStatusQuery,
  useGetSubmissionsQuery,
  useLazyGetSubmissionReportQuery,
  useRerunSubmissionMutation,
  useUpdateVerdictMutation,
} = submissionsApi

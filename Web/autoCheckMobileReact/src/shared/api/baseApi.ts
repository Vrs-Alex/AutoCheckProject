import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'
import type { BaseQueryFn, FetchArgs, FetchBaseQueryError } from '@reduxjs/toolkit/query'
import type { RootState } from '../../app/store'
import { appLogger } from '../lib/appLogger'

const apiUrl = import.meta.env.VITE_API_URL ?? '/api/v1'

type ApiEnvelope = {
  data?: unknown
  error?: unknown
  meta?: unknown
}

function isApiEnvelope(value: unknown): value is ApiEnvelope {
  return Boolean(
    value &&
      typeof value === 'object' &&
      ('data' in value || 'error' in value || 'meta' in value),
  )
}

function requestLabel(args: string | FetchArgs) {
  if (typeof args === 'string') {
    return args
  }

  const method = args.method ?? 'GET'
  return `${method} ${args.url}`
}

const rawBaseQuery = fetchBaseQuery({
  baseUrl: apiUrl,
  prepareHeaders: (headers, { getState }) => {
    const token = (getState() as RootState).auth.token
    if (token) {
      headers.set('Authorization', `Bearer ${token}`)
    }
    return headers
  },
})

const baseQuery: BaseQueryFn<string | FetchArgs, unknown, FetchBaseQueryError> = async (
  args,
  api,
  extraOptions,
) => {
  const endpoint = requestLabel(args)
  appLogger.info('BaseApi', 'API request started', { endpoint })

  const result = await rawBaseQuery(args, api, extraOptions)
  if ('error' in result) {
    appLogger.error('BaseApi', 'API request failed', { endpoint, error: result.error })
    return result
  }

  appLogger.debug('BaseApi', 'API request completed', { endpoint })

  if (isApiEnvelope(result.data)) {
    return { ...result, data: result.data.data ?? null }
  }
  return result
}

/**
 * Назначение: общий RTK Query API client layer для всех запросов AutoCheck.
 * Логирует старт, успешное завершение и ошибки запросов в едином формате.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export const baseApi = createApi({
  reducerPath: 'api',
  baseQuery,
  tagTypes: ['Auth', 'Assignment', 'Submission', 'CheckResult', 'Candidate', 'Report', 'AiReview'],
  endpoints: () => ({}),
})

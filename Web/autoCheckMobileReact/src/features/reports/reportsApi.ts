import { baseApi } from '../../shared/api/baseApi'
import { normalizeStats } from '../../shared/api/adapters'
import type { ReportStats } from '../../shared/api/types'

export const reportsApi = baseApi.injectEndpoints({
  endpoints: (builder) => ({
    getStats: builder.query<ReportStats, void>({
      query: () => '/reports/stats',
      transformResponse: (response: ReportStats) => normalizeStats(response),
      providesTags: ['Report'],
    }),
  }),
})

export const { useGetStatsQuery } = reportsApi

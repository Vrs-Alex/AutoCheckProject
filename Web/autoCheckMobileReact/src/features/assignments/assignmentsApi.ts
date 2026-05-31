import { baseApi } from '../../shared/api/baseApi'
import { normalizeAssignment, toApiCheckerWeights } from '../../shared/api/adapters'
import type { Assignment, CreateAssignmentRequest } from '../../shared/api/types'

export const assignmentsApi = baseApi.injectEndpoints({
  endpoints: (builder) => ({
    getAssignments: builder.query<Assignment[], void>({
      query: () => '/assignments',
      transformResponse: (response: Assignment[]) => response.map(normalizeAssignment),
      providesTags: (result) =>
        result
          ? [
              ...result.map((assignment) => ({ type: 'Assignment' as const, id: assignment.id })),
              { type: 'Assignment', id: 'LIST' },
            ]
          : [{ type: 'Assignment', id: 'LIST' }],
    }),
    getAssignmentById: builder.query<Assignment, string>({
      query: (id) => `/assignments/${id}`,
      transformResponse: (response: Assignment) => normalizeAssignment(response),
      providesTags: (_, __, id) => [{ type: 'Assignment', id }],
    }),
    createAssignment: builder.mutation<Assignment, CreateAssignmentRequest>({
      query: (body) => ({
        url: '/assignments',
        method: 'POST',
        body: {
          title: body.title,
          description: body.description,
          checkerWeights: toApiCheckerWeights(body.checkerConfig),
        },
      }),
      transformResponse: (response: Assignment) => normalizeAssignment(response),
      invalidatesTags: [{ type: 'Assignment', id: 'LIST' }],
    }),
  }),
})

export const { useCreateAssignmentMutation, useGetAssignmentByIdQuery, useGetAssignmentsQuery } =
  assignmentsApi

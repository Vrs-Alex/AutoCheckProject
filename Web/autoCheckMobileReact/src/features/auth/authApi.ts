import { baseApi } from '../../shared/api/baseApi'
import { normalizeUser } from '../../shared/api/adapters'
import type { LoginRequest, RegisterRequest, TokenResponse, User } from '../../shared/api/types'
import { logoutLocal, setToken, setUser } from './authSlice'

export const authApi = baseApi.injectEndpoints({
  endpoints: (builder) => ({
    login: builder.mutation<TokenResponse, LoginRequest>({
      query: (body) => ({
        url: '/auth/login',
        method: 'POST',
        body,
      }),
      transformResponse: (response: TokenResponse) => response,
      async onQueryStarted(_, { dispatch, queryFulfilled }) {
        const { data } = await queryFulfilled
        dispatch(setToken(data.token))
        dispatch(authApi.endpoints.profile.initiate(undefined, { forceRefetch: true }))
      },
      invalidatesTags: ['Auth'],
    }),
    register: builder.mutation<TokenResponse, RegisterRequest>({
      query: (body) => ({
        url: '/auth/register',
        method: 'POST',
        body: {
          email: body.email,
          password: body.password,
          fullName: body.fullName,
          role: body.role === 'expert' ? 'EXPERT' : 'CANDIDATE',
        },
      }),
      transformResponse: (response: TokenResponse) => response,
      async onQueryStarted(_, { dispatch, queryFulfilled }) {
        const { data } = await queryFulfilled
        dispatch(setToken(data.token))
        dispatch(authApi.endpoints.profile.initiate(undefined, { forceRefetch: true }))
      },
      invalidatesTags: ['Auth'],
    }),
    profile: builder.query<User, void>({
      query: () => '/auth/profile',
      transformResponse: (response: User) => normalizeUser(response),
      async onQueryStarted(_, { dispatch, queryFulfilled }) {
        const { data } = await queryFulfilled
        dispatch(setUser(data))
      },
      providesTags: ['Auth'],
    }),
    logout: builder.mutation<void, void>({
      query: () => ({
        url: '/auth/logout',
        method: 'POST',
      }),
      async onQueryStarted(_, { dispatch, queryFulfilled }) {
        try {
          await queryFulfilled
        } finally {
          dispatch(logoutLocal())
          dispatch(baseApi.util.resetApiState())
        }
      },
    }),
  }),
})

export const { useLoginMutation, useLogoutMutation, useProfileQuery, useRegisterMutation } = authApi

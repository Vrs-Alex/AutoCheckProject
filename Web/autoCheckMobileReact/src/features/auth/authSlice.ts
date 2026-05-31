import { createSlice, type PayloadAction } from '@reduxjs/toolkit'
import type { User } from '../../shared/api/types'

type AuthState = {
  token: string | null
  user: User | null
  isAuthenticated: boolean
}

const savedToken = localStorage.getItem('autocheck.token')
const savedUser = localStorage.getItem('autocheck.user')

const initialState: AuthState = {
  token: savedToken,
  user: savedUser ? (JSON.parse(savedUser) as User) : null,
  isAuthenticated: Boolean(savedToken),
}

/**
 * Назначение: хранит JWT, профиль пользователя и состояние авторизации.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setToken: (state, action: PayloadAction<string>) => {
      state.token = action.payload
      state.isAuthenticated = true
      localStorage.setItem('autocheck.token', action.payload)
    },
    setUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload
      localStorage.setItem('autocheck.user', JSON.stringify(action.payload))
    },
    setCredentials: (state, action: PayloadAction<{ token: string; user: User }>) => {
      state.token = action.payload.token
      state.user = action.payload.user
      state.isAuthenticated = true
      localStorage.setItem('autocheck.token', action.payload.token)
      localStorage.setItem('autocheck.user', JSON.stringify(action.payload.user))
    },
    logoutLocal: (state) => {
      state.token = null
      state.user = null
      state.isAuthenticated = false
      localStorage.removeItem('autocheck.token')
      localStorage.removeItem('autocheck.user')
    },
  },
})

export const { logoutLocal, setCredentials, setToken, setUser } = authSlice.actions
export default authSlice.reducer

import { createSlice, type PayloadAction } from '@reduxjs/toolkit'

type ToastTone = 'success' | 'error' | 'info'

type ToastState = {
  id: number
  tone: ToastTone
  message: string
} | null

type UiState = {
  sidebarOpen: boolean
  toast: ToastState
}

const initialState: UiState = {
  sidebarOpen: false,
  toast: null,
}

/**
 * Назначение: хранит локальное состояние оболочки приложения и toast-уведомления.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
const uiSlice = createSlice({
  name: 'ui',
  initialState,
  reducers: {
    setSidebarOpen: (state, action: PayloadAction<boolean>) => {
      state.sidebarOpen = action.payload
    },
    showToast: (state, action: PayloadAction<{ tone: ToastTone; message: string }>) => {
      state.toast = { id: Date.now(), ...action.payload }
    },
    clearToast: (state) => {
      state.toast = null
    },
  },
})

export const { clearToast, setSidebarOpen, showToast } = uiSlice.actions
export default uiSlice.reducer

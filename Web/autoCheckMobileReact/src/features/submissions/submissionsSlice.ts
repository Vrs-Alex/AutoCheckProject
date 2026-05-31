import { createSlice, type PayloadAction } from '@reduxjs/toolkit'
import type { SubmissionStatus } from '../../shared/api/types'

type SubmissionsUiState = {
  searchQuery: string
  assignmentId: string
  statuses: SubmissionStatus[]
  dateFrom: string
  dateTo: string
}

const initialState: SubmissionsUiState = {
  searchQuery: '',
  assignmentId: '',
  statuses: [],
  dateFrom: '',
  dateTo: '',
}

/**
 * Назначение: хранит фильтры экспертского дашборда проверок.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
const submissionsSlice = createSlice({
  name: 'submissionsUi',
  initialState,
  reducers: {
    setSearchQuery: (state, action: PayloadAction<string>) => {
      state.searchQuery = action.payload
    },
    setAssignmentId: (state, action: PayloadAction<string>) => {
      state.assignmentId = action.payload
    },
    toggleStatus: (state, action: PayloadAction<SubmissionStatus>) => {
      state.statuses = state.statuses.includes(action.payload)
        ? state.statuses.filter((status) => status !== action.payload)
        : [...state.statuses, action.payload]
    },
    setDateRange: (state, action: PayloadAction<{ dateFrom: string; dateTo: string }>) => {
      state.dateFrom = action.payload.dateFrom
      state.dateTo = action.payload.dateTo
    },
    resetFilters: () => initialState,
  },
})

export const { resetFilters, setAssignmentId, setDateRange, setSearchQuery, toggleStatus } =
  submissionsSlice.actions
export default submissionsSlice.reducer

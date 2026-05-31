import { configureStore } from '@reduxjs/toolkit'
import { baseApi } from '../shared/api/baseApi'
import authReducer from '../features/auth/authSlice'
import submissionsReducer from '../features/submissions/submissionsSlice'
import uiReducer from '../features/ui/uiSlice'

/**
 * Назначение: единая конфигурация Redux store и middleware RTK Query.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export const store = configureStore({
  reducer: {
    [baseApi.reducerPath]: baseApi.reducer,
    auth: authReducer,
    submissionsUi: submissionsReducer,
    ui: uiReducer,
  },
  middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(baseApi.middleware),
})

export type RootState = ReturnType<typeof store.getState>
export type AppDispatch = typeof store.dispatch

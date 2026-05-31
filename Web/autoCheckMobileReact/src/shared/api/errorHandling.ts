import type { FetchBaseQueryError } from '@reduxjs/toolkit/query'
import type { SerializedError } from '@reduxjs/toolkit'
import type { ApiError } from './types'

const fallbackMessages: Record<number, string> = {
  401: 'Сессия истекла. Войдите заново.',
  403: 'Недостаточно прав для выполнения действия.',
  404: 'Запрашиваемые данные не найдены.',
  422: 'Проверьте поля формы.',
  500: 'Сервер временно недоступен.',
}

export function extractApiError(error: FetchBaseQueryError | SerializedError | undefined): ApiError {
  if (!error) {
    return { code: 'UNKNOWN', message: 'Неизвестная ошибка.' }
  }

  if ('status' in error) {
    const status = typeof error.status === 'number' ? error.status : 500
    const payload = error.data as (ApiError & { error?: ApiError }) | undefined
    const rawError = payload?.error ?? payload
    const normalizedError =
      rawError?.code && rawError?.message
        ? {
            ...rawError,
            fields: rawError.fields ?? rawError.details,
          }
        : undefined
    return (
      normalizedError ?? {
        code: String(status),
        message: fallbackMessages[status] ?? 'Запрос завершился ошибкой.',
      }
    )
  }

  return {
    code: error.name ?? 'CLIENT_ERROR',
    message: error.message ?? 'Ошибка приложения.',
  }
}

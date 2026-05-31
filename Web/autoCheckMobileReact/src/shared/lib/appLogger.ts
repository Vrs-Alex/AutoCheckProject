type LogLevel = 'DEBUG' | 'INFO' | 'ERROR'

function normalizeDetails(details?: unknown) {
  if (details == null) {
    return 'Без дополнительных данных'
  }
  if (typeof details === 'string') {
    return details
  }
  if (details instanceof Error) {
    return details.message
  }
  try {
    return JSON.stringify(details)
  } catch {
    return String(details)
  }
}

function write(level: LogLevel, component: string, event: string, details?: unknown) {
  const message = `[${component}]: ${level} ${event} — ${normalizeDetails(details)}`
  if (level === 'ERROR') {
    console.error(message)
    return
  }
  if (level === 'DEBUG') {
    console.debug(message)
    return
  }
  console.info(message)
}

/**
 * Назначение: единый frontend logger в формате, заданном конкурсным заданием.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export const appLogger = {
  debug: (component: string, event: string, details?: unknown) => write('DEBUG', component, event, details),
  info: (component: string, event: string, details?: unknown) => write('INFO', component, event, details),
  error: (component: string, event: string, details?: unknown) => write('ERROR', component, event, details),
}

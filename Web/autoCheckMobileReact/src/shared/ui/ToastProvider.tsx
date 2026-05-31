import { useEffect } from 'react'
import { useAppDispatch, useAppSelector } from '../../app/hooks'
import { clearToast } from '../../features/ui/uiSlice'
import { TechIcon, type TechIconName } from './TechIcon'

/**
 * Назначение: отображает единое toast-уведомление по состоянию Redux UI slice.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function ToastProvider() {
  const dispatch = useAppDispatch()
  const toast = useAppSelector((state) => state.ui.toast)

  useEffect(() => {
    if (!toast) {
      return
    }
    const id = window.setTimeout(() => dispatch(clearToast()), 4200)
    return () => window.clearTimeout(id)
  }, [dispatch, toast])

  if (!toast) {
    return null
  }

  const icon: TechIconName = toast.tone === 'success' ? 'check' : toast.tone === 'error' ? 'alert' : 'activity'

  return (
    <div className="fixed right-5 top-5 z-[60] card-surface flex max-w-sm items-start gap-3 p-5">
      <TechIcon className={toast.tone === 'error' ? 'h-5 w-5 text-[#ff7a3d]' : 'h-5 w-5 text-[#00ff66]'} name={icon} />
      <p className="text-sm font-medium text-[#f5f7fb]">{toast.message}</p>
    </div>
  )
}

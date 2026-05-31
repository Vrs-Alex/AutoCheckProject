import { AppButton } from './AppButton'
import { Spinner, TechIcon } from './TechIcon'

export function LoadingState({ label = 'Загружаем данные' }: { label?: string }) {
  return (
    <div className="soft-panel flex min-h-48 items-center justify-center p-10 text-[#a0aec0]">
      <Spinner className="mr-3 h-5 w-5 text-[#00ff66]" />
      {label}
    </div>
  )
}

export function EmptyState({ label = 'Данных пока нет' }: { label?: string }) {
  return (
    <div className="soft-panel flex min-h-48 flex-col items-center justify-center p-10 text-center">
      <TechIcon className="h-9 w-9 text-[#687386]" name="inbox" />
      <p className="tech-label mt-3 text-[#f5f7fb]">{label}</p>
      <p className="mt-1 text-sm text-[#687386]">Создайте первый объект или измените фильтры.</p>
    </div>
  )
}

export function ErrorState({ label = 'Не удалось загрузить данные', onRetry }: { label?: string; onRetry?: () => void }) {
  return (
    <div className="soft-panel flex min-h-48 flex-col items-center justify-center p-10 text-center">
      <TechIcon className="h-9 w-9 text-[#ff7a3d]" name="alert" />
      <p className="tech-label mt-3 text-[#f5f7fb]">{label}</p>
      {onRetry ? (
        <AppButton className="mt-4" variant="secondary" onClick={onRetry}>
          Повторить
        </AppButton>
      ) : null}
    </div>
  )
}

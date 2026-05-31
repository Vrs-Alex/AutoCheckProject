import { progressTone } from '../lib/scoreColor'
import { cn } from '../lib/cn'

type ProgressBarProps = {
  value: number
  label?: string
  className?: string
}

/**
 * Назначение: линейный индикатор процента с цветом по порогу.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function ProgressBar({ className, label, value }: ProgressBarProps) {
  const normalized = Math.max(0, Math.min(100, value))

  return (
    <div className={cn('space-y-2', className)}>
      {label ? (
        <div className="flex items-center justify-between text-sm text-[#a0aec0]">
          <span>{label}</span>
          <span className="tech-label text-[#f5f7fb]">{normalized}%</span>
        </div>
      ) : null}
      <div className="h-1.5 overflow-hidden bg-white/10">
        <div className={cn('h-full transition-all', progressTone(normalized))} style={{ width: `${normalized}%` }} />
      </div>
    </div>
  )
}

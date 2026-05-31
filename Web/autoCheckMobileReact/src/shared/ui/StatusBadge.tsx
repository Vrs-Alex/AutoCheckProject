import type { SubmissionStatus, Verdict } from '../api/types'
import { cn } from '../lib/cn'

const statusMap: Record<SubmissionStatus, { label: string; className: string }> = {
  pending: { label: 'Ожидает', className: 'bg-white/[0.03] text-[#a0aec0] ring-white/10' },
  running: { label: 'Проверяется', className: 'bg-[#00ff66]/5 text-[#00ff66] ring-[#00ff66]/35' },
  passed: { label: 'Успешно', className: 'bg-[#00ff66]/5 text-[#00ff66] ring-[#00ff66]/35' },
  failed: { label: 'Провалено', className: 'bg-[#ff5500]/10 text-[#ff7a3d] ring-[#ff5500]/35' },
  error: { label: 'Ошибка', className: 'bg-[#ff5500]/10 text-[#ff7a3d] ring-[#ff5500]/35' },
}

const verdictMap: Record<Verdict, { label: string; className: string }> = {
  accepted: { label: 'Принят', className: 'bg-[#00ff66]/5 text-[#00ff66] ring-[#00ff66]/35' },
  rejected: { label: 'Отклонён', className: 'bg-[#ff5500]/10 text-[#ff7a3d] ring-[#ff5500]/35' },
  none: { label: 'Без вердикта', className: 'bg-white/[0.03] text-[#a0aec0] ring-white/10' },
}

type StatusBadgeProps = {
  status?: SubmissionStatus
  verdict?: Verdict
  className?: string
}

/**
 * Назначение: отображает единый статус проверки или вердикта.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function StatusBadge({ className, status, verdict }: StatusBadgeProps) {
  const tone = verdict ? verdictMap[verdict] : statusMap[status ?? 'pending']

  return (
    <span
      className={cn(
        'tech-label inline-flex items-center gap-1.5 px-2.5 py-1 ring-1',
        status === 'running' && 'before:h-1.5 before:w-1.5 before:animate-pulse before:bg-current',
        tone.className,
        className,
      )}
    >
      {tone.label}
    </span>
  )
}

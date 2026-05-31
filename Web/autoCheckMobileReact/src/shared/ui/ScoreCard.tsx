import type { SubmissionStatus } from '../api/types'
import { scoreTone } from '../lib/scoreColor'
import { StatusBadge } from './StatusBadge'
import { TechIcon } from './TechIcon'

type ScoreCardProps = {
  score: number | null
  title: string
  candidate: string
  status: SubmissionStatus
}

/**
 * Назначение: крупная карточка итогового балла, кандидата и статуса проверки.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function ScoreCard({ candidate, score, status, title }: ScoreCardProps) {
  return (
    <section className="card-surface p-10">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="tech-label text-[#a0aec0]">Итоговый балл</p>
          <div className="mt-4 flex items-end gap-3">
            <strong className={`text-6xl font-black leading-none ${scoreTone(score)}`}>{score ?? '—'}</strong>
            <span className="pb-2 text-sm font-semibold text-[#687386]">/ 100</span>
          </div>
        </div>
        <div className="border border-[#00ff66]/30 bg-[#00ff66]/5 p-3 text-[#00ff66]">
          <TechIcon className="h-6 w-6" name="shield" />
        </div>
      </div>
      <div className="mt-6 space-y-2">
        <h2 className="text-xl font-bold text-[#f5f7fb]">{title}</h2>
        <div className="flex flex-wrap items-center gap-3">
          <span className="text-sm text-[#a0aec0]">{candidate}</span>
          <StatusBadge status={status} />
        </div>
      </div>
    </section>
  )
}

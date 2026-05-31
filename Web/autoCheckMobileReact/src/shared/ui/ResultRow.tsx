import { useState } from 'react'
import type { CheckResult } from '../api/types'
import { scoreTone } from '../lib/scoreColor'
import { StatusBadge } from './StatusBadge'
import { TechIcon } from './TechIcon'

type ResultRowProps = {
  result: CheckResult
}

/**
 * Назначение: раскрываемая строка результата отдельного чекера.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function ResultRow({ result }: ResultRowProps) {
  const [open, setOpen] = useState(false)

  return (
    <article className="border border-white/10 bg-[#0d0f17]">
      <button
        className="flex w-full items-center justify-between gap-4 p-4 text-left"
        type="button"
        onClick={() => setOpen((value) => !value)}
      >
        <div className="flex min-w-0 items-center gap-3">
          <span className="border border-white/10 bg-white/[0.03] p-2 text-[#00ff66]">
            <TechIcon name={open ? 'chevronDown' : 'chevronRight'} />
          </span>
          <div className="min-w-0">
            <h3 className="mono-block truncate font-bold uppercase tracking-[0.12em] text-[#f5f7fb]">{result.checker}</h3>
            <p className="mt-1 truncate text-sm text-[#a0aec0]">{result.message}</p>
          </div>
        </div>
        <div className="flex shrink-0 items-center gap-3">
          <StatusBadge status={result.status} />
          <span className={`w-12 text-right text-lg font-black ${scoreTone(result.score)}`}>{result.score}</span>
        </div>
      </button>
      {open ? (
        <div className="border-t border-white/10 p-4">
          <div className="mb-3 flex items-center gap-2 text-sm text-[#687386]">
            <TechIcon className="h-4 w-4" name="activity" />
            {(result.durationMs / 1000).toFixed(1)} сек.
          </div>
          <pre className="mono-block max-h-72 overflow-auto border border-white/10 bg-[#08080c] p-4 text-xs leading-6 text-[#a0aec0]">
            {result.details}
          </pre>
        </div>
      ) : null}
    </article>
  )
}

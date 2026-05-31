import type { InputHTMLAttributes, ReactNode } from 'react'
import { cn } from '../lib/cn'

type AppInputProps = InputHTMLAttributes<HTMLInputElement> & {
  label?: string
  error?: string
  helper?: string
  icon?: ReactNode
}

/**
 * Назначение: единое поле ввода с label, helper и validation error.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function AppInput({ className, error, helper, icon, id, label, ...props }: AppInputProps) {
  const inputId = id ?? props.name

  return (
    <label className="block" htmlFor={inputId}>
      {label ? <span className="tech-label mb-2 block text-[#f5f7fb]">{label}</span> : null}
      <span className="relative block">
        {icon ? <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[#687386]">{icon}</span> : null}
        <input
          className={cn(
            'h-11 w-full border bg-[#0b0d13] px-3 text-sm text-[#f5f7fb] outline-none transition placeholder:text-[#687386] focus:border-[#00ff66] focus:ring-1 focus:ring-[#00ff66]/25 disabled:opacity-60',
            icon && 'pl-10',
            error ? 'border-[#ff5500]' : 'border-white/10',
            className,
          )}
          id={inputId}
          {...props}
        />
      </span>
      {error ? <span className="mt-2 block text-xs font-medium text-[#ff7a3d]">{error}</span> : null}
      {!error && helper ? <span className="mt-2 block text-xs text-[#687386]">{helper}</span> : null}
    </label>
  )
}

import type { ButtonHTMLAttributes, ReactNode } from 'react'
import { cn } from '../lib/cn'
import { Spinner } from './TechIcon'

type AppButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  icon?: ReactNode
}

/**
 * Назначение: единая кнопка продукта с вариантами, disabled и loading состояниями.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function AppButton({
  children,
  className,
  disabled,
  icon,
  loading,
  size = 'md',
  type = 'button',
  variant = 'primary',
  ...props
}: AppButtonProps) {
  return (
    <button
      className={cn(
        'tech-label inline-flex items-center justify-center gap-2 border transition duration-200 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-[#00ff66]/70 disabled:opacity-45',
        size === 'sm' && 'h-9 px-3 text-sm',
        size === 'md' && 'h-11 px-4 text-sm',
        size === 'lg' && 'h-12 px-5 text-base',
        variant === 'primary' &&
          'border-[#00ff66] bg-[#00ff66] text-[#06070b] shadow-[0_0_28px_rgba(0,255,102,0.14)] hover:-translate-y-0.5 hover:bg-transparent hover:text-[#00ff66]',
        variant === 'secondary' &&
          'border-white/10 bg-[#11141d] text-[#f5f7fb] hover:-translate-y-0.5 hover:border-[#00ff66]/60 hover:text-[#00ff66]',
        variant === 'danger' && 'border-[#ff5500]/60 bg-transparent text-[#ff7a3d] hover:-translate-y-0.5 hover:bg-[#ff5500]/10',
        variant === 'ghost' && 'border-transparent text-[#a0aec0] hover:border-white/10 hover:bg-white/[0.03] hover:text-[#f5f7fb]',
        className,
      )}
      disabled={disabled || loading}
      type={type}
      {...props}
    >
      {loading ? <Spinner /> : icon}
      {children}
    </button>
  )
}

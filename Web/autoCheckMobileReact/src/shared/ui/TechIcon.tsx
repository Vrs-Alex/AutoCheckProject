import { cn } from '../lib/cn'
import type { ReactElement } from 'react'

export type TechIconName =
  | 'activity'
  | 'alert'
  | 'award'
  | 'bot'
  | 'chart'
  | 'check'
  | 'chevronDown'
  | 'chevronRight'
  | 'chevronUp'
  | 'clipboard'
  | 'close'
  | 'download'
  | 'file'
  | 'filter'
  | 'git'
  | 'grid'
  | 'inbox'
  | 'lock'
  | 'logout'
  | 'mail'
  | 'menu'
  | 'percent'
  | 'plus'
  | 'refresh'
  | 'search'
  | 'settings'
  | 'shield'
  | 'sliders'
  | 'thumbDown'
  | 'thumbUp'
  | 'upload'
  | 'user'
  | 'users'

type TechIconProps = {
  name: TechIconName
  className?: string
}

/**
 * Назначение: набор лёгких inline SVG-иконок в едином техническом стиле.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function TechIcon({ className, name }: TechIconProps) {
  return (
    <svg
      aria-hidden="true"
      className={cn('h-5 w-5', className)}
      fill="none"
      stroke="currentColor"
      strokeLinecap="square"
      strokeLinejoin="miter"
      strokeWidth="1.5"
      viewBox="0 0 24 24"
    >
      {paths[name]}
    </svg>
  )
}

export function Spinner({ className }: { className?: string }) {
  return (
    <svg aria-hidden="true" className={cn('h-4 w-4 animate-spin', className)} fill="none" viewBox="0 0 24 24">
      <circle className="opacity-20" cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5" />
      <path d="M21 12a9 9 0 0 0-9-9" stroke="currentColor" strokeLinecap="square" strokeWidth="1.5" />
    </svg>
  )
}

const paths: Record<TechIconName, ReactElement> = {
  activity: <path d="M3 12h4l2-6 4 12 2-6h6" />,
  alert: (
    <>
      <path d="M12 3 2.8 20h18.4L12 3Z" />
      <path d="M12 9v5M12 17h.01" />
    </>
  ),
  award: (
    <>
      <path d="M8 4h8v8H8z" />
      <path d="m9 12-2 8 5-3 5 3-2-8" />
      <path d="M10 8h4" />
    </>
  ),
  bot: (
    <>
      <path d="M7 8h10v9H7z" />
      <path d="M12 8V4M9 12h.01M15 12h.01M10 16h4" />
      <path d="M4 12h3M17 12h3" />
    </>
  ),
  chart: (
    <>
      <path d="M4 20V4M4 20h16" />
      <path d="M8 16v-4M12 16V8M16 16v-7" />
    </>
  ),
  check: <path d="m4 12 5 5L20 6" />,
  chevronDown: <path d="m7 9 5 5 5-5" />,
  chevronRight: <path d="m9 6 6 6-6 6" />,
  chevronUp: <path d="m7 15 5-5 5 5" />,
  clipboard: (
    <>
      <path d="M8 5h8v3H8z" />
      <path d="M6 7H4v14h16V7h-2M8 13h8M8 17h5" />
    </>
  ),
  close: <path d="M6 6 18 18M18 6 6 18" />,
  download: (
    <>
      <path d="M12 3v12M7 10l5 5 5-5" />
      <path d="M5 21h14" />
    </>
  ),
  file: (
    <>
      <path d="M7 3h7l4 4v14H7z" />
      <path d="M14 3v5h5M10 13h5M10 17h4" />
    </>
  ),
  filter: (
    <>
      <path d="M4 6h16M7 12h10M10 18h4" />
    </>
  ),
  git: (
    <>
      <path d="M6 6h12M6 12h12M6 18h12" />
      <path d="M8 6v12M16 6v12" />
    </>
  ),
  grid: (
    <>
      <path d="M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z" />
    </>
  ),
  inbox: (
    <>
      <path d="M4 5h16v14H4z" />
      <path d="M4 13h5l2 3h2l2-3h5" />
    </>
  ),
  lock: (
    <>
      <path d="M6 10h12v10H6z" />
      <path d="M8 10V7a4 4 0 0 1 8 0v3" />
    </>
  ),
  logout: (
    <>
      <path d="M10 5H5v14h5M14 8l4 4-4 4M18 12H9" />
    </>
  ),
  mail: (
    <>
      <path d="M4 6h16v12H4z" />
      <path d="m4 7 8 6 8-6" />
    </>
  ),
  menu: <path d="M4 7h16M4 12h16M4 17h16" />,
  percent: (
    <>
      <path d="M19 5 5 19" />
      <path d="M7 7h.01M17 17h.01" />
    </>
  ),
  plus: <path d="M12 5v14M5 12h14" />,
  refresh: (
    <>
      <path d="M19 8a7 7 0 0 0-12-2l-2 2" />
      <path d="M5 4v4h4" />
      <path d="M5 16a7 7 0 0 0 12 2l2-2" />
      <path d="M19 20v-4h-4" />
    </>
  ),
  search: <path d="M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15ZM16 16l5 5" />,
  settings: (
    <>
      <path d="M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Z" />
      <path d="M12 2v3M12 19v3M4.9 4.9 7 7M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1 7 17M17 7l2.1-2.1" />
    </>
  ),
  shield: (
    <>
      <path d="M12 3 20 6v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3Z" />
      <path d="m8 12 3 3 5-6" />
    </>
  ),
  sliders: (
    <>
      <path d="M4 6h7M15 6h5M4 12h12M18 12h2M4 18h3M11 18h9" />
      <path d="M11 4v4M16 10v4M7 16v4" />
    </>
  ),
  thumbDown: (
    <>
      <path d="M7 4v10H4V4zM7 14h7l-1 6 5-6V4H7" />
    </>
  ),
  thumbUp: (
    <>
      <path d="M7 20V10H4v10zM7 10h7l-1-6 5 6v10H7" />
    </>
  ),
  upload: (
    <>
      <path d="M12 21V9M7 14l5-5 5 5" />
      <path d="M5 5h14" />
    </>
  ),
  user: (
    <>
      <path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z" />
      <path d="M4 21a8 8 0 0 1 16 0" />
    </>
  ),
  users: (
    <>
      <path d="M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM2 21a7 7 0 0 1 14 0" />
      <path d="M17 11a3 3 0 0 0 0-6M16 14a6 6 0 0 1 6 6" />
    </>
  ),
}

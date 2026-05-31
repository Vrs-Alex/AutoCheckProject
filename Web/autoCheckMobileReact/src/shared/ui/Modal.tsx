import type { ReactNode } from 'react'
import { TechIcon } from './TechIcon'

type ModalProps = {
  open: boolean
  title: string
  children: ReactNode
  onClose: () => void
}

/**
 * Назначение: базовое модальное окно для подтверждений и вердиктов эксперта.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function Modal({ children, onClose, open, title }: ModalProps) {
  if (!open) {
    return null
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-[#06070b]/86 p-4 backdrop-blur-sm">
      <section className="card-surface w-full max-w-lg p-10">
        <div className="mb-5 flex items-center justify-between gap-4">
          <h2 className="tech-label text-[#f5f7fb]">{title}</h2>
          <button className="border border-white/10 p-2 text-[#a0aec0] hover:border-[#00ff66] hover:text-[#00ff66]" type="button" onClick={onClose}>
            <TechIcon name="close" />
          </button>
        </div>
        {children}
      </section>
    </div>
  )
}

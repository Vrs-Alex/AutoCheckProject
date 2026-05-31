import { NavLink } from 'react-router-dom'
import { cn } from '../shared/lib/cn'
import { TechIcon, type TechIconName } from '../shared/ui/TechIcon'

const navItems = [
  { to: '/dashboard', label: 'Дашборд', icon: 'grid' },
  { to: '/submissions/new', label: 'Загрузка', icon: 'upload' },
  { to: '/assignments/new', label: 'Создать задание', icon: 'plus' },
  { to: '/statistics', label: 'Статистика', icon: 'chart' },
] satisfies Array<{ to: string; label: string; icon: TechIconName }>

/**
 * Назначение: основная навигация экспертского кабинета.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function Sidebar() {
  return (
    <aside className="hidden w-72 shrink-0 border-r border-white/10 bg-[#08080c]/92 p-6 backdrop-blur-xl lg:block">
      <div className="mb-10 flex items-center gap-3">
        <span className="grid h-11 w-11 place-items-center border border-white/10 bg-[#0d0f17] text-[#00ff66]">
          <TechIcon className="h-6 w-6" name="clipboard" />
        </span>
        <div>
          <p className="mono-block text-2xl font-bold tracking-[0.03em] text-[#f5f7fb]">AutoCheck</p>
          <p className="tech-label text-[#687386]">Expert console</p>
        </div>
      </div>
      <div className="mb-8 border-y border-white/10 py-4 text-xs text-[#687386]">
        <p className="tech-label">[ 55.7558° N, 37.6173° E ]</p>
        <p className="mt-2 flex items-center gap-2 text-[#a0aec0]">
          <span className="green-dot" />
          Backend API online
        </p>
      </div>
      <nav className="space-y-2">
        {navItems.map((item) => {
          return (
            <NavLink
              key={item.to}
              className={({ isActive }) =>
                cn(
                  'tech-label flex items-center gap-3 border border-transparent px-4 py-3 text-[#a0aec0] transition hover:-translate-y-0.5 hover:border-white/10 hover:bg-white/[0.03] hover:text-[#f5f7fb]',
                  isActive && 'blue-glow border-white/10 bg-[#0d0f17] text-[#f5f7fb]',
                )
              }
              to={item.to}
            >
              <TechIcon className="h-5 w-5" name={item.icon} />
              {item.label}
            </NavLink>
          )
        })}
      </nav>
    </aside>
  )
}

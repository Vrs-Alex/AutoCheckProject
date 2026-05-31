import { NavLink, Outlet } from 'react-router-dom'
import { useAppDispatch, useAppSelector } from '../app/hooks'
import { setSidebarOpen } from '../features/ui/uiSlice'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { ToastProvider } from '../shared/ui/ToastProvider'
import { TechIcon } from '../shared/ui/TechIcon'

const mobileLinks = [
  ['/dashboard', 'Дашборд'],
  ['/submissions/new', 'Загрузка'],
  ['/assignments/new', 'Задание'],
  ['/statistics', 'Статистика'],
] as const

/**
 * Назначение: общая оболочка авторизованного экспертского интерфейса.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function AppLayout() {
  const dispatch = useAppDispatch()
  const sidebarOpen = useAppSelector((state) => state.ui.sidebarOpen)

  return (
    <div className="tech-page flex min-h-screen bg-[#06070b]">
      <Sidebar />
      {sidebarOpen ? (
        <div className="fixed inset-0 z-40 bg-[#06070b]/86 backdrop-blur-sm lg:hidden" onClick={() => dispatch(setSidebarOpen(false))}>
          <aside className="h-full w-72 border-r border-white/10 bg-[#08080c] p-5" onClick={(event) => event.stopPropagation()}>
            <button className="mb-5 ml-auto block border border-white/10 p-2 text-[#a0aec0] hover:border-[#00ff66]/60 hover:text-[#00ff66]" type="button" onClick={() => dispatch(setSidebarOpen(false))}>
              <TechIcon className="h-5 w-5" name="close" />
            </button>
            <nav className="space-y-2">
              {mobileLinks.map(([to, label]) => (
                <NavLink
                  key={to}
                  className="tech-label block border border-transparent px-4 py-3 text-[#a0aec0] hover:border-white/10 hover:bg-white/[0.03] hover:text-[#f5f7fb]"
                  to={to}
                  onClick={() => dispatch(setSidebarOpen(false))}
                >
                  {label}
                </NavLink>
              ))}
            </nav>
          </aside>
        </div>
      ) : null}
      <div className="relative z-[1] min-w-0 flex-1">
        <Topbar />
        <main className="mx-auto w-full max-w-[1440px] px-4 py-10 lg:px-10 lg:py-16">
          <Outlet />
        </main>
      </div>
      <ToastProvider />
    </div>
  )
}

import { Link, useNavigate } from 'react-router-dom'
import { useAppDispatch, useAppSelector } from '../app/hooks'
import { useLogoutMutation } from '../features/auth/authApi'
import { setSidebarOpen } from '../features/ui/uiSlice'
import { appLogger } from '../shared/lib/appLogger'
import { AppButton } from '../shared/ui/AppButton'
import { TechIcon } from '../shared/ui/TechIcon'

/**
 * Назначение: верхняя панель с брендом, поиском, пользователем и выходом.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function Topbar() {
  const dispatch = useAppDispatch()
  const navigate = useNavigate()
  const user = useAppSelector((state) => state.auth.user)
  const [logout] = useLogoutMutation()

  return (
    <header className="sticky top-0 z-30 border-b border-white/10 bg-[#08080c]/88 px-4 py-4 backdrop-blur-xl lg:px-8">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3 lg:hidden">
          <button className="border border-white/10 p-2 text-[#a0aec0] hover:border-[#00ff66]/60 hover:text-[#00ff66]" type="button" onClick={() => dispatch(setSidebarOpen(true))}>
            <TechIcon className="h-5 w-5" name="menu" />
          </button>
          <Link className="mono-block flex items-center gap-2 text-xl font-bold tracking-[0.03em] text-[#f5f7fb]" to="/dashboard">
            <TechIcon className="h-6 w-6 text-[#00ff66]" name="clipboard" />
            AutoCheck
          </Link>
        </div>
        <div className="hidden min-w-0 items-center gap-3 border border-white/10 bg-[#0d0f17] px-4 py-2 text-[#687386] md:flex md:w-[420px]">
          <TechIcon className="h-4 w-4" name="search" />
          <span className="tech-label truncate">Search candidate / assignment / run</span>
        </div>
        <div className="ml-auto flex items-center gap-3">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-bold text-[#f5f7fb]">{user?.fullName ?? 'Эксперт'}</p>
            <p className="tech-label text-[#687386]">{user?.email ?? 'expert@autocheck.local'}</p>
          </div>
          <div className="mono-block grid h-10 w-10 place-items-center border border-white/10 bg-[#0d0f17] text-sm font-bold text-[#00ff66]">
            {user?.fullName?.slice(0, 1) ?? 'Э'}
          </div>
          <AppButton
            icon={<TechIcon className="h-4 w-4" name="logout" />}
            size="sm"
            variant="ghost"
            onClick={async () => {
              appLogger.info('Topbar', 'Logout requested', { email: user?.email })
              await logout()
                .unwrap()
                .catch((logoutError) => appLogger.error('Topbar', 'Logout request failed, local session cleared', logoutError))
              navigate('/login', { replace: true })
            }}
          >
            Выход
          </AppButton>
        </div>
      </div>
    </header>
  )
}

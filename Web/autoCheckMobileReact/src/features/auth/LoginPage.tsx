import { type FormEvent, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useLoginMutation, useRegisterMutation } from './authApi'
import { AppButton } from '../../shared/ui/AppButton'
import { AppInput } from '../../shared/ui/AppInput'
import { extractApiError } from '../../shared/api/errorHandling'
import { appLogger } from '../../shared/lib/appLogger'
import { validateEmail, validateRequired } from '../../shared/lib/validators'
import { TechIcon } from '../../shared/ui/TechIcon'
import type { UserRole } from '../../shared/api/types'

const demoAccounts = [
  { label: 'Эксперт', email: 'expert@autocheck.local', fullName: 'Алексей Морозов', password: 'secret123', role: 'expert' as const },
  { label: 'Кандидат', email: 'candidate@autocheck.local', fullName: 'Иван Петров', password: 'secret123', role: 'candidate' as const },
]

/**
 * Назначение: экран входа с демо-логинами и обработкой validation/API ошибок.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function LoginPage() {
  const navigate = useNavigate()
  const [login, loginState] = useLoginMutation()
  const [register, registerState] = useRegisterMutation()
  const [email, setEmail] = useState('expert@autocheck.local')
  const [password, setPassword] = useState('secret123')
  const [fullName, setFullName] = useState('Алексей Морозов')
  const [role, setRole] = useState<UserRole>('expert')
  const [errors, setErrors] = useState<Record<string, string>>({})

  function validateAuthForm() {
    const nextErrors = {
      email: validateEmail(email),
      fullName: validateRequired(fullName, 'ФИО'),
      password: validateRequired(password, 'Пароль'),
    }
    setErrors(nextErrors)
    return nextErrors
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    const nextErrors = validateAuthForm()
    if (Object.values(nextErrors).some(Boolean)) {
      appLogger.debug('LoginPage', 'Client validation blocked login', nextErrors)
      return
    }
    try {
      appLogger.info('LoginPage', 'Login request started', { email })
      await login({ email, password }).unwrap()
      appLogger.debug('LoginPage', 'Login request completed', { email })
      navigate('/dashboard', { replace: true })
    } catch (loginError) {
      appLogger.error('LoginPage', 'Login request failed', loginError)
    }
  }

  async function handleRegister() {
    const nextErrors = validateAuthForm()
    if (Object.values(nextErrors).some(Boolean)) {
      appLogger.debug('LoginPage', 'Client validation blocked register', nextErrors)
      return
    }
    try {
      appLogger.info('LoginPage', 'Register request started', { email, role })
      await register({ email, fullName, password, role }).unwrap()
      appLogger.debug('LoginPage', 'Register request completed', { email, role })
      navigate('/dashboard', { replace: true })
    } catch (registerError) {
      appLogger.error('LoginPage', 'Register request failed', registerError)
    }
  }

  const activeError = loginState.error ?? registerState.error
  const apiError = extractApiError(activeError)
  const isLoading = loginState.isLoading || registerState.isLoading

  return (
    <main className="tech-page grid min-h-screen place-items-center bg-[#06070b] px-4 py-10">
      <section className="card-surface grid w-full max-w-6xl overflow-hidden lg:grid-cols-[1.1fr_0.9fr]">
        <div className="relative hidden min-h-[680px] overflow-hidden border-r border-white/10 bg-[#08080c] p-12 lg:block">
          <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(255,255,255,0.025)_1px,transparent_1px),linear-gradient(rgba(255,255,255,0.025)_1px,transparent_1px)] bg-[size:48px_48px]" />
          <div className="relative z-10 flex h-full flex-col">
            <div className="mb-24 flex items-center gap-3">
              <span className="grid h-14 w-14 place-items-center border border-white/10 bg-[#0d0f17] text-[#00ff66]">
                <TechIcon className="h-8 w-8" name="clipboard" />
              </span>
              <h1 className="mono-block text-4xl font-bold tracking-[0.03em] text-[#f5f7fb]">AutoCheck</h1>
            </div>
            <p className="max-w-xl text-5xl font-black leading-tight text-[#f5f7fb]">
              Панель автопроверки мобильных тестовых заданий
            </p>
            <p className="mt-8 max-w-lg text-lg leading-8 text-[#a0aec0]">
              Создавайте задания, загружайте решения, наблюдайте за чекерами и фиксируйте итоговый вердикт в одном интерфейсе.
            </p>
            <div className="mt-16 grid grid-cols-3 gap-4">
              {['RTK Query', 'Real Backend', 'Docker ready'].map((item) => (
                <div key={item} className="tech-label border border-white/10 bg-[#0d0f17]/85 p-5 text-[#f5f7fb]">
                  {item}
                </div>
              ))}
            </div>
            <div className="mt-auto border-t border-white/10 pt-6">
              <p className="tech-label text-[#687386]">[ AUTH NODE: BACKEND / PORT 8080 ]</p>
              <p className="mt-3 flex items-center gap-2 text-sm text-[#a0aec0]">
                <span className="green-dot" />
                Session broker ready
              </p>
            </div>
          </div>
        </div>
        <form className="bg-[#0d0f17]/74 p-8 sm:p-12" onSubmit={handleSubmit}>
          <div className="mb-8 lg:hidden">
            <div className="flex items-center gap-3">
              <TechIcon className="h-8 w-8 text-[#00ff66]" name="clipboard" />
              <h1 className="mono-block text-3xl font-bold tracking-[0.03em] text-[#f5f7fb]">AutoCheck</h1>
            </div>
          </div>
          <p className="tech-label text-[#687386]">Вход в систему</p>
          <h2 className="mt-4 text-3xl font-black text-[#f5f7fb]">Экспертский dashboard</h2>
          <p className="mt-4 text-[#a0aec0]">Войдите в backend или создайте демо-пользователя в живой базе.</p>

          <div className="mt-6 grid gap-3 sm:grid-cols-2">
            {demoAccounts.map((account) => (
              <button
                key={account.email}
                className="border border-white/10 bg-[#08080c] p-5 text-left transition hover:-translate-y-0.5 hover:border-[#00ff66]/60"
                type="button"
                onClick={() => {
                  appLogger.debug('LoginPage', 'Demo account selected', { email: account.email })
                  setEmail(account.email)
                  setFullName(account.fullName)
                  setPassword(account.password)
                  setRole(account.role)
                }}
              >
                <span className="font-bold text-[#f5f7fb]">{account.label}</span>
                <span className="mt-2 block text-sm text-[#687386]">{account.email}</span>
              </button>
            ))}
          </div>

          <div className="mt-8 space-y-4">
            <AppInput
              error={errors.email || apiError.fields?.email}
              icon={<TechIcon className="h-4 w-4" name="mail" />}
              label="Email"
              name="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
            <AppInput
              error={errors.fullName || apiError.fields?.fullName}
              icon={<TechIcon className="h-4 w-4" name="user" />}
              label="ФИО"
              name="fullName"
              value={fullName}
              onChange={(event) => setFullName(event.target.value)}
            />
            <AppInput
              error={errors.password || apiError.fields?.password}
              icon={<TechIcon className="h-4 w-4" name="lock" />}
              label="Пароль"
              name="password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </div>

          <div className="mt-4 grid grid-cols-2 gap-2 border border-white/10 bg-[#08080c] p-1">
            {(['expert', 'candidate'] as const).map((item) => (
              <button
                key={item}
                className={`tech-label px-3 py-2 transition ${role === item ? 'bg-[#00ff66] text-[#06070b]' : 'text-[#a0aec0] hover:text-[#f5f7fb]'}`}
                type="button"
                onClick={() => setRole(item)}
              >
                {item === 'expert' ? 'Эксперт' : 'Кандидат'}
              </button>
            ))}
          </div>

          {activeError ? (
            <div className="mt-5 border border-[#ff5500]/35 bg-[#ff5500]/10 p-4 text-sm font-medium text-[#ff7a3d]">
              {apiError.message}
            </div>
          ) : null}

          <AppButton className="mt-7 w-full" loading={isLoading} size="lg" type="submit">
            Войти
          </AppButton>
          <AppButton className="mt-3 w-full" loading={registerState.isLoading} size="lg" type="button" variant="secondary" onClick={handleRegister}>
            Создать пользователя
          </AppButton>
        </form>
      </section>
    </main>
  )
}

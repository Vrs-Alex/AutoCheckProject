import { type SyntheticEvent, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useCreateAssignmentMutation } from './assignmentsApi'
import { useAppDispatch } from '../../app/hooks'
import { showToast } from '../ui/uiSlice'
import type { CheckerConfig, CheckerName } from '../../shared/api/types'
import { AppButton } from '../../shared/ui/AppButton'
import { AppInput } from '../../shared/ui/AppInput'
import { ProgressBar } from '../../shared/ui/ProgressBar'
import { extractApiError } from '../../shared/api/errorHandling'
import { appLogger } from '../../shared/lib/appLogger'
import { validateRequired } from '../../shared/lib/validators'
import { TechIcon } from '../../shared/ui/TechIcon'

const checkerLabels: Record<CheckerName, string> = {
  StaticAnalysis: 'Статический анализ',
  Architecture: 'Архитектура',
  Build: 'Сборка',
  Tests: 'Unit-тесты',
  Documentation: 'Документация',
  GitPractices: 'Git-практики',
}

const initialCheckers: CheckerConfig[] = [
  { checker: 'StaticAnalysis', enabled: true, weight: 20 },
  { checker: 'Architecture', enabled: true, weight: 20 },
  { checker: 'Build', enabled: true, weight: 20 },
  { checker: 'Tests', enabled: true, weight: 20 },
  { checker: 'Documentation', enabled: true, weight: 10 },
  { checker: 'GitPractices', enabled: true, weight: 10 },
]

/**
 * Назначение: форма создания тестового задания с чекерами и контролем суммы весов 100%.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function CreateAssignmentPage() {
  const navigate = useNavigate()
  const dispatch = useAppDispatch()
  const [createAssignment, createState] = useCreateAssignmentMutation()
  const [title, setTitle] = useState('Mobile Clean Architecture Challenge')
  const [description, setDescription] = useState('Проверка мобильного проекта на архитектуру, сборку, тесты и документацию.')
  const [technologies, setTechnologies] = useState('Flutter, Kotlin, Android')
  const [instructions, setInstructions] = useState('Загрузите ZIP проекта или ссылку на публичный Git-репозиторий. README и тесты обязательны.')
  const [checkers, setCheckers] = useState<CheckerConfig[]>(initialCheckers)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const totalWeight = useMemo(() => checkers.filter((item) => item.enabled).reduce((sum, item) => sum + item.weight, 0), [checkers])
  const apiError = extractApiError(createState.error)

  function updateChecker(checker: CheckerName, patch: Partial<CheckerConfig>) {
    setCheckers((items) => items.map((item) => (item.checker === checker ? { ...item, ...patch } : item)))
  }

  async function handleSubmit(event: SyntheticEvent, status: 'draft' | 'published') {
    event.preventDefault()
    const nextErrors = {
      title: validateRequired(title, 'Название задания'),
      weights: totalWeight === 100 ? '' : 'Сумма весов активных чекеров должна быть 100%',
    }
    setErrors(nextErrors)
    if (Object.values(nextErrors).some(Boolean)) {
      appLogger.debug('CreateAssignmentPage', 'Client validation blocked assignment create', nextErrors)
      return
    }
    try {
      appLogger.info('CreateAssignmentPage', 'Assignment create started', {
        status,
        title,
        totalWeight,
      })
      await createAssignment({
        title,
        description,
        technologies: technologies
          .split(',')
          .map((item) => item.trim())
          .filter(Boolean),
        checkerConfig: checkers,
        instructionsMarkdown: instructions,
        status,
      }).unwrap()
      appLogger.debug('CreateAssignmentPage', 'Assignment create completed', { status, title })
      dispatch(showToast({ tone: 'success', message: status === 'draft' ? 'Черновик сохранён' : 'Задание опубликовано' }))
      navigate('/dashboard')
    } catch (assignmentError) {
      appLogger.error('CreateAssignmentPage', 'Assignment create failed', assignmentError)
    }
  }

  return (
    <form className="mx-auto max-w-5xl space-y-14">
      <div>
        <p className="tech-label text-[#687386]">Sprint-3 / assignment control</p>
        <h1 className="mt-4 text-4xl font-black text-[#f5f7fb] md:text-5xl">Создание тестового задания</h1>
        <p className="mt-4 text-[#a0aec0]">Настройте чекеры и веса. Публикация доступна только при сумме 100%.</p>
      </div>

      <section className="card-surface p-10">
        <div className="grid gap-6 lg:grid-cols-2">
          <AppInput error={errors.title || apiError.fields?.title} label="Название задания" value={title} onChange={(event) => setTitle(event.target.value)} />
          <AppInput label="Технологии" value={technologies} onChange={(event) => setTechnologies(event.target.value)} />
        </div>
        <label className="mt-6 block">
          <span className="tech-label mb-2 block text-[#f5f7fb]">Описание</span>
          <textarea
            className="min-h-28 w-full border border-white/10 bg-[#0b0d13] p-3 text-sm text-[#f5f7fb] outline-none transition focus:border-[#00ff66] focus:ring-1 focus:ring-[#00ff66]/25"
            value={description}
            onChange={(event) => setDescription(event.target.value)}
          />
        </label>
        <label className="mt-6 block">
          <span className="tech-label mb-2 block text-[#f5f7fb]">Инструкция для кандидата</span>
          <textarea
            className="min-h-32 w-full border border-white/10 bg-[#0b0d13] p-3 text-sm text-[#f5f7fb] outline-none transition focus:border-[#00ff66] focus:ring-1 focus:ring-[#00ff66]/25"
            value={instructions}
            onChange={(event) => setInstructions(event.target.value)}
          />
        </label>
      </section>

      <section className="card-surface p-10">
        <div className="mb-8 flex flex-col justify-between gap-4 lg:flex-row lg:items-center">
          <div>
            <div className="flex items-center gap-3">
              <TechIcon className="h-5 w-5 text-[#00ff66]" name="sliders" />
              <h2 className="text-2xl font-black text-[#f5f7fb]">Чекеры и веса</h2>
            </div>
            <p className="mt-2 text-sm text-[#a0aec0]">Активные веса должны давать ровно 100%.</p>
          </div>
          <div className="min-w-64">
            <ProgressBar label={`Сумма весов: ${totalWeight}%`} value={Math.min(totalWeight, 100)} />
            {errors.weights || apiError.fields?.checkerWeights || apiError.fields?.weights ? (
              <p className="mt-2 text-sm text-[#ff7a3d]">{errors.weights || apiError.fields?.checkerWeights || apiError.fields?.weights}</p>
            ) : null}
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          {checkers.map((item) => (
            <article key={item.checker} className="border border-white/10 bg-[#0b0d13] p-5">
              <div className="mb-4 flex items-center justify-between gap-4">
                <label className="flex items-center gap-3 font-bold text-[#f5f7fb]">
                  <input checked={item.enabled} className="h-4 w-4 accent-[#00ff66]" type="checkbox" onChange={(event) => updateChecker(item.checker, { enabled: event.target.checked })} />
                  {checkerLabels[item.checker]}
                </label>
                <span className="mono-block border border-white/10 bg-[#08080c] px-3 py-1 text-sm font-bold text-[#00ff66]">{item.weight}%</span>
              </div>
              <input
                className="w-full accent-[#00ff66]"
                disabled={!item.enabled}
                max={100}
                min={0}
                type="range"
                value={item.weight}
                onChange={(event) => updateChecker(item.checker, { weight: Number(event.target.value) })}
              />
            </article>
          ))}
        </div>

        {createState.error ? <div className="mt-5 border border-[#ff5500]/35 bg-[#ff5500]/10 p-4 text-sm text-[#ff7a3d]">{apiError.message}</div> : null}

        <div className="mt-7 flex flex-wrap justify-end gap-3">
          <AppButton loading={createState.isLoading} variant="secondary" onClick={(event) => handleSubmit(event, 'draft')}>
            Сохранить черновик
          </AppButton>
          <AppButton disabled={totalWeight !== 100} icon={<TechIcon className="h-4 w-4" name="check" />} loading={createState.isLoading} onClick={(event) => handleSubmit(event, 'published')}>
            Опубликовать
          </AppButton>
        </div>
      </section>
    </form>
  )
}

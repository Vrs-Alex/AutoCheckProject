import { useMemo } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAppDispatch, useAppSelector } from '../../app/hooks'
import { useGetAssignmentsQuery } from '../assignments/assignmentsApi'
import { useGetStatsQuery } from '../reports/reportsApi'
import { useGetSubmissionsQuery } from './submissionsApi'
import { resetFilters, setAssignmentId, setSearchQuery, toggleStatus } from './submissionsSlice'
import type { DataColumn } from '../../shared/ui/DataTable'
import type { Submission, SubmissionStatus } from '../../shared/api/types'
import { AppButton } from '../../shared/ui/AppButton'
import { AppInput } from '../../shared/ui/AppInput'
import { DataTable } from '../../shared/ui/DataTable'
import { ErrorState, LoadingState } from '../../shared/ui/StateViews'
import { StatusBadge } from '../../shared/ui/StatusBadge'
import { TechIcon, type TechIconName } from '../../shared/ui/TechIcon'
import { formatDate } from '../../shared/lib/formatDate'
import { scoreTone } from '../../shared/lib/scoreColor'

const statuses: SubmissionStatus[] = ['pending', 'running', 'passed', 'failed', 'error']

/**
 * Назначение: главная страница эксперта со сводкой, фильтрами и таблицей проверок.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function DashboardPage() {
  const navigate = useNavigate()
  const dispatch = useAppDispatch()
  const filters = useAppSelector((state) => state.submissionsUi)
  const { data: assignments = [] } = useGetAssignmentsQuery()
  const stats = useGetStatsQuery()
  const submissions = useGetSubmissionsQuery({
    search: filters.searchQuery,
    assignmentId: filters.assignmentId,
    statuses: filters.statuses,
    dateFrom: filters.dateFrom,
    dateTo: filters.dateTo,
    page: 1,
    limit: 50,
  })

  const columns = useMemo<DataColumn<Submission>[]>(
    () => [
      {
        key: 'candidate',
        title: 'Кандидат',
        sortValue: (row) => row.candidateName,
        render: (row) => (
          <div>
            <p className="font-bold text-[#f5f7fb]">{row.candidateName}</p>
            {row.candidateEmail ? <p className="text-xs text-[#687386]">{row.candidateEmail}</p> : null}
          </div>
        ),
      },
      { key: 'assignment', title: 'Задание', sortValue: (row) => row.assignmentTitle, render: (row) => row.assignmentTitle },
      { key: 'date', title: 'Дата', sortValue: (row) => row.uploadedAt, render: (row) => formatDate(row.uploadedAt) },
      { key: 'status', title: 'Статус', sortValue: (row) => row.status, render: (row) => <StatusBadge status={row.status} /> },
      {
        key: 'score',
        title: 'Балл',
        sortValue: (row) => row.score ?? -1,
        render: (row) => <span className={`text-lg font-black ${scoreTone(row.score)}`}>{row.score ?? '—'}</span>,
      },
      { key: 'verdict', title: 'Вердикт', sortValue: (row) => row.verdict, render: (row) => <StatusBadge verdict={row.verdict} /> },
    ],
    [],
  )

  const kpis: Array<{ label: string; value: string | number; icon: TechIconName; delta: string }> = [
    { label: 'Всего проверок', value: stats.data?.totalSubmissions30d ?? 0, icon: 'clipboard', delta: '+12% за неделю' },
    { label: 'Средний балл', value: stats.data?.averageScore ?? 0, icon: 'activity', delta: 'по завершённым' },
    { label: 'Процент прохождения', value: `${stats.data?.passRate ?? 0}%`, icon: 'filter', delta: 'passed / total' },
    {
      label: 'Ожидают',
      value: submissions.data?.items.filter((item) => item.status === 'pending' || item.status === 'running').length ?? stats.data?.awaitingReview ?? 0,
      icon: 'upload',
      delta: 'pending + running',
    },
  ]

  return (
    <div className="space-y-16">
      <div className="flex flex-col justify-between gap-4 xl:flex-row xl:items-end">
        <div>
          <p className="tech-label text-[#687386]">AutoCheck dashboard / expert node</p>
          <h1 className="mt-4 text-4xl font-black text-[#f5f7fb] md:text-5xl">Панель управления</h1>
          <p className="mt-4 max-w-2xl text-[#a0aec0]">Контролируйте проверки, фильтруйте кандидатов и открывайте карточки результатов.</p>
        </div>
        <div className="flex flex-wrap gap-3">
          <AppButton icon={<TechIcon className="h-4 w-4" name="plus" />} onClick={() => navigate('/assignments/new')}>
            Создать задание
          </AppButton>
          <AppButton icon={<TechIcon className="h-4 w-4" name="upload" />} variant="secondary" onClick={() => navigate('/submissions/new')}>
            Загрузить решение
          </AppButton>
        </div>
      </div>

      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        {kpis.map((item) => {
          return (
            <section key={item.label} className="card-surface min-h-48 p-10">
              <div className="flex items-center justify-between">
                <p className="tech-label text-[#a0aec0]">{item.label}</p>
                <span className="grid h-11 w-11 place-items-center border border-white/10 bg-[#08080c] text-[#00ff66]">
                  <TechIcon className="h-5 w-5" name={item.icon} />
                </span>
              </div>
              <strong className="mono-block mt-8 block text-5xl font-bold text-[#f5f7fb]">{item.value}</strong>
              <p className="tech-label mt-5 text-[#00ff66]">{item.delta}</p>
            </section>
          )
        })}
      </div>

      <section className="card-surface p-10">
        <div className="mb-8 flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div>
            <p className="tech-label text-[#687386]">Queue monitor</p>
            <h2 className="mt-2 text-2xl font-black text-[#f5f7fb]">Все проверки</h2>
          </div>
          <div className="flex flex-wrap gap-3">
            <Link to="/submissions/new">
              <AppButton size="sm" variant="secondary">
                Новая проверка
              </AppButton>
            </Link>
            <AppButton size="sm" variant="ghost" onClick={() => dispatch(resetFilters())}>
              Сбросить фильтры
            </AppButton>
          </div>
        </div>

        <div className="mb-6 grid gap-3 lg:grid-cols-[1fr_260px]">
          <AppInput
            icon={<TechIcon className="h-4 w-4" name="search" />}
            placeholder="Живой поиск по ФИО, email или заданию"
            value={filters.searchQuery}
            onChange={(event) => dispatch(setSearchQuery(event.target.value))}
          />
          <select
            className="h-11 border border-white/10 bg-[#0b0d13] px-3 text-sm text-[#f5f7fb] outline-none transition focus:border-[#00ff66] focus:ring-1 focus:ring-[#00ff66]/25"
            value={filters.assignmentId}
            onChange={(event) => dispatch(setAssignmentId(event.target.value))}
          >
            <option value="">Все задания</option>
            {assignments.map((assignment) => (
              <option key={assignment.id} value={assignment.id}>
                {assignment.title}
              </option>
            ))}
          </select>
        </div>

        <div className="mb-6 flex flex-wrap gap-2">
          {statuses.map((status) => (
            <button
              key={status}
              className={`border px-3 py-1.5 text-sm font-bold transition ${
                filters.statuses.includes(status)
                  ? 'border-[#00ff66]/60 bg-[#00ff66]/10 text-[#f5f7fb]'
                  : 'border-white/10 bg-[#0b0d13] text-[#687386] hover:text-[#f5f7fb]'
              }`}
              type="button"
              onClick={() => dispatch(toggleStatus(status))}
            >
              <StatusBadge status={status} />
            </button>
          ))}
        </div>

        {submissions.isLoading ? <LoadingState /> : null}
        {submissions.isError ? <ErrorState onRetry={submissions.refetch} /> : null}
        {submissions.data && !submissions.isError ? (
          <DataTable columns={columns} getRowKey={(row) => row.id} rows={submissions.data.items} onRowClick={(row) => navigate(`/submissions/${row.id}`)} />
        ) : null}
      </section>
    </div>
  )
}

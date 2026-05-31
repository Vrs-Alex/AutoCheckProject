import { Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useGetStatsQuery } from './reportsApi'
import { ErrorState, LoadingState } from '../../shared/ui/StateViews'
import { scoreTone } from '../../shared/lib/scoreColor'
import { TechIcon, type TechIconName } from '../../shared/ui/TechIcon'

/**
 * Назначение: аналитическая страница статистики за 30 дней.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function StatisticsPage() {
  const stats = useGetStatsQuery()

  if (stats.isLoading) {
    return <LoadingState label="Собираем статистику" />
  }

  if (stats.isError || !stats.data) {
    return <ErrorState label="Статистика недоступна" onRetry={stats.refetch} />
  }

  const cards: Array<{ label: string; value: string | number; icon: TechIconName }> = [
    { label: 'Проверок за 30 дней', value: stats.data.totalSubmissions30d, icon: 'chart' },
    { label: 'Средний балл', value: stats.data.averageScore, icon: 'award' },
    { label: 'Процент прохождения', value: `${stats.data.passRate}%`, icon: 'percent' },
    { label: 'Ожидают проверки', value: stats.data.awaitingReview, icon: 'users' },
  ]

  return (
    <div className="space-y-16">
      <div>
        <p className="tech-label text-[#687386]">Sprint-4 / telemetry</p>
        <h1 className="mt-4 text-4xl font-black text-[#f5f7fb] md:text-5xl">Статистика</h1>
        <p className="mt-4 text-[#a0aec0]">Метрики AutoCheck за последние 30 дней и рейтинг кандидатов.</p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {cards.map((card) => {
          return (
            <section key={card.label} className="card-surface min-h-48 p-10">
              <div className="flex items-center justify-between">
                <p className="tech-label text-[#a0aec0]">{card.label}</p>
                <TechIcon className="h-5 w-5 text-[#00ff66]" name={card.icon} />
              </div>
              <strong className="mono-block mt-8 block text-5xl font-bold text-[#f5f7fb]">{card.value}</strong>
            </section>
          )
        })}
      </div>

      <div className="grid gap-6 xl:grid-cols-[1.4fr_0.8fr]">
        <section className="card-surface p-10">
          <p className="tech-label text-[#687386]">Runtime chart</p>
          <h2 className="mt-2 text-2xl font-black text-[#f5f7fb]">Динамика проверок</h2>
          <div className="mt-6 h-80">
            <ResponsiveContainer height="100%" width="100%">
              <LineChart data={stats.data.dailySubmissions}>
                <CartesianGrid stroke="rgba(255,255,255,0.08)" strokeDasharray="3 3" />
                <XAxis dataKey="date" stroke="#687386" tickFormatter={(value) => String(value).slice(5)} />
                <YAxis stroke="#687386" />
                <Tooltip contentStyle={{ background: '#0d0f17', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 0, color: '#f5f7fb' }} />
                <Line dataKey="count" name="Всего" stroke="#a0aec0" strokeWidth={2} type="monotone" />
                <Line dataKey="passed" name="Успешно" stroke="#00ff66" strokeWidth={2} type="monotone" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </section>

        <section className="card-surface p-10">
          <p className="tech-label text-[#687386]">Candidate ranking</p>
          <h2 className="mt-2 text-2xl font-black text-[#f5f7fb]">Топ-10 кандидатов</h2>
          <div className="mt-5 space-y-3">
            {stats.data.topCandidates.map((candidate, index) => (
              <div key={candidate.id} className="flex items-center justify-between gap-4 border border-white/10 bg-[#0b0d13] p-4">
                <div>
                  <p className="font-bold text-[#f5f7fb]">
                    {index + 1}. {candidate.fullName}
                  </p>
                  <p className="tech-label mt-1 text-[#687386]">{candidate.attempts} попыток</p>
                </div>
                <span className={`mono-block text-xl font-bold ${scoreTone(candidate.bestScore)}`}>{candidate.bestScore}</span>
              </div>
            ))}
          </div>
        </section>
      </div>

      <section className="card-surface p-10">
        <p className="tech-label text-[#687386]">Outcome distribution</p>
        <h2 className="mt-2 text-2xl font-black text-[#f5f7fb]">Passed / Failed</h2>
        <div className="mt-6 h-64">
          <ResponsiveContainer height="100%" width="100%">
            <BarChart data={stats.data.dailySubmissions.slice(-10)}>
              <CartesianGrid stroke="rgba(255,255,255,0.08)" strokeDasharray="3 3" />
              <XAxis dataKey="date" stroke="#687386" tickFormatter={(value) => String(value).slice(5)} />
              <YAxis stroke="#687386" />
              <Tooltip contentStyle={{ background: '#0d0f17', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 0, color: '#f5f7fb' }} />
              <Bar dataKey="passed" fill="#00ff66" name="Успешно" radius={[0, 0, 0, 0]} />
              <Bar dataKey="failed" fill="#ff5500" name="Провалено" radius={[0, 0, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </section>
    </div>
  )
}

import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  useGetAiReviewQuery,
  useGetSubmissionByIdQuery,
  useGetSubmissionResultsQuery,
  useLazyGetSubmissionReportQuery,
  useRerunSubmissionMutation,
  useUpdateVerdictMutation,
} from './submissionsApi'
import { useAppDispatch } from '../../app/hooks'
import { showToast } from '../ui/uiSlice'
import { AppButton } from '../../shared/ui/AppButton'
import { ErrorState, LoadingState } from '../../shared/ui/StateViews'
import { ScoreCard } from '../../shared/ui/ScoreCard'
import { ResultRow } from '../../shared/ui/ResultRow'
import { Modal } from '../../shared/ui/Modal'
import { formatDateTime } from '../../shared/lib/formatDate'
import { extractApiError } from '../../shared/api/errorHandling'
import { createTimelineFromSubmission } from '../../shared/api/adapters'
import { appLogger } from '../../shared/lib/appLogger'
import { TechIcon } from '../../shared/ui/TechIcon'

/**
 * Назначение: карточка проверки с результатами чекеров, AI-анализом и вердиктом.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function SubmissionDetailsPage() {
  const { submissionId = '' } = useParams()
  const navigate = useNavigate()
  const dispatch = useAppDispatch()
  const submission = useGetSubmissionByIdQuery(submissionId, { pollingInterval: 3500 })
  const results = useGetSubmissionResultsQuery(submissionId, { pollingInterval: 3500 })
  const aiReview = useGetAiReviewQuery(submissionId)
  const [rerun, rerunState] = useRerunSubmissionMutation()
  const [updateVerdict, verdictState] = useUpdateVerdictMutation()
  const [loadReport, reportState] = useLazyGetSubmissionReportQuery()
  const [modalVerdict, setModalVerdict] = useState<'accepted' | 'rejected' | null>(null)
  const [comment, setComment] = useState('')
  const [reportText, setReportText] = useState('')

  if (submission.isLoading) {
    return <LoadingState label="Загружаем карточку проверки" />
  }

  if (submission.isError || !submission.data) {
    return <ErrorState label="Карточка проверки недоступна" onRetry={submission.refetch} />
  }

  const verdictError = extractApiError(verdictState.error)
  const timeline = createTimelineFromSubmission(submission.data)

  return (
    <div className="space-y-16">
      <div className="flex flex-col justify-between gap-4 xl:flex-row xl:items-start">
        <div>
          <p className="tech-label text-[#687386]">Run card / submission node</p>
          <h1 className="mt-4 text-4xl font-black text-[#f5f7fb] md:text-5xl">{submission.data.candidateName}</h1>
          <p className="mt-4 text-[#a0aec0]">
            {submission.data.assignmentTitle} · {formatDateTime(submission.data.uploadedAt)}
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <AppButton
            icon={<TechIcon className="h-4 w-4" name="refresh" />}
            loading={rerunState.isLoading}
            variant="secondary"
            onClick={async () => {
              try {
                appLogger.info('SubmissionDetailsPage', 'Rerun requested', { submissionId: submission.data.id })
                await rerun(submission.data.id).unwrap()
                appLogger.debug('SubmissionDetailsPage', 'Rerun completed', { submissionId: submission.data.id })
                dispatch(showToast({ tone: 'info', message: 'Проверка перезапущена' }))
              } catch (rerunError) {
                appLogger.error('SubmissionDetailsPage', 'Rerun failed', rerunError)
                dispatch(showToast({ tone: 'error', message: 'Не удалось перезапустить проверку' }))
              }
            }}
          >
            Перезапустить
          </AppButton>
          <AppButton
            icon={<TechIcon className="h-4 w-4" name="download" />}
            loading={reportState.isLoading}
            variant="secondary"
            onClick={async () => {
              try {
                appLogger.info('SubmissionDetailsPage', 'Report export requested', { submissionId: submission.data.id })
                const report = await loadReport(submission.data.id).unwrap()
                setReportText(report)
                dispatch(showToast({ tone: 'success', message: 'Отчёт получен от backend' }))
              } catch (reportError) {
                appLogger.error('SubmissionDetailsPage', 'Report export failed', reportError)
                dispatch(showToast({ tone: 'error', message: 'Не удалось получить отчёт' }))
              }
            }}
          >
            Скачать отчёт
          </AppButton>
          <AppButton icon={<TechIcon className="h-4 w-4" name="thumbUp" />} onClick={() => setModalVerdict('accepted')}>
            Принять
          </AppButton>
          <AppButton icon={<TechIcon className="h-4 w-4" name="thumbDown" />} variant="danger" onClick={() => setModalVerdict('rejected')}>
            Отклонить
          </AppButton>
        </div>
      </div>

      <div className="grid gap-8 xl:grid-cols-[380px_1fr]">
        <div className="space-y-8">
          <ScoreCard candidate={submission.data.candidateName} score={submission.data.score} status={submission.data.status} title={submission.data.assignmentTitle} />
          <section className="card-surface p-10">
            <p className="tech-label text-[#687386]">Pipeline events</p>
            <h2 className="mt-2 text-xl font-black text-[#f5f7fb]">Хронология</h2>
            <div className="mt-6 space-y-5">
              {timeline.map((event) => (
                <div key={event.id} className="flex gap-3">
                  <span
                    className={`mt-1 h-3 w-3 ${
                      event.status === 'done' ? 'bg-[#00ff66]' : event.status === 'active' ? 'animate-pulse bg-[#ff5500]' : 'bg-[#303641]'
                    }`}
                  />
                  <div>
                    <p className="font-semibold text-[#f5f7fb]">{event.label}</p>
                    <p className="tech-label mt-1 text-[#687386]">{formatDateTime(event.at)}</p>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>

        <div className="space-y-8">
          <section className="card-surface p-10">
            <p className="tech-label text-[#687386]">Checker matrix</p>
            <h2 className="mt-2 text-xl font-black text-[#f5f7fb]">Детализация проверок</h2>
            <div className="mt-6 space-y-3">
              {results.isLoading ? <LoadingState label="Загружаем чекеры" /> : null}
              {results.data?.map((result) => <ResultRow key={result.id} result={result} />)}
            </div>
          </section>

          <section className="card-surface p-10">
            <div className="mb-6 flex items-center gap-3">
              <span className="grid h-11 w-11 place-items-center border border-white/10 bg-[#08080c] text-[#00ff66]">
                <TechIcon className="h-5 w-5" name="bot" />
              </span>
              <div>
                <p className="tech-label text-[#687386]">AI inspection</p>
                <h2 className="text-xl font-black text-[#f5f7fb]">AI-анализ</h2>
              </div>
            </div>
            {aiReview.isLoading ? <LoadingState label="Запрашиваем AI-анализ" /> : null}
            {aiReview.data?.available ? (
              <div className="space-y-5">
                <p className="border border-white/10 bg-[#0b0d13] p-5 text-[#a0aec0]">{aiReview.data.summary}</p>
                {[
                  ['Что хорошо', aiReview.data.good],
                  ['Что улучшить', aiReview.data.improvements],
                  ['Замечания', aiReview.data.remarks],
                ].map(([title, items]) => (
                  <div key={String(title)}>
                    <h3 className="tech-label text-[#f5f7fb]">{String(title)}</h3>
                    <ul className="mt-3 space-y-2 text-sm text-[#a0aec0]">
                      {(items as string[] | undefined)?.map((item) => (
                        <li key={item} className="border border-white/10 bg-[#0b0d13] px-3 py-2">
                          {item}
                        </li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>
            ) : null}
            {aiReview.data && !aiReview.data.available ? (
              <div className="border border-[#ff5500]/35 bg-[#ff5500]/10 p-4 text-[#ff7a3d]">
                {aiReview.data.errorMessage ?? 'AI-анализ недоступен'}
              </div>
            ) : null}
          </section>
        </div>
      </div>

      <Modal
        open={Boolean(modalVerdict)}
        title={modalVerdict === 'accepted' ? 'Принять кандидата' : 'Отклонить кандидата'}
        onClose={() => setModalVerdict(null)}
      >
        <textarea
          className="min-h-32 w-full border border-white/10 bg-[#0b0d13] p-3 text-sm text-[#f5f7fb] outline-none transition placeholder:text-[#687386] focus:border-[#00ff66] focus:ring-1 focus:ring-[#00ff66]/25"
          placeholder="Комментарий к вердикту"
          value={comment}
          onChange={(event) => setComment(event.target.value)}
        />
        {verdictState.error ? <p className="mt-2 text-sm text-[#ff7a3d]">{verdictError.fields?.comment ?? verdictError.message}</p> : null}
        <div className="mt-5 flex justify-end gap-3">
          <AppButton variant="ghost" onClick={() => setModalVerdict(null)}>
            Отмена
          </AppButton>
          <AppButton
            loading={verdictState.isLoading}
            variant={modalVerdict === 'accepted' ? 'primary' : 'danger'}
            onClick={async () => {
              if (!modalVerdict) return
              try {
                appLogger.info('SubmissionDetailsPage', 'Verdict update started', {
                  submissionId: submission.data.id,
                  verdict: modalVerdict,
                })
                await updateVerdict({ id: submission.data.id, verdict: modalVerdict, comment }).unwrap()
                appLogger.debug('SubmissionDetailsPage', 'Verdict update completed', {
                  submissionId: submission.data.id,
                  verdict: modalVerdict,
                })
                dispatch(showToast({ tone: 'success', message: 'Вердикт сохранён' }))
                setModalVerdict(null)
                setComment('')
                navigate(`/submissions/${submission.data.id}`)
              } catch (verdictError) {
                appLogger.error('SubmissionDetailsPage', 'Verdict update failed', verdictError)
              }
            }}
          >
            Сохранить
          </AppButton>
        </div>
      </Modal>

      <Modal open={Boolean(reportText)} title="JSON-отчёт backend" onClose={() => setReportText('')}>
        <pre className="max-h-[60vh] overflow-auto border border-white/10 bg-[#0b0d13] p-4 text-xs leading-6 text-[#a0aec0]">
          {reportText}
        </pre>
      </Modal>
    </div>
  )
}

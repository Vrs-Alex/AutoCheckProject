import { type FormEvent, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useGetAssignmentsQuery } from '../assignments/assignmentsApi'
import { useCreateSubmissionMutation } from './submissionsApi'
import { useAppDispatch } from '../../app/hooks'
import { showToast } from '../ui/uiSlice'
import { AppButton } from '../../shared/ui/AppButton'
import { AppInput } from '../../shared/ui/AppInput'
import { FileUpload } from '../../shared/ui/FileUpload'
import { ErrorState, LoadingState } from '../../shared/ui/StateViews'
import { extractApiError } from '../../shared/api/errorHandling'
import { appLogger } from '../../shared/lib/appLogger'
import { validateEmail, validateGitUrl, validateRequired } from '../../shared/lib/validators'
import { TechIcon } from '../../shared/ui/TechIcon'

type UploadMode = 'zip' | 'git'

/**
 * Назначение: экран ручной загрузки решения кандидата ZIP-архивом или Git URL.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function UploadSubmissionPage() {
  const navigate = useNavigate()
  const dispatch = useAppDispatch()
  const assignments = useGetAssignmentsQuery()
  const [createSubmission, createState] = useCreateSubmissionMutation()
  const [assignmentId, setAssignmentId] = useState('')
  const [mode, setMode] = useState<UploadMode>('zip')
  const [file, setFile] = useState<File | null>(null)
  const [fileError, setFileError] = useState('')
  const [gitUrl, setGitUrl] = useState('')
  const [candidateName, setCandidateName] = useState('Иван Петров')
  const [candidateEmail, setCandidateEmail] = useState('ivan.petrov@test.ru')
  const [errors, setErrors] = useState<Record<string, string>>({})

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    const nextErrors = {
      assignmentId: assignmentId ? '' : 'Выберите тестовое задание',
      candidateName: validateRequired(candidateName, 'ФИО кандидата'),
      candidateEmail: validateEmail(candidateEmail),
      gitUrl: mode === 'git' ? validateGitUrl(gitUrl) : '',
      file: mode === 'zip' && !file ? 'Выберите ZIP-архив' : fileError,
    }
    setErrors(nextErrors)
    if (Object.values(nextErrors).some(Boolean)) {
      appLogger.debug('UploadSubmissionPage', 'Client validation blocked submission upload', nextErrors)
      return
    }

    try {
      appLogger.info('UploadSubmissionPage', 'Submission upload started', {
        assignmentId,
        candidateEmail,
        mode,
      })
      const submission = await createSubmission({
        assignmentId,
        candidateName,
        candidateEmail,
        file: mode === 'zip' ? file : null,
        gitUrl: mode === 'git' ? gitUrl : undefined,
      }).unwrap()
      appLogger.debug('UploadSubmissionPage', 'Submission upload completed', { submissionId: submission.id })
      dispatch(showToast({ tone: 'success', message: 'Решение отправлено на проверку' }))
      navigate(`/submissions/${submission.id}`)
    } catch (submissionError) {
      appLogger.error('UploadSubmissionPage', 'Submission upload failed', submissionError)
    }
  }

  const apiError = extractApiError(createState.error)

  if (assignments.isLoading) {
    return <LoadingState label="Загружаем список заданий" />
  }

  if (assignments.isError) {
    return <ErrorState label="Не удалось загрузить задания" onRetry={assignments.refetch} />
  }

  return (
    <form className="mx-auto max-w-5xl space-y-14" onSubmit={handleSubmit}>
      <div>
        <p className="tech-label text-[#687386]">Sprint-2 / intake terminal</p>
        <h1 className="mt-4 text-4xl font-black text-[#f5f7fb] md:text-5xl">Загрузка задания</h1>
        <p className="mt-4 text-[#a0aec0]">Создайте проверку вручную: ZIP-архив или публичная ссылка на Git-репозиторий.</p>
      </div>

      <section className="card-surface p-10">
        <div className="grid gap-6 lg:grid-cols-2">
          <label>
            <span className="tech-label mb-2 block text-[#f5f7fb]">Тестовое задание</span>
            <select
              className={`h-11 w-full border bg-[#0b0d13] px-3 text-sm text-[#f5f7fb] outline-none transition focus:border-[#00ff66] focus:ring-1 focus:ring-[#00ff66]/25 ${
                errors.assignmentId ? 'border-[#ff5500]' : 'border-white/10'
              }`}
              value={assignmentId}
              onChange={(event) => setAssignmentId(event.target.value)}
            >
              <option value="">Выберите задание</option>
              {assignments.data?.map((assignment) => (
                <option key={assignment.id} value={assignment.id}>
                  {assignment.title}
                </option>
              ))}
            </select>
            {errors.assignmentId ? <span className="mt-2 block text-xs text-[#ff7a3d]">{errors.assignmentId}</span> : null}
          </label>
          <div>
            <span className="tech-label mb-2 block text-[#f5f7fb]">Способ загрузки</span>
            <div className="grid grid-cols-2 gap-2 border border-white/10 bg-[#0b0d13] p-1">
              {(['zip', 'git'] as const).map((item) => (
                <button
                  key={item}
                  className={`tech-label px-3 py-2 transition ${mode === item ? 'bg-[#00ff66] text-[#06070b]' : 'text-[#a0aec0] hover:text-[#f5f7fb]'}`}
                  type="button"
                  onClick={() => {
                    appLogger.debug('UploadSubmissionPage', 'Upload mode changed', { mode: item })
                    setMode(item)
                  }}
                >
                  {item === 'zip' ? 'ZIP-файл' : 'Git URL'}
                </button>
              ))}
            </div>
          </div>
          <AppInput
            error={errors.candidateName || apiError.fields?.candidateFullName}
            icon={<TechIcon className="h-4 w-4" name="user" />}
            label="ФИО кандидата"
            value={candidateName}
            onChange={(event) => setCandidateName(event.target.value)}
          />
          <AppInput
            error={errors.candidateEmail || apiError.fields?.candidateEmail}
            icon={<TechIcon className="h-4 w-4" name="mail" />}
            label="Email кандидата"
            value={candidateEmail}
            onChange={(event) => setCandidateEmail(event.target.value)}
          />
        </div>

        <div className="mt-6">
          {mode === 'zip' ? (
            <FileUpload
              error={errors.file || fileError}
              file={file}
              onChange={(nextFile, nextError) => {
                setFile(nextFile)
                setFileError(nextError ?? '')
              }}
            />
          ) : (
            <AppInput
              error={errors.gitUrl}
              helper="Например: https://git.example.ru/team/mobile-solution"
              icon={<TechIcon className="h-4 w-4" name="git" />}
              label="Публичная ссылка на Git"
              value={gitUrl}
              onChange={(event) => setGitUrl(event.target.value)}
            />
          )}
        </div>

        {createState.error ? (
          <div className="mt-5 border border-[#ff5500]/35 bg-[#ff5500]/10 p-4 text-sm text-[#ff7a3d]">{apiError.message}</div>
        ) : null}

        <div className="mt-7 flex justify-end gap-3">
          <AppButton variant="ghost" onClick={() => navigate('/dashboard')}>
            Отмена
          </AppButton>
          <AppButton loading={createState.isLoading} type="submit">
            Отправить на проверку
          </AppButton>
        </div>
      </section>
    </form>
  )
}

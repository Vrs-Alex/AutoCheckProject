import { useCallback, useRef, useState } from 'react'
import { AppButton } from './AppButton'
import { cn } from '../lib/cn'
import { TechIcon } from './TechIcon'

type FileUploadProps = {
  file: File | null
  error?: string
  onChange: (file: File | null, error?: string) => void
}

const maxBytes = 50 * 1024 * 1024

/**
 * Назначение: drag-and-drop ZIP upload с валидацией типа и размера файла.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function FileUpload({ error, file, onChange }: FileUploadProps) {
  const inputRef = useRef<HTMLInputElement | null>(null)
  const [dragging, setDragging] = useState(false)

  const validateAndSet = useCallback(
    (selected: File | null) => {
      if (!selected) {
        onChange(null)
        return
      }
      if (!selected.name.toLowerCase().endsWith('.zip')) {
        onChange(null, 'Допустим только ZIP-архив')
        return
      }
      if (selected.size > maxBytes) {
        onChange(null, 'Размер файла не должен превышать 50 МБ')
        return
      }
      onChange(selected)
    },
    [onChange],
  )

  return (
    <div>
      <div
        className={cn(
          'border border-dashed p-10 transition',
          dragging ? 'border-[#00ff66] bg-[#00ff66]/5' : 'border-white/10 bg-[#0b0d13]',
          error && 'border-[#ff5500]',
        )}
        onDragLeave={() => setDragging(false)}
        onDragOver={(event) => {
          event.preventDefault()
          setDragging(true)
        }}
        onDrop={(event) => {
          event.preventDefault()
          setDragging(false)
          validateAndSet(event.dataTransfer.files.item(0))
        }}
      >
        <input
          ref={inputRef}
          accept=".zip"
          className="hidden"
          type="file"
          onChange={(event) => validateAndSet(event.target.files?.item(0) ?? null)}
        />
        {file ? (
          <div className="flex items-center justify-between gap-4">
            <div className="flex min-w-0 items-center gap-3">
              <div className="border border-white/10 bg-white/[0.03] p-3 text-[#00ff66]">
                <TechIcon name="file" />
              </div>
              <div className="min-w-0">
                <p className="truncate font-semibold text-[#f5f7fb]">{file.name}</p>
                <p className="text-sm text-[#687386]">{(file.size / 1024 / 1024).toFixed(2)} МБ</p>
              </div>
            </div>
            <button className="border border-white/10 p-2 text-[#a0aec0] hover:border-[#00ff66] hover:text-[#00ff66]" type="button" onClick={() => onChange(null)}>
              <TechIcon className="h-4 w-4" name="close" />
            </button>
          </div>
        ) : (
          <div className="text-center">
            <TechIcon className="mx-auto h-8 w-8 text-[#00ff66]" name="upload" />
            <p className="tech-label mt-3 text-[#f5f7fb]">Перетащите ZIP-архив сюда</p>
            <p className="mt-1 text-sm text-[#687386]">или выберите файл до 50 МБ</p>
            <AppButton className="mt-4" variant="secondary" onClick={() => inputRef.current?.click()}>
              Выбрать файл
            </AppButton>
          </div>
        )}
      </div>
      {error ? <p className="mt-2 text-sm font-medium text-[#ff7a3d]">{error}</p> : null}
    </div>
  )
}

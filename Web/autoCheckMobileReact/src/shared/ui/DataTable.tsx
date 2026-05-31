import { useMemo, useState } from 'react'
import { EmptyState } from './StateViews'
import { cn } from '../lib/cn'
import { TechIcon } from './TechIcon'

export type DataColumn<T> = {
  key: string
  title: string
  render: (row: T) => React.ReactNode
  sortValue?: (row: T) => string | number | null
  className?: string
}

type DataTableProps<T> = {
  rows: T[]
  columns: DataColumn<T>[]
  getRowKey: (row: T) => string
  onRowClick?: (row: T) => void
  pageSize?: number
}

/**
 * Назначение: универсальная таблица с сортировкой, пагинацией и кликабельными строками.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
export function DataTable<T>({ columns, getRowKey, onRowClick, pageSize = 50, rows }: DataTableProps<T>) {
  const [sortKey, setSortKey] = useState<string>('')
  const [direction, setDirection] = useState<'asc' | 'desc'>('asc')
  const [page, setPage] = useState(1)

  const sortedRows = useMemo(() => {
    const column = columns.find((item) => item.key === sortKey)
    if (!column?.sortValue) {
      return rows
    }
    return [...rows].sort((a, b) => {
      const av = column.sortValue?.(a) ?? ''
      const bv = column.sortValue?.(b) ?? ''
      if (av === bv) {
        return 0
      }
      const result = av > bv ? 1 : -1
      return direction === 'asc' ? result : -result
    })
  }, [columns, direction, rows, sortKey])

  const totalPages = Math.max(1, Math.ceil(sortedRows.length / pageSize))
  const visibleRows = sortedRows.slice((page - 1) * pageSize, page * pageSize)

  if (!rows.length) {
    return <EmptyState label="По текущим фильтрам проверок нет" />
  }

  return (
    <div className="overflow-hidden border border-white/10">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-white/10">
          <thead className="bg-[#0b0d13]">
            <tr>
              {columns.map((column) => {
                const active = sortKey === column.key
                return (
                  <th
                    key={column.key}
                    className={cn(
                      'px-4 py-3 text-left text-xs font-bold uppercase tracking-[0.14em] text-[#687386]',
                      column.className,
                    )}
                  >
                    {column.sortValue ? (
                      <button
                        className="tech-label inline-flex items-center gap-1 hover:text-[#00ff66]"
                        type="button"
                        onClick={() => {
                          if (active) {
                            setDirection(direction === 'asc' ? 'desc' : 'asc')
                          } else {
                            setSortKey(column.key)
                            setDirection('asc')
                          }
                        }}
                      >
                        {column.title}
                        {active ? (
                          direction === 'asc' ? (
                            <TechIcon className="h-3 w-3" name="chevronUp" />
                          ) : (
                            <TechIcon className="h-3 w-3" name="chevronDown" />
                          )
                        ) : null}
                      </button>
                    ) : (
                      column.title
                    )}
                  </th>
                )
              })}
            </tr>
          </thead>
          <tbody className="divide-y divide-white/10 bg-[#0d0f17]/70">
            {visibleRows.map((row) => (
              <tr
                key={getRowKey(row)}
                className={cn('transition hover:bg-white/[0.035]', onRowClick && 'cursor-pointer')}
                onClick={() => onRowClick?.(row)}
              >
                {columns.map((column) => (
                  <td key={column.key} className={cn('px-4 py-4 text-sm text-[#f5f7fb]', column.className)}>
                    {column.render(row)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="flex items-center justify-between gap-4 border-t border-white/10 bg-[#0b0d13] px-4 py-3 text-sm text-[#a0aec0]">
        <span>
          Страница {page} из {totalPages}, по {pageSize} строк
        </span>
        <div className="flex gap-2">
          <button className="border border-transparent px-3 py-1.5 hover:border-white/10 hover:text-[#00ff66] disabled:opacity-40" disabled={page === 1} type="button" onClick={() => setPage((value) => value - 1)}>
            Назад
          </button>
          <button className="border border-transparent px-3 py-1.5 hover:border-white/10 hover:text-[#00ff66] disabled:opacity-40" disabled={page === totalPages} type="button" onClick={() => setPage((value) => value + 1)}>
            Далее
          </button>
        </div>
      </div>
    </div>
  )
}

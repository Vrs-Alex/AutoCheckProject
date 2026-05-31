import { Navigate, Route, Routes } from 'react-router-dom'
import { AppLayout } from './layouts/AppLayout'
import { LoginPage } from './features/auth/LoginPage'
import { DashboardPage } from './features/submissions/DashboardPage'
import { UploadSubmissionPage } from './features/submissions/UploadSubmissionPage'
import { SubmissionDetailsPage } from './features/submissions/SubmissionDetailsPage'
import { CreateAssignmentPage } from './features/assignments/CreateAssignmentPage'
import { StatisticsPage } from './features/reports/StatisticsPage'
import { useAppSelector } from './app/hooks'

/**
 * Назначение: корневой компонент маршрутизации AutoCheck Web Dashboard.
 * Дата создания: 31-05-2026.
 * Автор: Команда.
 */
function App() {
  const isAuthenticated = useAppSelector((state) => state.auth.isAuthenticated)

  return (
    <Routes>
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <LoginPage />}
      />
      <Route
        path="/"
        element={isAuthenticated ? <AppLayout /> : <Navigate to="/login" replace />}
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="submissions/new" element={<UploadSubmissionPage />} />
        <Route path="submissions/:submissionId" element={<SubmissionDetailsPage />} />
        <Route path="assignments/new" element={<CreateAssignmentPage />} />
        <Route path="statistics" element={<StatisticsPage />} />
      </Route>
      <Route path="*" element={<Navigate to={isAuthenticated ? '/dashboard' : '/login'} replace />} />
    </Routes>
  )
}

export default App

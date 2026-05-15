import { Navigate, Route, Routes } from 'react-router-dom'
import type { ReactElement } from 'react'
import { useAuth } from './auth/AuthContext'
import Layout from './layout/Layout'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import DashboardPage from './pages/DashboardPage'
import CitasPage from './pages/CitasPage'
import ServiciosPage from './pages/ServiciosPage'

function Private({ children }: { children: ReactElement }) {
  const { user } = useAuth()
  if (!user) return <Navigate to="/login" replace />
  return children
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route
        path="/"
        element={
          <Private>
            <Layout />
          </Private>
        }
      >
        <Route index element={<DashboardPage />} />
        <Route path="citas" element={<CitasPage />} />
        <Route path="servicios" element={<ServiciosPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

import { Link, Navigate, useNavigate } from 'react-router-dom'
import { FormEvent, useState } from 'react'
import { useAuth } from '../auth/AuthContext'
import { apiFetch } from '../api'

export default function LoginPage() {
  const { login, user } = useAuth()
  const nav = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  if (user) {
    return <Navigate to="/" replace />
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      const res = await apiFetch('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      })
      if (!res.ok) {
        setError(await res.text().catch(() => 'Error al iniciar sesión'))
        return
      }
      const data = (await res.json()) as { token: string; email: string; role: string; userId: number }
      login({
        token: data.token,
        email: data.email,
        role: data.role as 'ADMIN' | 'USER',
        userId: data.userId,
      })
      nav('/', { replace: true })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-wrap">
      <form className="card auth-card" onSubmit={onSubmit}>
        <h1>Iniciar sesión</h1>
        <p className="muted">Microservicios peluquería — JWT</p>
        <label>
          Email
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" />
        </label>
        <label>
          Contraseña
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="current-password"
          />
        </label>
        {error && <p className="error">{error}</p>}
        <button type="submit" className="btn primary" disabled={loading}>
          {loading ? 'Entrando…' : 'Entrar'}
        </button>
        <p className="muted small">
          ¿Sin cuenta? <Link to="/register">Registrarse</Link>
        </p>
      </form>
    </div>
  )
}

import { Link, Navigate, useNavigate } from 'react-router-dom'
import { FormEvent, useState } from 'react'
import { useAuth } from '../auth/AuthContext'
import { apiFetch } from '../api'

export default function RegisterPage() {
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
      const res = await apiFetch('/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      })
      if (!res.ok) {
        setError(await res.text().catch(() => 'No se pudo registrar'))
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
        <h1>Crear cuenta</h1>
        <p className="muted">El primer usuario del sistema será ADMIN.</p>
        <label>
          Email
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" />
        </label>
        <label>
          Contraseña (mín. 6)
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            minLength={6}
            autoComplete="new-password"
          />
        </label>
        {error && <p className="error">{error}</p>}
        <button type="submit" className="btn primary" disabled={loading}>
          {loading ? 'Creando…' : 'Registrarse'}
        </button>
        <p className="muted small">
          <Link to="/login">Volver al login</Link>
        </p>
      </form>
    </div>
  )
}

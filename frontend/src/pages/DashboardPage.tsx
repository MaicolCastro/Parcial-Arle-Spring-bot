import { useAuth } from '../auth/AuthContext'

export default function DashboardPage() {
  const { user } = useAuth()
  return (
    <div className="page">
      <h1>Bienvenido</h1>
      <p className="lead">
        Panel de la peluquería. Como <strong>{user?.role}</strong> puedes gestionar citas
        {user?.role === 'ADMIN' ? ' y el catálogo de servicios' : ''}.
      </p>
      <div className="grid cards">
        <div className="card">
          <h2>Citas</h2>
          <p className="muted">Reservas y seguimiento de turnos.</p>
          <p className="small">{user?.role === 'ADMIN' ? 'Ves todas las citas.' : 'Solo ves tus propias citas.'}</p>
        </div>
        <div className="card">
          <h2>Servicios</h2>
          <p className="muted">Cortes, barba, color…</p>
          <p className="small">{user?.role === 'ADMIN' ? 'Puedes crear, editar y borrar.' : 'Consulta en solo lectura.'}</p>
        </div>
      </div>
    </div>
  )
}

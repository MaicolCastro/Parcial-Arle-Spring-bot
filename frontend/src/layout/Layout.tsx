import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

export default function Layout() {
  const { user, logout } = useAuth()
  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">Peluquería</div>
        <nav className="nav">
          <NavLink to="/" end>
            Inicio
          </NavLink>
          <NavLink to="/citas">Citas</NavLink>
          <NavLink to="/servicios">Servicios</NavLink>
        </nav>
        <div className="sidebar-footer">
          <div className="user-chip">
            <span className="email">{user?.email}</span>
            <span className={`role role-${user?.role.toLowerCase()}`}>{user?.role}</span>
          </div>
          <button type="button" className="btn ghost" onClick={logout}>
            Salir
          </button>
        </div>
      </aside>
      <main className="main">
        <Outlet />
      </main>
    </div>
  )
}

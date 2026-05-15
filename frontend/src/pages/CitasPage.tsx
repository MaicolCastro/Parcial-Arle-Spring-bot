import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { apiFetch } from '../api'
import { useAuth } from '../auth/AuthContext'

type CitaEstado = 'PENDIENTE' | 'CONFIRMADA' | 'CANCELADA'

type Cita = {
  id: number
  userId: number
  servicioId: number | null
  fechaHora: string
  notas: string | null
  estado: CitaEstado
}

type Servicio = { id: number; nombre: string; precio: number; duracionMinutos: number }

export default function CitasPage() {
  const { user } = useAuth()
  const [citas, setCitas] = useState<Cita[]>([])
  const [servicios, setServicios] = useState<Servicio[]>([])
  const [error, setError] = useState<string | null>(null)
  const [editing, setEditing] = useState<Cita | null>(null)
  const [form, setForm] = useState({
    servicioId: '' as string | number,
    fechaHora: '',
    notas: '',
    estado: 'PENDIENTE' as CitaEstado,
  })

  const load = useCallback(async () => {
    setError(null)
    const res = await apiFetch('/api/citas')
    if (!res.ok) {
      setError(await res.text())
      return
    }
    setCitas(await res.json())
  }, [])

  const loadServicios = useCallback(async () => {
    const res = await apiFetch('/api/servicios')
    if (res.ok) setServicios(await res.json())
  }, [])

  useEffect(() => {
    void load()
    void loadServicios()
  }, [load, loadServicios])

  function openCreate() {
    setEditing(null)
    setForm({ servicioId: '', fechaHora: toLocalInput(new Date()), notas: '', estado: 'PENDIENTE' })
  }

  function openEdit(c: Cita) {
    setEditing(c)
    setForm({
      servicioId: c.servicioId ?? '',
      fechaHora: toLocalInput(new Date(c.fechaHora)),
      notas: c.notas ?? '',
      estado: c.estado,
    })
  }

  async function save(e: FormEvent) {
    e.preventDefault()
    setError(null)
    const body: Record<string, unknown> = {
      fechaHora: new Date(form.fechaHora).toISOString(),
      notas: form.notas || null,
      servicioId: form.servicioId === '' ? null : Number(form.servicioId),
    }
    if (user?.role === 'ADMIN') {
      body.estado = form.estado
    }
    const url = editing ? `/api/citas/${editing.id}` : '/api/citas'
    const method = editing ? 'PUT' : 'POST'
    const res = await apiFetch(url, { method, body: JSON.stringify(body) })
    if (!res.ok) {
      setError(await res.text())
      return
    }
    setEditing(null)
    await load()
  }

  async function remove(id: number) {
    if (!confirm('¿Eliminar esta cita?')) return
    const res = await apiFetch(`/api/citas/${id}`, { method: 'DELETE' })
    if (!res.ok) {
      setError(await res.text())
      return
    }
    await load()
  }

  return (
    <div className="page">
      <div className="page-head">
        <h1>Citas</h1>
        <button type="button" className="btn primary" onClick={openCreate}>
          Nueva cita
        </button>
      </div>
      {error && <p className="error">{error}</p>}

      <div className="split">
        <div className="card table-card">
          <table className="table">
            <thead>
              <tr>
                {user?.role === 'ADMIN' && <th>Usuario</th>}
                <th>Fecha</th>
                <th>Servicio</th>
                <th>Estado</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {citas.map((c) => (
                <tr key={c.id}>
                  {user?.role === 'ADMIN' && <td>{c.userId}</td>}
                  <td>{new Date(c.fechaHora).toLocaleString()}</td>
                  <td>{c.servicioId ?? '—'}</td>
                  <td>
                    <span className={`pill estado-${c.estado.toLowerCase()}`}>{c.estado}</span>
                  </td>
                  <td className="actions">
                    <button type="button" className="btn small" onClick={() => openEdit(c)}>
                      Editar
                    </button>
                    <button type="button" className="btn small danger" onClick={() => void remove(c.id)}>
                      Borrar
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {citas.length === 0 && <p className="muted pad">No hay citas.</p>}
        </div>

        <form className="card form-card" onSubmit={save}>
          <h2>{editing ? 'Editar cita' : 'Nueva cita'}</h2>
          <label>
            Servicio (opcional)
            <select
              value={form.servicioId}
              onChange={(e) => setForm({ ...form, servicioId: e.target.value === '' ? '' : Number(e.target.value) })}
            >
              <option value="">—</option>
              {servicios.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.nombre} ({s.precio} €)
                </option>
              ))}
            </select>
          </label>
          <label>
            Fecha y hora
            <input
              type="datetime-local"
              value={form.fechaHora}
              onChange={(e) => setForm({ ...form, fechaHora: e.target.value })}
              required
            />
          </label>
          <label>
            Notas
            <textarea value={form.notas} onChange={(e) => setForm({ ...form, notas: e.target.value })} rows={3} />
          </label>
          {user?.role === 'ADMIN' && (
            <label>
              Estado
              <select value={form.estado} onChange={(e) => setForm({ ...form, estado: e.target.value as CitaEstado })}>
                <option value="PENDIENTE">PENDIENTE</option>
                <option value="CONFIRMADA">CONFIRMADA</option>
                <option value="CANCELADA">CANCELADA</option>
              </select>
            </label>
          )}
          <div className="row">
            <button type="submit" className="btn primary">
              Guardar
            </button>
            {editing && (
              <button type="button" className="btn ghost" onClick={() => setEditing(null)}>
                Cancelar
              </button>
            )}
          </div>
        </form>
      </div>
    </div>
  )
}

function toLocalInput(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

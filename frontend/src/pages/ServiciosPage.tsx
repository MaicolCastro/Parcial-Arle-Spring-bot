import { FormEvent, useCallback, useEffect, useState } from 'react'
import { apiFetch } from '../api'
import { useAuth } from '../auth/AuthContext'

type Servicio = {
  id: number
  nombre: string
  descripcion: string | null
  precio: number
  duracionMinutos: number
}

export default function ServiciosPage() {
  const { user } = useAuth()
  const admin = user?.role === 'ADMIN'
  const [list, setList] = useState<Servicio[]>([])
  const [error, setError] = useState<string | null>(null)
  const [editing, setEditing] = useState<Servicio | null>(null)
  const [form, setForm] = useState({ nombre: '', descripcion: '', precio: '', duracionMinutos: '30' })

  const load = useCallback(async () => {
    setError(null)
    const res = await apiFetch('/api/servicios')
    if (!res.ok) {
      setError(await res.text())
      return
    }
    setList(await res.json())
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  function openCreate() {
    if (!admin) return
    setEditing(null)
    setForm({ nombre: '', descripcion: '', precio: '', duracionMinutos: '30' })
  }

  function openEdit(s: Servicio) {
    if (!admin) return
    setEditing(s)
    setForm({
      nombre: s.nombre,
      descripcion: s.descripcion ?? '',
      precio: String(s.precio),
      duracionMinutos: String(s.duracionMinutos),
    })
  }

  async function save(e: FormEvent) {
    e.preventDefault()
    if (!admin) return
    setError(null)
    const body = {
      nombre: form.nombre.trim(),
      descripcion: form.descripcion.trim() || null,
      precio: Number(form.precio),
      duracionMinutos: Number(form.duracionMinutos),
    }
    const url = editing ? `/api/servicios/${editing.id}` : '/api/servicios'
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
    if (!admin) return
    if (!confirm('¿Eliminar servicio?')) return
    const res = await apiFetch(`/api/servicios/${id}`, { method: 'DELETE' })
    if (!res.ok) {
      setError(await res.text())
      return
    }
    await load()
  }

  return (
    <div className="page">
      <div className="page-head">
        <h1>Servicios de peluquería</h1>
        {admin && (
          <button type="button" className="btn primary" onClick={openCreate}>
            Nuevo servicio
          </button>
        )}
      </div>
      {!admin && <p className="banner info">Como usuario puedes consultar el catálogo. Solo ADMIN modifica.</p>}
      {error && <p className="error">{error}</p>}

      <div className="split">
        <div className="card table-card">
          <table className="table">
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Precio</th>
                <th>Min</th>
                {admin && <th></th>}
              </tr>
            </thead>
            <tbody>
              {list.map((s) => (
                <tr key={s.id}>
                  <td>
                    <strong>{s.nombre}</strong>
                    {s.descripcion && <div className="muted small">{s.descripcion}</div>}
                  </td>
                  <td>{s.precio} €</td>
                  <td>{s.duracionMinutos}</td>
                  {admin && (
                    <td className="actions">
                      <button type="button" className="btn small" onClick={() => openEdit(s)}>
                        Editar
                      </button>
                      <button type="button" className="btn small danger" onClick={() => void remove(s.id)}>
                        Borrar
                      </button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {admin && (
          <form className="card form-card" onSubmit={save}>
            <h2>{editing ? 'Editar servicio' : 'Nuevo servicio'}</h2>
            <label>
              Nombre
              <input value={form.nombre} onChange={(e) => setForm({ ...form, nombre: e.target.value })} required />
            </label>
            <label>
              Descripción
              <textarea
                value={form.descripcion}
                onChange={(e) => setForm({ ...form, descripcion: e.target.value })}
                rows={3}
              />
            </label>
            <label>
              Precio (€)
              <input
                type="number"
                step="0.01"
                min="0"
                value={form.precio}
                onChange={(e) => setForm({ ...form, precio: e.target.value })}
                required
              />
            </label>
            <label>
              Duración (min, mín. 5)
              <input
                type="number"
                min={5}
                value={form.duracionMinutos}
                onChange={(e) => setForm({ ...form, duracionMinutos: e.target.value })}
                required
              />
            </label>
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
        )}
      </div>
    </div>
  )
}

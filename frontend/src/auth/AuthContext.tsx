import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react'

export type Role = 'ADMIN' | 'USER'

export type AuthUser = {
  token: string
  email: string
  role: Role
  userId: number
}

type AuthContextValue = {
  user: AuthUser | null
  login: (u: AuthUser) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

function loadStored(): AuthUser | null {
  const raw = localStorage.getItem('auth')
  if (!raw) return null
  try {
    return JSON.parse(raw) as AuthUser
  } catch {
    return null
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() => loadStored())

  const login = useCallback((u: AuthUser) => {
    localStorage.setItem('token', u.token)
    localStorage.setItem('auth', JSON.stringify(u))
    setUser(u)
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem('token')
    localStorage.removeItem('auth')
    setUser(null)
  }, [])

  const value = useMemo(() => ({ user, login, logout }), [user, login, logout])
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth fuera de AuthProvider')
  return ctx
}

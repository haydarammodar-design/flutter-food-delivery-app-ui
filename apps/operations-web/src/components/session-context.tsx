"use client";

import {
  api,
  clearStoredSession,
  getStoredSession,
  saveStoredSession,
  type AuthSession,
  type LoginCredentials,
} from "@/lib/api";
import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";

type SessionStatus = "loading" | "anonymous" | "authenticated";

type SessionContextValue = {
  status: SessionStatus;
  session: AuthSession | null;
  signIn: (credentials: LoginCredentials) => Promise<void>;
  signOut: () => void;
};

const SessionContext = createContext<SessionContextValue | null>(null);

export function SessionProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<SessionStatus>("loading");
  const [session, setSession] = useState<AuthSession | null>(null);

  useEffect(() => {
    const storedSession = getStoredSession();
    const frame = window.requestAnimationFrame(() => {
      setSession(storedSession);
      setStatus(storedSession ? "authenticated" : "anonymous");
    });

    return () => {
      window.cancelAnimationFrame(frame);
    };
  }, []);

  async function signIn(credentials: LoginCredentials): Promise<void> {
    const nextSession = await api.login(credentials);
    saveStoredSession(nextSession);
    setSession(nextSession);
    setStatus("authenticated");
  }

  function signOut(): void {
    clearStoredSession();
    setSession(null);
    setStatus("anonymous");
  }

  return (
    <SessionContext.Provider value={{ status, session, signIn, signOut }}>
      {children}
    </SessionContext.Provider>
  );
}

export function useSession(): SessionContextValue {
  const context = useContext(SessionContext);
  if (!context) {
    throw new Error("useSession must be used inside SessionProvider.");
  }

  return context;
}

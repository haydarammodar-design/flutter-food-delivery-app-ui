"use client";

import { Icon } from "@/components/icon";
import { useSession } from "@/components/session-context";
import { getErrorMessage } from "@/lib/api";
import { useState, type FormEvent } from "react";

export function SignIn() {
  const { signIn } = useSession();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      await signIn({ email: email.trim(), password });
    } catch (loginError) {
      setError(getErrorMessage(loginError));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="ops-signin-page">
      <section className="ops-signin-aside" aria-label="Operations console introduction">
        <div className="ops-signin-brand">
          <span className="ops-brand-mark" aria-hidden="true">
            <i />
            <i />
            <i />
          </span>
          <span>Fieldwork</span>
        </div>
        <div className="ops-signin-message">
          <p className="ops-eyebrow">Commerce operations</p>
          <h1>Run the work behind every storefront.</h1>
          <p>
            A focused workspace for category governance, merchant onboarding, and catalog control.
          </p>
        </div>
        <div className="ops-signin-grid" aria-hidden="true">
          <span />
          <span />
          <span />
          <span />
          <span />
          <span />
        </div>
        <p className="ops-signin-footnote">Admin and merchant access are determined by your API account.</p>
      </section>

      <section className="ops-signin-form-panel">
        <div className="ops-signin-form-wrap">
          <div className="ops-mobile-brand">
            <span className="ops-brand-mark" aria-hidden="true">
              <i />
              <i />
              <i />
            </span>
            <span>Fieldwork</span>
          </div>
          <div className="ops-signin-heading">
            <p className="ops-eyebrow">Secure sign in</p>
            <h2>Welcome to operations.</h2>
            <p>Use the account provisioned for your organization.</p>
          </div>

          <form className="ops-form ops-signin-form" onSubmit={handleSubmit}>
            {error ? (
              <div className="ops-alert ops-alert-error" role="alert">
                <Icon name="warning" size={17} />
                <span>{error}</span>
              </div>
            ) : null}
            <label>
              Work email
              <input
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                autoComplete="email"
                placeholder="name@company.com"
                required
              />
            </label>
            <label>
              Password
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                autoComplete="current-password"
                placeholder="Enter your password"
                required
              />
            </label>
            <button className="ops-button ops-button-primary ops-button-full" type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Signing in..." : "Sign in to console"}
              {!isSubmitting ? <Icon name="arrowRight" size={17} /> : null}
            </button>
          </form>

          <div className="ops-signin-security">
            <Icon name="lock" size={16} />
            <span>Your access token is stored in this browser&apos;s local storage.</span>
          </div>
        </div>
      </section>
    </main>
  );
}

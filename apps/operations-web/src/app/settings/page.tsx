"use client";

import { Icon } from "@/components/icon";
import { useSession } from "@/components/session-context";
import { PageHeader } from "@/components/ui";
import { apiBaseUrl } from "@/lib/api";
import { roleLabel } from "@/lib/roles";

export default function SettingsPage() {
  const { session, signOut } = useSession();

  return (
    <div className="ops-page-stack">
      <PageHeader
        eyebrow="Workspace settings"
        title="Session and connection"
        description="Review the local console session and the public API base URL it is configured to use."
      />

      <div className="ops-settings-grid">
        <section className="ops-panel ops-settings-panel">
          <div className="ops-panel-heading ops-panel-heading-tight">
            <div>
              <p className="ops-eyebrow">Signed-in account</p>
              <h2>Access context</h2>
            </div>
            <span className="ops-settings-icon">
              <Icon name="lock" size={19} />
            </span>
          </div>
          <dl className="ops-detail-list">
            <div>
              <dt>Email</dt>
              <dd>{session?.user.email || "Not provided by the login response"}</dd>
            </div>
            <div>
              <dt>Role</dt>
              <dd>{roleLabel(session?.user.role)}</dd>
            </div>
            <div>
              <dt>Merchant ID</dt>
              <dd>{session?.user.merchantId || "Not assigned"}</dd>
            </div>
          </dl>
          <button className="ops-button ops-button-danger" type="button" onClick={signOut}>
            <Icon name="logout" size={17} />
            Sign out of this browser
          </button>
        </section>

        <section className="ops-panel ops-settings-panel">
          <div className="ops-panel-heading ops-panel-heading-tight">
            <div>
              <p className="ops-eyebrow">API connection</p>
              <h2>Environment contract</h2>
            </div>
            <span className="ops-settings-icon">
              <Icon name="settings" size={19} />
            </span>
          </div>
          <dl className="ops-detail-list">
            <div>
              <dt>Base URL</dt>
              <dd className="ops-code-value">{apiBaseUrl}</dd>
            </div>
            <div>
              <dt>Authentication</dt>
              <dd>Bearer token from POST /v1/auth/login</dd>
            </div>
            <div>
              <dt>Configuration file</dt>
              <dd className="ops-code-value">.env.local</dd>
            </div>
          </dl>
          <p className="ops-settings-note">
            Set <code>NEXT_PUBLIC_API_URL</code> before running the web app so browser requests reach your NestJS
            service.
          </p>
        </section>
      </div>
    </div>
  );
}

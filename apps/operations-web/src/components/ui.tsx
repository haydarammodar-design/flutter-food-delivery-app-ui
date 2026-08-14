import { Icon } from "@/components/icon";
import type { ReactNode } from "react";

type PageHeaderProps = {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
};

export function PageHeader({ eyebrow, title, description, action }: PageHeaderProps) {
  return (
    <header className="ops-page-header">
      <div>
        <p className="ops-eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="ops-page-description">{description}</p>
      </div>
      {action ? <div className="ops-page-actions">{action}</div> : null}
    </header>
  );
}

export function Alert({ children, tone = "error" }: { children: ReactNode; tone?: "error" | "success" }) {
  return (
    <div className={`ops-alert ops-alert-${tone}`} role={tone === "error" ? "alert" : "status"}>
      <Icon name={tone === "error" ? "warning" : "check"} size={17} />
      <span>{children}</span>
    </div>
  );
}

export function EmptyState({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="ops-empty-state">
      <div className="ops-empty-icon">
        <Icon name="catalog" size={22} />
      </div>
      <h2>{title}</h2>
      <p>{description}</p>
      {action ? <div className="ops-empty-action">{action}</div> : null}
    </div>
  );
}

export function AccessPanel({ title, description }: { title: string; description: string }) {
  return (
    <div className="ops-access-panel">
      <div className="ops-empty-icon">
        <Icon name="lock" size={22} />
      </div>
      <p className="ops-eyebrow">Restricted workspace</p>
      <h1>{title}</h1>
      <p>{description}</p>
    </div>
  );
}

export function StatusPill({ status }: { status: string }) {
  const normalized = status.toUpperCase();
  let tone = "neutral";

  if (normalized.includes("INACTIVE") || normalized.includes("SUSPEND") || normalized.includes("REJECT")) {
    tone = "muted";
  } else if (normalized.includes("ACTIVE") || normalized.includes("OPEN") || normalized.includes("AVAILABLE")) {
    tone = "positive";
  } else if (normalized.includes("PENDING") || normalized.includes("DRAFT")) {
    tone = "attention";
  }

  const label = status
    .replace(/[_-]/g, " ")
    .toLowerCase()
    .replace(/\b\w/g, (character) => character.toUpperCase());

  return <span className={`ops-status ops-status-${tone}`}>{label}</span>;
}

export function LoadingRows({ columns, rows = 4 }: { columns: number; rows?: number }) {
  return Array.from({ length: rows }, (_, rowIndex) => (
    <tr key={`loading-row-${rowIndex}`}>
      {Array.from({ length: columns }, (_, columnIndex) => (
        <td key={`loading-cell-${rowIndex}-${columnIndex}`}>
          <span className="ops-skeleton" />
        </td>
      ))}
    </tr>
  ));
}

export function formatDate(value: string | undefined): string {
  if (!value) {
    return "Not available";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "Not available";
  }

  return new Intl.DateTimeFormat("en", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(date);
}

export function formatNumber(value: number | undefined): string {
  if (value === undefined || !Number.isFinite(value)) {
    return "Not available";
  }

  return new Intl.NumberFormat("en", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(value);
}

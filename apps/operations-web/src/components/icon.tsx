type IconName =
  | "overview"
  | "categories"
  | "merchants"
  | "catalog"
  | "orders"
  | "settings"
  | "refresh"
  | "plus"
  | "logout"
  | "arrowRight"
  | "lock"
  | "store"
  | "check"
  | "warning";

type IconProps = {
  name: IconName;
  size?: number;
};

const strokeProps = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.8,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

export function Icon({ name, size = 18 }: IconProps) {
  const content = (() => {
    switch (name) {
      case "overview":
        return (
          <>
            <rect x="3" y="3" width="7" height="7" rx="1" {...strokeProps} />
            <rect x="14" y="3" width="7" height="7" rx="1" {...strokeProps} />
            <rect x="3" y="14" width="7" height="7" rx="1" {...strokeProps} />
            <rect x="14" y="14" width="7" height="7" rx="1" {...strokeProps} />
          </>
        );
      case "categories":
        return (
          <>
            <path d="m12 3 8 4.4L12 12 4 7.4 12 3Z" {...strokeProps} />
            <path d="m4 12 8 4.5 8-4.5M4 16.7l8 4.3 8-4.3" {...strokeProps} />
          </>
        );
      case "merchants":
        return (
          <>
            <path d="M4 10.5h16v9.8H4zM3 6.3h18l-1.5 4.2h-15L3 6.3Z" {...strokeProps} />
            <path d="M9 10.5v9.8M15 14.5h2" {...strokeProps} />
          </>
        );
      case "catalog":
        return (
          <>
            <path d="m12 3 8 4.5v9L12 21l-8-4.5v-9L12 3Z" {...strokeProps} />
            <path d="m4.3 7.6 7.7 4.5 7.7-4.5M12 12.1V21" {...strokeProps} />
          </>
        );
      case "orders":
        return (
          <>
            <rect x="5" y="3" width="14" height="18" rx="2" {...strokeProps} />
            <path d="M9 3.2h6v3H9zM9 11h6M9 15h4" {...strokeProps} />
          </>
        );
      case "settings":
        return (
          <>
            <circle cx="12" cy="12" r="3" {...strokeProps} />
            <path
              d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.2 2.2-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.5v.2h-3.2v-.2a1.7 1.7 0 0 0-1-1.5 1.7 1.7 0 0 0-1.9.3l-.1.1-2.2-2.2.1-.1a1.7 1.7 0 0 0 .3-1.9 1.7 1.7 0 0 0-1.5-1H5v-3.2h.2a1.7 1.7 0 0 0 1.5-1 1.7 1.7 0 0 0-.3-1.9l-.1-.1 2.2-2.2.1.1a1.7 1.7 0 0 0 1.9.3 1.7 1.7 0 0 0 1-1.5V3.5h3.2v.2a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.9-.3l.1-.1 2.2 2.2-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.5 1h.2V13h-.2a1.7 1.7 0 0 0-1.5 1Z"
              {...strokeProps}
            />
          </>
        );
      case "refresh":
        return <path d="M20 11a8 8 0 1 0 1.5 4.7M20 4v7h-7" {...strokeProps} />;
      case "plus":
        return <path d="M12 5v14M5 12h14" {...strokeProps} />;
      case "logout":
        return (
          <>
            <path d="M10 5H5v14h5M14 8l4 4-4 4M9 12h9" {...strokeProps} />
          </>
        );
      case "arrowRight":
        return <path d="M5 12h14M13 6l6 6-6 6" {...strokeProps} />;
      case "lock":
        return (
          <>
            <rect x="5" y="10" width="14" height="11" rx="2" {...strokeProps} />
            <path d="M8 10V7a4 4 0 1 1 8 0v3" {...strokeProps} />
          </>
        );
      case "store":
        return (
          <>
            <path d="M3 9h18v11H3zM2 5h20l-1.5 4H3.5L2 5Z" {...strokeProps} />
            <path d="M8 9v11M14 13h3" {...strokeProps} />
          </>
        );
      case "check":
        return <path d="m5 12 4.2 4.2L19.5 6" {...strokeProps} />;
      case "warning":
        return (
          <>
            <path d="m12 3 9 17H3L12 3Z" {...strokeProps} />
            <path d="M12 9v4M12 16h.01" {...strokeProps} />
          </>
        );
    }
  })();

  return (
    <svg
      aria-hidden="true"
      focusable="false"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
    >
      {content}
    </svg>
  );
}

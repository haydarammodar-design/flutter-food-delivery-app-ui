export function isAdminRole(role: string | undefined): boolean {
  return Boolean(role && role.toUpperCase().includes("ADMIN"));
}

export function roleLabel(role: string | undefined): string {
  if (!role || role === "UNKNOWN") {
    return "Operations user";
  }

  return role
    .toLowerCase()
    .split(/[_\s-]+/)
    .filter(Boolean)
    .map((part) => `${part[0].toUpperCase()}${part.slice(1)}`)
    .join(" ");
}

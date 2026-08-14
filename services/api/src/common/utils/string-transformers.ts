type TransformInput = { value: unknown };

export function trimString({ value }: TransformInput): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export function trimLowercaseString({ value }: TransformInput): unknown {
  return typeof value === 'string' ? value.trim().toLowerCase() : value;
}

export function trimUppercaseString({ value }: TransformInput): unknown {
  return typeof value === 'string' ? value.trim().toUpperCase() : value;
}

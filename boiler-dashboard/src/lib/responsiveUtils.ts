import { breakpoints, Breakpoint } from './breakpoints';

export type ResponsiveValue<T> = T | Partial<Record<Breakpoint, T>>;

export function createResponsiveStyles<T>(
  property: string,
  value: ResponsiveValue<T>,
  transform?: (val: T) => string
): string {
  if (typeof value === 'object' && value !== null) {
    return Object.entries(value)
      .map(([breakpoint, val]) => {
        const bp = breakpoints[breakpoint as Breakpoint];
        const cssValue = transform ? transform(val as T) : String(val);
        return `@media (min-width: ${bp}) { ${property}: ${cssValue}; }`;
      })
      .join('\n');
  }
  
  const cssValue = transform ? transform(value as T) : String(value);
  return `${property}: ${cssValue};`;
}

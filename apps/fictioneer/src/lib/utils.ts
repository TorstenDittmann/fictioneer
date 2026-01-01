/**
 * Generate a unique ID with a prefix
 */
export function generate_id(prefix: string): string {
	return `${prefix}-${Date.now()}-${Math.random().toString(36).substring(2, 11)}`;
}

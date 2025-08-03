// Backend API configuration
const BACKEND_URL = 'http://localhost:3001/api';

export class AIWritingBackendService {
	private async call_backend(endpoint: string, data: unknown): Promise<unknown> {
		const response = await fetch(`${BACKEND_URL}/${endpoint}`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify(data)
		});

		if (!response.ok) {
			throw new Error(`Backend request failed: ${response.statusText}`);
		}

		return await response.json();
	}

	async continue_writing(
		content: string,
		context: unknown = {},
		word_count: number = 100
	): Promise<string> {
		const result = await this.call_backend('continue', {
			content,
			context,
			word_count
		});
		
		if (result && typeof result === 'object' && result !== null) {
			const res = result as Record<string, unknown>;
			return typeof res.text === 'string' ? res.text : '';
		}
		return '';
	}

	async check_health(): Promise<boolean> {
		try {
			const response = await fetch(`${BACKEND_URL}/health`);
			return response.ok;
		} catch {
			return false;
		}
	}
}

export const ai_writing_backend_service = new AIWritingBackendService();
// Backend API configuration
const BACKEND_URL = 'http://localhost:3001/api';

export class AIWritingBackendService {
	private async call_backend(endpoint: string, data: unknown): Promise<unknown> {
		const response = await fetch(`${BACKEND_URL}/${endpoint}`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json'
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
		word_count: number = 100,
		onStream?: (chunk: string) => void
	): Promise<string> {
		if (onStream) {
			return this.stream_continue_writing(content, context, word_count, onStream);
		}

		const result = await this.call_backend('continue', {
			content,
			context,
			word_count,
			stream: false
		});

		if (result && typeof result === 'object' && result !== null) {
			const res = result as Record<string, unknown>;
			return typeof res.text === 'string' ? res.text : '';
		}
		return '';
	}

	private async stream_continue_writing(
		content: string,
		context: unknown = {},
		word_count: number = 100,
		onStream: (chunk: string) => void
	): Promise<string> {
		const response = await fetch(`${BACKEND_URL}/continue`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({
				content,
				context,
				word_count,
				stream: true
			})
		});

		if (!response.ok) {
			throw new Error(`Backend request failed: ${response.statusText}`);
		}

		// Get the response as a text stream
		const reader = response.body?.getReader();
		if (!reader) {
			throw new Error('No response body reader available');
		}

		const decoder = new TextDecoder();
		let fullText = '';

		try {
			while (true) {
				const { done, value } = await reader.read();

				if (done) break;

				const chunk = decoder.decode(value, { stream: true });
				fullText += chunk;
				onStream(fullText);
			}
		} finally {
			reader.releaseLock();
		}

		return fullText;
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

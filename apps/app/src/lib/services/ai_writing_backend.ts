import { PUBLIC_INTELLIGENCE_SERVER_URL } from '$env/static/public';

// Backend API configuration
const BACKEND_URL = PUBLIC_INTELLIGENCE_SERVER_URL || 'http://localhost:3001/api';

export class AIWritingBackendService {
	private current_abort_controller: AbortController | null = null;
	private token: string | null = null;

	private async call_backend(
		endpoint: string,
		data: unknown,
		signal?: AbortSignal
	): Promise<unknown> {
		const response = await fetch(`${BACKEND_URL}/${endpoint}`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${this.token}`,
				Accept: 'text/plain'
			},
			body: JSON.stringify(data),
			signal
		});

		if (!response.ok) {
			throw new Error(`Backend request failed: ${response.statusText}`);
		}

		return await response.json();
	}

	private async *call_backend_stream(
		endpoint: string,
		data: unknown,
		signal?: AbortSignal
	): AsyncGenerator<string, void, unknown> {
		const response = await fetch(`${BACKEND_URL}/${endpoint}`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${this.token}`,
				Accept: 'text/plain+stream'
			},
			body: JSON.stringify(data),
			signal
		});

		if (!response.ok) {
			throw new Error(`Backend request failed: ${response.statusText}`);
		}

		const reader = response.body?.getReader();
		if (!reader) {
			throw new Error('No response body reader available');
		}

		const decoder = new TextDecoder();

		try {
			while (true) {
				const { done, value } = await reader.read();
				if (done) break;

				const chunk = decoder.decode(value, { stream: true });
				yield chunk;
			}
		} finally {
			reader.releaseLock();
		}
	}

	async *continue_writing(
		content: string,
		context: unknown = {},
		word_count: number = 100
	): AsyncGenerator<string, void, unknown> {
		// Cancel any existing request
		this.cancel_current_request();

		// Create new abort controller for this request
		this.current_abort_controller = new AbortController();

		try {
			let accumulated_text = '';
			for await (const chunk of this.call_backend_stream(
				'continue',
				{
					content,
					context,
					word_count
				},
				this.current_abort_controller?.signal
			)) {
				accumulated_text += chunk;
				yield accumulated_text;
			}
		} finally {
			// Clean up abort controller on completion
			this.current_abort_controller = null;
		}
	}

	cancel_current_request(): void {
		if (this.current_abort_controller) {
			this.current_abort_controller.abort();
			this.current_abort_controller = null;
		}
	}

	async check_health(): Promise<boolean> {
		try {
			const response = await fetch(`${BACKEND_URL}/health`);
			return response.ok;
		} catch {
			return false;
		}
	}

	is_request_active(): boolean {
		return this.current_abort_controller !== null;
	}

	set_token(token: string | null) {
		this.token = token;
	}
}

export const ai_writing_backend_service = new AIWritingBackendService();

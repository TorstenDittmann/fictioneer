import { PUBLIC_INTELLIGENCE_SERVER_URL } from '$env/static/public';

// Backend API configuration
const BACKEND_URL = PUBLIC_INTELLIGENCE_SERVER_URL || 'http://localhost:3001/api';

export class AIWritingBackendService {
	private current_abort_controller: AbortController | null = null;

	private async call_backend(
		endpoint: string,
		data: unknown,
		signal?: AbortSignal
	): Promise<unknown> {
		const response = await fetch(`${BACKEND_URL}/${endpoint}`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify(data),
			signal
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
		// Cancel any existing request
		this.cancel_current_request();

		// Create new abort controller for this request
		this.current_abort_controller = new AbortController();

		if (onStream) {
			return this.stream_continue_writing(content, context, word_count, onStream);
		}

		const result = await this.call_backend(
			'continue',
			{
				content,
				context,
				word_count,
				stream: false
			},
			this.current_abort_controller.signal
		);

		// Clean up abort controller on successful completion
		this.current_abort_controller = null;

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
			}),
			signal: this.current_abort_controller?.signal
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
				// Check if request was cancelled
				if (this.current_abort_controller?.signal.aborted) {
					break;
				}

				const { done, value } = await reader.read();

				if (done) break;

				const chunk = decoder.decode(value, { stream: true });
				fullText += chunk;
				onStream(fullText);
			}
		} finally {
			reader.releaseLock();
			// Clean up abort controller on completion
			this.current_abort_controller = null;
		}

		return fullText;
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
}

export const ai_writing_backend_service = new AIWritingBackendService();

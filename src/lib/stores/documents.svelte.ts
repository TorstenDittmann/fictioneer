export interface Document {
	id: string;
	title: string;
	content: string;
	createdAt: Date;
	updatedAt: Date;
	wordCount: number;
	characterCount: number;
}

class DocumentStore {
	private _documents = $state<Document[]>([]);
	private _activeDocumentId = $state<string | null>(null);
	private _isDistactionFree = $state(false);

	constructor() {
		// Create a default document
		this.createDocument('Untitled Document');
	}

	get documents(): Document[] {
		return this._documents;
	}

	get activeDocument(): Document | null {
		if (!this._activeDocumentId) return null;
		return this._documents.find((doc) => doc.id === this._activeDocumentId) || null;
	}

	get activeDocumentId(): string | null {
		return this._activeDocumentId;
	}

	get isDistractionFree(): boolean {
		return this._isDistactionFree;
	}

	createDocument(title: string = 'Untitled Document'): string {
		const id = crypto.randomUUID();
		const now = new Date();

		const newDocument: Document = {
			id,
			title,
			content: '',
			createdAt: now,
			updatedAt: now,
			wordCount: 0,
			characterCount: 0
		};

		this._documents.push(newDocument);
		this._activeDocumentId = id;

		return id;
	}

	updateDocument(id: string, updates: Partial<Omit<Document, 'id' | 'createdAt'>>) {
		const docIndex = this._documents.findIndex((doc) => doc.id === id);
		if (docIndex === -1) return;

		const updatedDoc = {
			...this._documents[docIndex],
			...updates,
			updatedAt: new Date()
		};

		// Calculate word and character count if content is updated
		if (updates.content !== undefined) {
			const textContent = this.stripHtml(updates.content);
			updatedDoc.wordCount = this.countWords(textContent);
			updatedDoc.characterCount = textContent.length;
		}

		this._documents[docIndex] = updatedDoc;
	}

	deleteDocument(id: string) {
		if (this._documents.length <= 1) return; // Don't delete the last document

		const docIndex = this._documents.findIndex((doc) => doc.id === id);
		if (docIndex === -1) return;

		this._documents.splice(docIndex, 1);

		// If we deleted the active document, switch to the first available one
		if (this._activeDocumentId === id) {
			this._activeDocumentId = this._documents[0]?.id || null;
		}
	}

	setActiveDocument(id: string) {
		const doc = this._documents.find((doc) => doc.id === id);
		if (doc) {
			this._activeDocumentId = id;
		}
	}

	toggleDistractionFree() {
		this._isDistactionFree = !this._isDistactionFree;
	}

	setDistractionFree(value: boolean) {
		this._isDistactionFree = value;
	}

	private stripHtml(html: string): string {
		const div = document.createElement('div');
		div.innerHTML = html;
		return div.textContent || div.innerText || '';
	}

	private countWords(text: string): number {
		return text
			.trim()
			.split(/\s+/)
			.filter((word) => word.length > 0).length;
	}

	// Get total statistics across all documents
	getTotalStats() {
		return this._documents.reduce(
			(acc, doc) => ({
				totalWords: acc.totalWords + doc.wordCount,
				totalCharacters: acc.totalCharacters + doc.characterCount,
				totalDocuments: acc.totalDocuments + 1
			}),
			{ totalWords: 0, totalCharacters: 0, totalDocuments: 0 }
		);
	}
}

export const documentStore = new DocumentStore();

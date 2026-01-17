import { describe, it, expect } from 'bun:test';

/**
 * Test utility functions from projects.svelte.ts
 * These are recreated here since the service uses Svelte 5 runes
 */

function strip_html(html: string): string {
	return html.replace(/<[^>]*>/g, '');
}

function count_words(text: string): number {
	return text
		.trim()
		.split(/\s+/)
		.filter((word) => word.length > 0).length;
}

function escape_regex(str: string): string {
	return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

describe('strip_html', () => {
	it('should remove basic HTML tags', () => {
		expect(strip_html('<p>Hello</p>')).toBe('Hello');
	});

	it('should remove multiple tags', () => {
		expect(strip_html('<p>Hello</p><p>World</p>')).toBe('HelloWorld');
	});

	it('should remove nested tags', () => {
		expect(strip_html('<div><p><strong>Hello</strong></p></div>')).toBe('Hello');
	});

	it('should handle self-closing tags', () => {
		expect(strip_html('Hello<br/>World')).toBe('HelloWorld');
	});

	it('should handle tags with attributes', () => {
		expect(strip_html('<p class="intro" id="main">Hello</p>')).toBe('Hello');
	});

	it('should return empty string for empty input', () => {
		expect(strip_html('')).toBe('');
	});

	it('should return text unchanged if no tags', () => {
		expect(strip_html('Hello World')).toBe('Hello World');
	});

	it('should handle unclosed tags', () => {
		expect(strip_html('<p>Hello')).toBe('Hello');
	});

	it('should preserve text between tags', () => {
		expect(strip_html('<p>Hello</p> <p>World</p>')).toBe('Hello World');
	});

	it('should handle complex HTML content', () => {
		const html =
			'<div class="editor"><p>First paragraph.</p><p>Second <em>emphasized</em> text.</p></div>';
		expect(strip_html(html)).toBe('First paragraph.Second emphasized text.');
	});
});

describe('count_words', () => {
	it('should count words in normal text', () => {
		expect(count_words('Hello world')).toBe(2);
	});

	it('should handle multiple spaces', () => {
		expect(count_words('Hello    world')).toBe(2);
	});

	it('should handle leading and trailing spaces', () => {
		expect(count_words('  Hello world  ')).toBe(2);
	});

	it('should return 0 for empty string', () => {
		expect(count_words('')).toBe(0);
	});

	it('should return 0 for whitespace only', () => {
		expect(count_words('   ')).toBe(0);
	});

	it('should handle single word', () => {
		expect(count_words('Hello')).toBe(1);
	});

	it('should handle punctuation attached to words', () => {
		expect(count_words('Hello, world!')).toBe(2);
	});

	it('should handle newlines as separators', () => {
		expect(count_words('Hello\nworld')).toBe(2);
	});

	it('should handle tabs as separators', () => {
		expect(count_words('Hello\tworld')).toBe(2);
	});

	it('should count long text correctly', () => {
		const text = 'The quick brown fox jumps over the lazy dog';
		expect(count_words(text)).toBe(9);
	});

	it('should handle mixed whitespace', () => {
		expect(count_words('Hello\n\t  world')).toBe(2);
	});
});

describe('escape_regex', () => {
	it('should escape dots', () => {
		expect(escape_regex('hello.world')).toBe('hello\\.world');
	});

	it('should escape asterisks', () => {
		expect(escape_regex('hello*world')).toBe('hello\\*world');
	});

	it('should escape plus signs', () => {
		expect(escape_regex('hello+world')).toBe('hello\\+world');
	});

	it('should escape question marks', () => {
		expect(escape_regex('hello?world')).toBe('hello\\?world');
	});

	it('should escape caret', () => {
		expect(escape_regex('^hello')).toBe('\\^hello');
	});

	it('should escape dollar sign', () => {
		expect(escape_regex('hello$')).toBe('hello\\$');
	});

	it('should escape curly braces', () => {
		expect(escape_regex('hello{1,2}')).toBe('hello\\{1,2\\}');
	});

	it('should escape parentheses', () => {
		expect(escape_regex('(hello)')).toBe('\\(hello\\)');
	});

	it('should escape pipe', () => {
		expect(escape_regex('hello|world')).toBe('hello\\|world');
	});

	it('should escape square brackets', () => {
		expect(escape_regex('[hello]')).toBe('\\[hello\\]');
	});

	it('should escape backslash', () => {
		expect(escape_regex('hello\\world')).toBe('hello\\\\world');
	});

	it('should handle multiple special characters', () => {
		expect(escape_regex('(hello.*world)?')).toBe('\\(hello\\.\\*world\\)\\?');
	});

	it('should return unchanged string if no special characters', () => {
		expect(escape_regex('hello world')).toBe('hello world');
	});

	it('should handle empty string', () => {
		expect(escape_regex('')).toBe('');
	});

	it('should work correctly when used in RegExp', () => {
		const special_string = 'hello.world*test';
		const escaped = escape_regex(special_string);
		const regex = new RegExp(escaped);

		expect(regex.test('hello.world*test')).toBe(true);
		expect(regex.test('helloXworldYtest')).toBe(false);
	});
});

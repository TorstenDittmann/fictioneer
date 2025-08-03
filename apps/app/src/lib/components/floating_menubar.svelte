<script lang="ts">
	import { Menubar } from 'bits-ui';
	import type { Editor } from '@tiptap/core';

	interface Props {
		editor: Editor | null;
		visible?: boolean;
	}

	let { editor, visible = true }: Props = $props();

	// Show menubar when editor exists and is visible
	let should_show_menubar = $derived(visible && editor);

	// Text formatting functions
	function toggle_bold() {
		editor?.chain().focus().toggleBold().run();
	}

	function toggle_italic() {
		editor?.chain().focus().toggleItalic().run();
	}

	function toggle_underline() {
		editor?.chain().focus().toggleUnderline().run();
	}

	function toggle_strikethrough() {
		editor?.chain().focus().toggleStrike().run();
	}

	// Heading functions
	function set_heading(level: 1 | 2 | 3 | 4 | 5 | 6) {
		editor?.chain().focus().toggleHeading({ level }).run();
	}

	function set_paragraph() {
		editor?.chain().focus().setParagraph().run();
	}

	// List functions
	function toggle_bullet_list() {
		editor?.chain().focus().toggleBulletList().run();
	}

	function toggle_ordered_list() {
		editor?.chain().focus().toggleOrderedList().run();
	}

	// Block functions
	function toggle_blockquote() {
		editor?.chain().focus().toggleBlockquote().run();
	}

	function insert_horizontal_rule() {
		editor?.chain().focus().setHorizontalRule().run();
	}

	// Edit functions
	function undo() {
		editor?.chain().focus().undo().run();
	}

	function redo() {
		editor?.chain().focus().redo().run();
	}
</script>

{#if should_show_menubar}
	<div
		class="absolute top-4 left-1/2 z-50 -translate-x-1/2 transform transition-all duration-200 ease-in-out"
	>
		<Menubar.Root
			class="flex items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-2 shadow-lg dark:border-gray-700 dark:bg-gray-800"
		>
			<!-- Edit Menu -->
			<Menubar.Menu>
				<Menubar.Trigger
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-gray-600 transition-colors duration-200 hover:bg-gray-100 focus:outline-none data-[state=open]:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:data-[state=open]:bg-gray-700"
				>
					Edit
				</Menubar.Trigger>
				<Menubar.Portal>
					<Menubar.Content
						class="z-50 w-48 rounded-lg border border-gray-200 bg-white p-1 shadow-lg dark:border-gray-700 dark:bg-gray-900"
						sideOffset={6}
					>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={undo}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"
								/>
							</svg>
							Undo
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={redo}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M21 10h-10a8 8 0 00-8 8v2m18-10l-6 6m6-6l-6-6"
								/>
							</svg>
							Redo
						</Menubar.Item>
					</Menubar.Content>
				</Menubar.Portal>
			</Menubar.Menu>

			<!-- Format Menu -->
			<Menubar.Menu>
				<Menubar.Trigger
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-gray-600 transition-colors duration-200 hover:bg-gray-100 focus:outline-none data-[state=open]:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:data-[state=open]:bg-gray-700"
				>
					Format
				</Menubar.Trigger>
				<Menubar.Portal>
					<Menubar.Content
						class="z-50 w-48 rounded-lg border border-gray-200 bg-white p-1 shadow-lg dark:border-gray-700 dark:bg-gray-900"
						sideOffset={6}
					>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={toggle_bold}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M6 4h8a4 4 0 014 4 4 4 0 01-4 4H6z"
								/>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M6 12h9a4 4 0 014 4 4 4 0 01-4 4H6z"
								/>
							</svg>
							Bold
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={toggle_italic}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M19 4h-9M14 20H5m5-16L8 20"
								/>
							</svg>
							Italic
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={toggle_underline}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 19h16M8 4v10a4 4 0 008 0V4"
								/>
							</svg>
							Underline
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={toggle_strikethrough}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M6 12h12M6 4h4v8M14 4h4v8"
								/>
							</svg>
							Strikethrough
						</Menubar.Item>
						<Menubar.Separator class="my-1 h-px bg-gray-200 dark:bg-gray-700" />
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={toggle_blockquote}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M11 15h2a2 2 0 002-2V9a2 2 0 00-2-2h-2v8zM7 15h2a2 2 0 002-2V9a2 2 0 00-2-2H7v8z"
								/>
							</svg>
							Quote
						</Menubar.Item>
					</Menubar.Content>
				</Menubar.Portal>
			</Menubar.Menu>

			<!-- Headings Menu -->
			<Menubar.Menu>
				<Menubar.Trigger
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-gray-600 transition-colors duration-200 hover:bg-gray-100 focus:outline-none data-[state=open]:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:data-[state=open]:bg-gray-700"
				>
					Headings
				</Menubar.Trigger>
				<Menubar.Portal>
					<Menubar.Content
						class="z-50 w-48 rounded-lg border border-gray-200 bg-white p-1 shadow-lg dark:border-gray-700 dark:bg-gray-900"
						sideOffset={6}
					>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={set_paragraph}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 6h16M4 12h16M4 18h7"
								/>
							</svg>
							Paragraph
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={() => set_heading(1)}
						>
							<span class="mr-2 text-lg font-bold">H1</span>
							Heading 1
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={() => set_heading(2)}
						>
							<span class="mr-2 text-base font-bold">H2</span>
							Heading 2
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={() => set_heading(3)}
						>
							<span class="mr-2 text-sm font-bold">H3</span>
							Heading 3
						</Menubar.Item>
					</Menubar.Content>
				</Menubar.Portal>
			</Menubar.Menu>

			<!-- Lists Menu -->
			<Menubar.Menu>
				<Menubar.Trigger
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-gray-600 transition-colors duration-200 hover:bg-gray-100 focus:outline-none data-[state=open]:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:data-[state=open]:bg-gray-700"
				>
					Lists
				</Menubar.Trigger>
				<Menubar.Portal>
					<Menubar.Content
						class="z-50 w-48 rounded-lg border border-gray-200 bg-white p-1 shadow-lg dark:border-gray-700 dark:bg-gray-900"
						sideOffset={6}
					>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={toggle_bullet_list}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"
								/>
							</svg>
							Bullet List
						</Menubar.Item>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={toggle_ordered_list}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M3 4h0m0 0v1m0-1h0m1 0h13M4 12h0m0 0v1m0-1h0m1 0h13m-18 7h0m0 0v1m0-1h0m1 0h13"
								/>
							</svg>
							Numbered List
						</Menubar.Item>
					</Menubar.Content>
				</Menubar.Portal>
			</Menubar.Menu>

			<!-- Insert Menu -->
			<Menubar.Menu>
				<Menubar.Trigger
					class="inline-flex h-9 cursor-default items-center justify-center rounded-lg px-3 text-sm font-medium text-gray-600 transition-colors duration-200 hover:bg-gray-100 focus:outline-none data-[state=open]:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:data-[state=open]:bg-gray-700"
				>
					Insert
				</Menubar.Trigger>
				<Menubar.Portal>
					<Menubar.Content
						class="z-50 w-48 rounded-lg border border-gray-200 bg-white p-1 shadow-lg dark:border-gray-700 dark:bg-gray-900"
						sideOffset={6}
					>
						<Menubar.Item
							class="flex h-8 cursor-default items-center rounded-md px-2 py-1 text-sm text-gray-900 outline-none select-none hover:bg-gray-100 focus:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-700"
							onSelect={insert_horizontal_rule}
						>
							<svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M20 12H4"
								/>
							</svg>
							Horizontal Rule
						</Menubar.Item>
					</Menubar.Content>
				</Menubar.Portal>
			</Menubar.Menu>
		</Menubar.Root>
	</div>
{/if}

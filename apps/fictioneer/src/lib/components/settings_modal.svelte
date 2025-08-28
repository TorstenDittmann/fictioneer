<script lang="ts">
	import { Modal, Input, Label, Select, Button } from '$lib/components/ui';
	import type { AppSettings, EditorSettings } from '$lib/state/settings.svelte';
	import { settings_state } from '$lib/state/settings.svelte';
	import { Tabs } from 'bits-ui';
	import { onMount } from 'svelte';
	import { license_key_state } from '$lib/state/license_key.svelte';

	let { open = $bindable(false) }: { open: boolean } = $props();

	let tab = $state<'editor' | 'app' | 'license'>('editor');

	const st = $derived(settings_state.settings);

	const font_options = [
		{ label: 'Libre Baskerville (Serif)', value: 'Libre Baskerville, serif' },
		{ label: 'Georgia (Serif)', value: 'Georgia, serif' },
		{ label: 'Times New Roman (Serif)', value: '"Times New Roman", Times, serif' },
		{ label: 'Merriweather (Serif)', value: 'Merriweather, serif' },
		{ label: 'EB Garamond (Serif)', value: '"EB Garamond", serif' },
		{ label: 'Source Serif (Serif)', value: '"Source Serif Pro", serif' },
		{
			label: 'Inter (Sans)',
			value: 'Inter, system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif'
		},
		{
			label: 'System Sans',
			value: 'system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif'
		}
	] as const;

	let license_key_input = $state('');

	onMount(async () => {
		await license_key_state.initialize();
		license_key_input = license_key_state.license_key || '';
	});

	function set_editor(key: keyof EditorSettings, value: unknown) {
		switch (key) {
			case 'font_family':
				settings_state.set_editor({ font_family: String(value) });
				break;
			case 'font_size_px':
				settings_state.set_editor({ font_size_px: Number(value) });
				break;
			case 'line_height':
				settings_state.set_editor({ line_height: Number(value) });
				break;
			case 'page_margin_px':
				settings_state.set_editor({ page_margin_px: Number(value) });
				break;
			case 'spellcheck':
				settings_state.set_editor({
					spellcheck: Boolean((value as EventTarget & { checked?: boolean }).checked ?? value)
				});
				break;
		}
	}

	function set_app<K extends keyof AppSettings>(key: K, value: AppSettings[K]) {
		settings_state.update({ [key]: value } as Partial<AppSettings>);
	}
</script>

<Modal bind:open>
	<div class="space-y-4 p-2">
		<div class="flex items-center justify-between">
			<h2 class="text-lg font-semibold text-text">Settings</h2>
		</div>

		<Tabs.Root bind:value={tab} class="w-full">
			<Tabs.List class="inline-flex gap-1 rounded-lg border border-border bg-surface p-1">
				<Tabs.Trigger
					class="rounded-md px-3 py-1.5 text-xs font-medium text-text-secondary hover:bg-background-tertiary data-[state=active]:bg-background data-[state=active]:text-text data-[state=active]:ring-1 data-[state=active]:ring-accent"
					value="editor"
				>
					Editor
				</Tabs.Trigger>
				<Tabs.Trigger
					class="rounded-md px-3 py-1.5 text-xs font-medium text-text-secondary hover:bg-background-tertiary data-[state=active]:bg-background data-[state=active]:text-text data-[state=active]:ring-1 data-[state=active]:ring-accent"
					value="app"
				>
					App
				</Tabs.Trigger>
				<Tabs.Trigger
					class="rounded-md px-3 py-1.5 text-xs font-medium text-text-secondary hover:bg-background-tertiary data-[state=active]:bg-background data-[state=active]:text-text data-[state=active]:ring-1 data-[state=active]:ring-accent"
					value="license"
				>
					License
				</Tabs.Trigger>
			</Tabs.List>

			<div class="mt-3 h-[360px] overflow-auto pr-1">
				<Tabs.Content value="editor">
					<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
						<div class="flex flex-col gap-1">
							<Label for="font-family" class="text-sm font-medium text-text">Font Family</Label>
							<Select
								items={font_options.map((f) => ({ label: f.label, value: f.value }))}
								value={st.editor.font_family}
								onValueChange={(v) => set_editor('font_family', v)}
							/>
						</div>
						<div class="flex flex-col gap-1">
							<Label for="font-size" class="text-sm font-medium text-text">Font Size (px)</Label>
							<Input
								id="font-size"
								type="number"
								min="12"
								max="36"
								value={st.editor.font_size_px.toString()}
								oninput={(e) => set_editor('font_size_px', Number(e.currentTarget.value))}
							/>
						</div>
						<div class="flex flex-col gap-1">
							<Label for="line-height" class="text-sm font-medium text-text">Line Height</Label>
							<Input
								id="line-height"
								type="number"
								step="0.05"
								min="1"
								max="2.5"
								value={st.editor.line_height.toString()}
								oninput={(e) => set_editor('line_height', Number(e.currentTarget.value))}
							/>
						</div>
						<div class="flex flex-col gap-1">
							<Label for="margin" class="text-sm font-medium text-text">Page Margin (px)</Label>
							<Input
								id="margin"
								type="number"
								min="0"
								max="160"
								value={st.editor.page_margin_px.toString()}
								oninput={(e) => set_editor('page_margin_px', Number(e.currentTarget.value))}
							/>
						</div>
						<div class="sm:col-span-2">
							<label
								class="flex items-center gap-2 rounded-md border border-border bg-background p-3"
							>
								<input
									type="checkbox"
									checked={st.editor.spellcheck}
									onchange={(e) => set_editor('spellcheck', e.currentTarget.checked)}
								/>
								<span class="text-sm text-text">Enable system spellcheck</span>
							</label>
						</div>
					</div>
				</Tabs.Content>

				<Tabs.Content value="app">
					<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
						<div class="flex flex-col gap-1">
							<Label for="theme" class="text-sm font-medium text-text">Theme</Label>
							<Select
								items={[
									{ label: 'System', value: 'system' },
									{ label: 'Light', value: 'light' },
									{ label: 'Dark', value: 'dark' }
								]}
								value={st.theme}
								onValueChange={(v) => set_app('theme', v as AppSettings['theme'])}
							/>
						</div>
						<div class="flex flex-col gap-1">
							<Label for="autosave" class="text-sm font-medium text-text"
								>Autosave Interval (ms)</Label
							>
							<Input
								id="autosave"
								type="number"
								min="500"
								step="100"
								value={st.autosave_interval_ms.toString()}
								oninput={(e) => set_app('autosave_interval_ms', Number(e.currentTarget.value))}
							/>
						</div>
						<div class="flex flex-col gap-1 sm:col-span-2">
							<Label for="intelligence" class="text-sm font-medium text-text"
								>Intelligence Server URL (override)</Label
							>
							<Input
								id="intelligence"
								class="w-full"
								placeholder="Leave empty to use bundled server URL"
								value={st.intelligence_server_url || ''}
								oninput={(e) =>
									set_app(
										'intelligence_server_url',
										e.currentTarget.value ? e.currentTarget.value : null
									)}
							/>
							<p class="text-xs text-text-muted">Used for AI features and license verification.</p>
						</div>
					</div>
				</Tabs.Content>

				<Tabs.Content value="license">
					<div class="space-y-3">
						<div class="flex items-center justify-between">
							<Label for="license-key" class="text-sm font-medium text-text">AI License Key</Label>
							{#if license_key_state.is_verifying}
								<span class="text-xs text-text-secondary">Verifying…</span>
							{:else if license_key_state.verification_result}
								<span
									class="text-xs font-medium"
									style={license_key_state.is_valid ? 'color:#10b981' : 'color:#ef4444'}
								>
									{license_key_state.is_valid
										? 'Valid'
										: license_key_state.verification_result.error || 'Invalid'}
								</span>
							{/if}
						</div>
						<div class="flex gap-2">
							<Input
								id="license-key"
								class="flex-1"
								placeholder="Enter license key"
								value={license_key_input}
								oninput={(e) => (license_key_input = e.currentTarget.value)}
							/>
							<Button
								variant="primary"
								onclick={async () => {
									await license_key_state.set_license_key(license_key_input.trim() || null);
								}}
								disabled={license_key_state.is_verifying}>Verify</Button
							>
							{#if license_key_state.has_license_key}
								<Button
									variant="secondary"
									onclick={() => {
										license_key_state.remove_license_key();
										license_key_input = '';
									}}
									disabled={license_key_state.is_verifying}>Remove</Button
								>
							{/if}
						</div>
					</div>
				</Tabs.Content>
			</div>
		</Tabs.Root>

		<div class="mt-4 flex justify-end gap-2">
			<Button variant="secondary" onclick={() => (open = false)}>Close</Button>
		</div>
	</div>
</Modal>

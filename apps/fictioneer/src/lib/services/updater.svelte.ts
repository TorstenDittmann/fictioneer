import { check } from '@tauri-apps/plugin-updater';
import { relaunch } from '@tauri-apps/plugin-process';

export interface UpdateState {
	is_checking: boolean;
	is_downloading: boolean;
	is_installing: boolean;
	update_available: boolean;
	update_version?: string;
	update_body?: string;
	download_progress: number;
	download_total: number;
	error?: string;
}

class UpdaterService {
	private state_internal = $state<UpdateState>({
		is_checking: false,
		is_downloading: false,
		is_installing: false,
		update_available: false,
		download_progress: 0,
		download_total: 0
	});

	private check_interval: ReturnType<typeof setInterval> | null = null;

	get state(): UpdateState {
		return this.state_internal;
	}

	start_auto_check(): void {
		// Check immediately
		this.check_for_updates();

		// Then check every 10 minutes
		this.check_interval = setInterval(
			() => {
				this.check_for_updates();
			},
			10 * 60 * 1000
		);
	}

	stop_auto_check(): void {
		if (this.check_interval) {
			clearInterval(this.check_interval);
			this.check_interval = null;
		}
	}

	async check_for_updates(): Promise<boolean> {
		if (this.state_internal.is_checking) {
			return false;
		}

		this.state_internal.is_checking = true;
		this.state_internal.error = undefined;

		try {
			const update = await check();

			if (update) {
				this.state_internal.update_available = true;
				this.state_internal.update_version = update.version;
				this.state_internal.update_body = update.body;
				console.log(
					`Found update ${update.version} from ${update.date} with notes: ${update.body}`
				);
				return true;
			} else {
				this.state_internal.update_available = false;
				return false;
			}
		} catch (error) {
			console.error('Failed to check for updates:', error);
			this.state_internal.error = error instanceof Error ? error.message : 'Unknown error occurred';
			return false;
		} finally {
			this.state_internal.is_checking = false;
		}
	}

	async download_and_install_update(): Promise<boolean> {
		if (!this.state_internal.update_available || this.state_internal.is_downloading) {
			return false;
		}

		this.state_internal.is_downloading = true;
		this.state_internal.error = undefined;
		this.state_internal.download_progress = 0;
		this.state_internal.download_total = 0;

		try {
			const update = await check();

			if (!update) {
				throw new Error('No update available');
			}

			await update.downloadAndInstall((event) => {
				switch (event.event) {
					case 'Started':
						this.state_internal.download_total = event.data.contentLength ?? 0;
						console.log(`Started downloading ${event.data.contentLength ?? 0} bytes`);
						break;
					case 'Progress':
						this.state_internal.download_progress += event.data.chunkLength;
						console.log(
							`Downloaded ${this.state_internal.download_progress} from ${this.state_internal.download_total}`
						);
						break;
					case 'Finished':
						console.log('Download finished');
						this.state_internal.is_downloading = false;
						this.state_internal.is_installing = true;
						break;
				}
			});

			console.log('Update installed successfully');

			// Relaunch the application
			await relaunch();

			return true;
		} catch (error) {
			console.error('Failed to download and install update:', error);
			this.state_internal.error = error instanceof Error ? error.message : 'Unknown error occurred';
			return false;
		} finally {
			this.state_internal.is_downloading = false;
			this.state_internal.is_installing = false;
		}
	}

	get_download_percentage(): number {
		if (this.state_internal.download_total === 0) {
			return 0;
		}
		return Math.round(
			(this.state_internal.download_progress / this.state_internal.download_total) * 100
		);
	}

	reset_state(): void {
		this.state_internal.update_available = false;
		this.state_internal.update_version = undefined;
		this.state_internal.update_body = undefined;
		this.state_internal.download_progress = 0;
		this.state_internal.download_total = 0;
		this.state_internal.error = undefined;
	}

	destroy(): void {
		this.stop_auto_check();
	}
}

export const updater_service = new UpdaterService();

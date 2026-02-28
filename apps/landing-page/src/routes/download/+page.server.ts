import type { PageServerLoad } from './$types';

type Platform = {
	signature: string;
	url: string;
};

type ReleaseData = {
	version: string;
	notes: string;
	pub_date: string;
	platforms: Record<string, Platform>;
};

export type DownloadOption = {
	platform: 'windows' | 'mac' | 'linux';
	name: string;
	description: string;
	versions: {
		arch: string;
		url: string;
	}[];
};

type DetectedPlatform = 'windows' | 'mac' | 'linux' | null;

function detect_platform_from_user_agent(user_agent: string): DetectedPlatform {
	const ua_lower = user_agent.toLowerCase();

	if (ua_lower.includes('mac') || ua_lower.includes('darwin')) {
		return 'mac';
	}
	if (ua_lower.includes('win')) {
		return 'windows';
	}
	if (ua_lower.includes('linux') || ua_lower.includes('x11')) {
		return 'linux';
	}

	return null;
}

export const load: PageServerLoad = async ({ fetch, request }) => {
	const response = await fetch(
		'https://github.com/TorstenDittmann/fictioneer/releases/latest/download/latest.json'
	);

	if (!response.ok) {
		throw new Error(`Failed to fetch release data: ${response.statusText}`);
	}

	const release_data: ReleaseData = await response.json();
	const release_version = release_data.version;
	const release_tag = `app-v${release_version}`;
	const release_base_url = `https://github.com/TorstenDittmann/fictioneer/releases/download/${release_tag}`;

	function build_asset_url(asset_name: string): string {
		return `${release_base_url}/${asset_name}`;
	}

	const download_options: DownloadOption[] = [
		{
			platform: 'mac',
			name: 'macOS',
			description: `Version ${release_version}`,
			versions: [
				{
					arch: 'Apple Silicon (M1/M2/M3)',
					url: build_asset_url(`Fictioneer_${release_version}_aarch64.dmg`)
				},
				{
					arch: 'Intel',
					url: build_asset_url(`Fictioneer_${release_version}_x64.dmg`)
				}
			]
		},
		{
			platform: 'windows',
			name: 'Windows',
			description: `Version ${release_version}`,
			versions: [
				{
					arch: 'Installer (MSI)',
					url: build_asset_url(`Fictioneer_${release_version}_x64_en-US.msi`)
				},
				{
					arch: 'Setup (NSIS)',
					url: build_asset_url(`Fictioneer_${release_version}_x64-setup.exe`)
				}
			]
		},
		{
			platform: 'linux',
			name: 'Linux',
			description: `Version ${release_version}`,
			versions: [
				{
					arch: 'AppImage (x64)',
					url: build_asset_url(`Fictioneer_${release_version}_amd64.AppImage`)
				},
				{
					arch: 'Debian/Ubuntu (.deb)',
					url: build_asset_url(`Fictioneer_${release_version}_amd64.deb`)
				},
				{
					arch: 'Red Hat/Fedora (.rpm)',
					url: build_asset_url(`Fictioneer-${release_version}-1.x86_64.rpm`)
				}
			]
		}
	];

	const user_agent = request.headers.get('user-agent') || '';
	const detected_platform = detect_platform_from_user_agent(user_agent);

	return {
		download_options,
		version: release_version,
		release_notes: release_data.notes,
		pub_date: release_data.pub_date,
		detected_platform
	};
};

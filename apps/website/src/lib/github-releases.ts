import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export interface ReleaseAsset {
  name: string;
  downloadUrl: string;
  sizeBytes: number;
  sizeFormatted: string;
  platform: 'windows' | 'linux' | 'android' | 'other';
  type: string;
}

export interface ReleaseInfo {
  version: string;
  tagName: string;
  name: string;
  publishedAt: string;
  htmlUrl: string;
  notes: string;
  assets: ReleaseAsset[];
  downloads: {
    windowsInstaller?: string;
    windowsPortable?: string;
    linuxDeb?: string;
    linuxAppImage?: string;
    androidApk?: string;
  };
}

export function resolveLocalAppVersion(): string {
  try {
    const candidates = [
      fileURLToPath(new URL('../../../shellit/pubspec.yaml', import.meta.url)),
      path.resolve(process.cwd(), '../shellit/pubspec.yaml'),
      path.resolve(process.cwd(), '../../apps/shellit/pubspec.yaml'),
    ];
    for (const p of candidates) {
      if (fs.existsSync(p)) {
        const content = fs.readFileSync(p, 'utf-8');
        const m = content.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)/m);
        if (m) return `v${m[1]}`;
      }
    }
  } catch {}
  return 'v0.8.5';
}

export function createFallbackRelease(tag: string = resolveLocalAppVersion()): ReleaseInfo {
  const versionTag = tag.startsWith('v') ? tag : `v${tag}`;
  return {
    version: versionTag,
    tagName: versionTag,
    name: `Shellit ${versionTag} Alpha Preview`,
    publishedAt: new Date().toISOString(),
    htmlUrl: 'https://github.com/kobaltgit/Shellit/releases',
    notes: `Alpha / Developer Preview with hardened Zero-Trust architecture, Fail-Closed SSH TOFU, byte-level memory zeroization, and sandboxed Plugin SDK.`,
    assets: [],
    downloads: {
      windowsInstaller: `https://github.com/kobaltgit/Shellit/releases/download/${versionTag}/Shellit-Setup-x64-${versionTag}.exe`,
      windowsPortable: `https://github.com/kobaltgit/Shellit/releases/download/${versionTag}/Shellit-Windows-x64-${versionTag}.zip`,
      linuxDeb: `https://github.com/kobaltgit/Shellit/releases`,
      linuxAppImage: `https://github.com/kobaltgit/Shellit/releases/download/${versionTag}/Shellit-Linux-x64-${versionTag}.tar.gz`,
      androidApk: `https://github.com/kobaltgit/Shellit/releases/download/${versionTag}/Shellit-Android-${versionTag}.apk`,
    },
  };
}

const FALLBACK_RELEASE: ReleaseInfo = createFallbackRelease();

function formatBytes(bytes: number, decimals = 1): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
}

let cachedRelease: ReleaseInfo | null = null;
let lastFetchTime = 0;
const CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes cache

export async function getLatestRelease(): Promise<ReleaseInfo> {
  const now = Date.now();
  if (cachedRelease && (now - lastFetchTime < CACHE_TTL_MS)) {
    return cachedRelease;
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 4000);

    // Note: /releases/latest only returns full (non-prerelease) releases.
    // Query /releases?per_page=1 to support pre-releases (such as automated CI releases).
    const res = await fetch('https://api.github.com/repos/kobaltgit/Shellit/releases?per_page=1', {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Shellit-Website-Sync/1.0',
      },
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (!res.ok) {
      return cachedRelease || FALLBACK_RELEASE;
    }

    const releasesList = await res.json();
    if (!Array.isArray(releasesList) || releasesList.length === 0) {
      return cachedRelease || FALLBACK_RELEASE;
    }

    const data = releasesList[0];
    const assets: ReleaseAsset[] = Array.isArray(data.assets)
      ? data.assets.map((a: any) => {
          const name = String(a.name || '');
          let platform: ReleaseAsset['platform'] = 'other';
          if (name.endsWith('.exe') || name.endsWith('.msi') || (name.includes('windows') && name.endsWith('.zip'))) {
            platform = 'windows';
          } else if (name.endsWith('.deb') || name.endsWith('.AppImage') || name.endsWith('.tar.gz')) {
            platform = 'linux';
          } else if (name.endsWith('.apk')) {
            platform = 'android';
          }

          return {
            name,
            downloadUrl: a.browser_download_url || data.html_url,
            sizeBytes: Number(a.size) || 0,
            sizeFormatted: formatBytes(Number(a.size) || 0),
            platform,
            type: name.split('.').pop() || '',
          };
        })
      : [];

    const downloads = {
      windowsInstaller: assets.find(a => a.name.endsWith('.exe') || a.name.endsWith('.msi'))?.downloadUrl || data.html_url,
      windowsPortable: assets.find(a => a.name.includes('portable') || (a.name.includes('win') && a.name.endsWith('.zip')))?.downloadUrl || data.html_url,
      linuxDeb: assets.find(a => a.name.endsWith('.deb'))?.downloadUrl || data.html_url,
      linuxAppImage: assets.find(a => a.name.endsWith('.AppImage') || a.name.endsWith('.tar.gz'))?.downloadUrl || data.html_url,
      androidApk: assets.find(a => a.name.endsWith('.apk'))?.downloadUrl || data.html_url,
    };

    cachedRelease = {
      version: data.tag_name || resolveLocalAppVersion(),
      tagName: data.tag_name || resolveLocalAppVersion(),
      name: data.name || data.tag_name || 'Shellit Release',
      publishedAt: data.published_at || new Date().toISOString(),
      htmlUrl: data.html_url || 'https://github.com/kobaltgit/Shellit/releases',
      notes: data.body || '',
      assets,
      downloads,
    };
    lastFetchTime = now;

    return cachedRelease;
  } catch (err) {
    return cachedRelease || FALLBACK_RELEASE;
  }
}

let cachedStars: number | null = null;
let lastStarsFetchTime = 0;

export async function getRepoStars(): Promise<number> {
  const now = Date.now();
  if (cachedStars !== null && (now - lastStarsFetchTime < CACHE_TTL_MS)) {
    return cachedStars;
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 4000);
    const res = await fetch('https://api.github.com/repos/kobaltgit/Shellit', {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Shellit-Website-Sync/1.0',
      },
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (res.ok) {
      const data = await res.json();
      if (typeof data.stargazers_count === 'number') {
        cachedStars = data.stargazers_count;
        lastStarsFetchTime = now;
        return cachedStars;
      }
    }
  } catch (err) {
    // Return cached or fallback
  }
  return cachedStars ?? 0;
}

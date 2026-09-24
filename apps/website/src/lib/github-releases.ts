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

const FALLBACK_RELEASE: ReleaseInfo = {
  version: 'v0.8.3',
  tagName: 'v0.8.3',
  name: 'Shellit v0.8.3 Release',
  publishedAt: '2026-09-22T03:17:02Z',
  htmlUrl: 'https://github.com/kobaltgit/Shellit/releases',
  notes: 'Production release with 2x2 matrix tiling, Prod Guard, AI Gemini assistant, and Zero-Knowledge Vault.',
  assets: [],
  downloads: {
    windowsInstaller: 'https://github.com/kobaltgit/Shellit/releases/download/v0.8.3/Shellit-Setup-x64-v0.8.3.exe',
    windowsPortable: 'https://github.com/kobaltgit/Shellit/releases/download/v0.8.3/Shellit-Windows-x64-v0.8.3.zip',
    linuxDeb: 'https://github.com/kobaltgit/Shellit/releases',
    linuxAppImage: 'https://github.com/kobaltgit/Shellit/releases/download/v0.8.3/Shellit-Linux-x64-v0.8.3.tar.gz',
    androidApk: 'https://github.com/kobaltgit/Shellit/releases/download/v0.8.3/Shellit-Android-v0.8.3.apk',
  },
};

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
      version: data.tag_name || 'v0.8.3',
      tagName: data.tag_name || 'v0.8.3',
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

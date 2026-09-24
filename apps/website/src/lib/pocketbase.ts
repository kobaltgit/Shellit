import PocketBase from 'pocketbase';
import rawRoadmap from '../../../../docs/roadmap.data.json';

const POCKETBASE_DEFAULT_URL = (import.meta.env.PUBLIC_POCKETBASE_URL as string) || '';

// Global client instance
let pbInstance: PocketBase | null = null;

export function getPocketBaseClient(): PocketBase {
  if (!pbInstance) {
    const url = typeof window !== 'undefined'
      ? ((window as any).__PUBLIC_POCKETBASE_URL__ !== undefined ? (window as any).__PUBLIC_POCKETBASE_URL__ : window.location.origin)
      : (import.meta.env.PUBLIC_POCKETBASE_URL || 'http://127.0.0.1:8095');
    pbInstance = new PocketBase(url || '/');
  }
  return pbInstance;
}

export interface LiveRoadmapRecord {
  id: string;
  feature_id: string;
  title_en: string;
  title_ru: string;
  desc_en: string;
  desc_ru: string;
  status: 'shipped' | 'in-progress' | 'planned';
  tag: string;
  votes: number;
  order: number;
}

/**
 * Fetch live roadmap items from PocketBase with graceful fallback to SSOT docs/roadmap.data.json
 */
export async function getLiveRoadmapItems(): Promise<LiveRoadmapRecord[]> {
  try {
    const pb = getPocketBaseClient();
    const records = await pb.collection('roadmap_items').getFullList<LiveRoadmapRecord>({
      sort: '+order',
      requestKey: null,
    });

    if (records && records.length > 0) {
      return records;
    }
  } catch (err) {
    // PocketBase is offline or unreachable - use SSOT fallback
  }

  // Fallback to docs/roadmap.data.json
  return rawRoadmap.items.map((it: any) => ({
    id: it.id,
    feature_id: it.id,
    title_en: it.title.en,
    title_ru: it.title.ru,
    desc_en: it.desc.en,
    desc_ru: it.desc.ru,
    status: it.status as 'shipped' | 'in-progress' | 'planned',
    tag: it.tag,
    votes: it.votes || 0,
    order: it.order || 999,
  }));
}

/**
 * Upvote a roadmap feature in PocketBase
 */
export async function upvoteRoadmapItem(recordId: string): Promise<number | null> {
  try {
    const pb = getPocketBaseClient();
    // Using atomic increment
    const updated = await pb.collection('roadmap_items').update<LiveRoadmapRecord>(recordId, {
      'votes+': 1,
    });
    return updated.votes;
  } catch (err) {
    console.warn('Failed to upvote in PocketBase:', err);
    return null;
  }
}

/**
 * Submit user feedback or bug report to PocketBase
 */
export async function submitFeedback(payload: {
  email?: string;
  subject: string;
  message: string;
  category?: 'feature_request' | 'bug_report' | 'general';
}): Promise<boolean> {
  try {
    const pb = getPocketBaseClient();
    await pb.collection('feedback_reports').create({
      ...payload,
      status: 'new',
    });
    return true;
  } catch (err) {
    console.error('Failed to submit feedback to PocketBase:', err);
    return false;
  }
}

/**
 * Fetch approved plugins from PocketBase
 */
export async function getApprovedPlugins(): Promise<any[]> {
  try {
    const pb = getPocketBaseClient();
    const records = await pb.collection('plugins').getFullList({
      filter: "status = 'published'",
      sort: '-downloads',
      requestKey: null,
    });
    return records;
  } catch (err) {
    return [];
  }
}

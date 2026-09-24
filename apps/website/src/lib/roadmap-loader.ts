import type { Locale } from '../i18n/translations';
import rawRoadmap from '../../../../docs/roadmap.data.json';

export interface LocalizedRoadmapItem {
  id: string;
  title: string;
  desc: string;
  tag: string;
  status: 'shipped' | 'in-progress' | 'planned';
  votes: number;
  order: number;
}

export interface LocalizedRoadmapColumn {
  status: 'shipped' | 'in-progress' | 'planned';
  statusTitle: string;
  badgeColor: 'green' | 'yellow' | 'blue';
  items: LocalizedRoadmapItem[];
}

export function getRoadmapColumns(lang: Locale = 'en'): LocalizedRoadmapColumn[] {
  const items: LocalizedRoadmapItem[] = rawRoadmap.items.map((it: any) => ({
    id: it.id,
    title: it.title[lang] || it.title.en,
    desc: it.desc[lang] || it.desc.en,
    tag: it.tag,
    status: it.status as 'shipped' | 'in-progress' | 'planned',
    votes: it.votes || 0,
    order: it.order || 999,
  }));

  // Sort by order ascending
  items.sort((a, b) => a.order - b.order);

  return rawRoadmap.columns.map((col: any) => ({
    status: col.status as 'shipped' | 'in-progress' | 'planned',
    statusTitle: col.title[lang] || col.title.en,
    badgeColor: col.badgeColor as 'green' | 'yellow' | 'blue',
    items: items.filter(it => it.status === col.status),
  }));
}

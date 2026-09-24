/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        obsidian: {
          bg: '#0D0F12',
          card: '#14171E',
          surface: '#1A1F29',
          border: '#1E2430',
          'border-hover': '#2E3747',
        },
        cyber: {
          cyan: '#7BE113', // Authentic Electric Lime from Shellit Logo
          lime: '#8AEB1A',
          'lime-dark': '#5FB300',
          purple: '#A855F7',
          red: '#EF4444',
          amber: '#F59E0B',
          blue: '#3B82F6',
          green: '#10B981',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'monospace'],
      },
      boxShadow: {
        'glow-cyan': '0 0 25px -4px rgba(123, 225, 19, 0.38)',
        'glow-lime': '0 0 25px -4px rgba(138, 235, 26, 0.45)',
        'glow-purple': '0 0 25px -5px rgba(168, 85, 247, 0.3)',
        'glow-red': '0 0 25px -5px rgba(239, 68, 68, 0.3)',
      },
      animation: {
        'pulse-subtle': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      }
    },
  },
  plugins: [],
};

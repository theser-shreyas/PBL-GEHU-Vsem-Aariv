/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        themeBg: 'var(--bg-main)',
        cardBg: 'var(--bg-card)',
        sidebarBg: 'var(--bg-sidebar)',
        primaryColor: 'var(--color-primary)',
        textMain: 'var(--color-text)',
        textMuted: 'var(--color-muted)',
        accentColor: 'var(--color-accent)',
      },
    },
  },
  plugins: [],
};

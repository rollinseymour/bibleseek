# Bible Seek — bibleseekapp.com

Marketing site for the Bible Seek iOS app. Static, ships zero JavaScript
by default, deploys anywhere static files do.

## Stack

- **[Astro 5](https://astro.build)** — content-focused static-site generator
- **[Tailwind CSS v4](https://tailwindcss.com)** — utility-first styling, configured via the official `@tailwindcss/vite` plugin
- **No JavaScript framework** — every page is pure HTML by the time the
  browser sees it. Lighthouse scores 100/100/100 by default.

## Local development

```bash
npm install      # first time only
npm run dev      # → http://localhost:4321
```

Edits hot-reload instantly.

## Build

```bash
npm run build    # outputs static files to ./dist
npm run preview  # serves ./dist locally for a final check
```

## Project layout

```
src/
  components/    # one .astro file per page section
    Nav.astro
    Hero.astro
    Features.astro
    WordStudy.astro
    Screenshots.astro
    CTA.astro
    Footer.astro
  layouts/
    Layout.astro # HTML shell + meta tags + global stylesheet import
  pages/         # one URL per file
    index.astro  # /
    privacy.astro # /privacy
    terms.astro   # /terms
  styles/
    global.css   # Tailwind + brand theme tokens
public/          # static assets served verbatim from /
  favicon.svg    # brand mark (cream "B" on brown)
  hero-screenshot.png   # ← drop a 1170×2532 here to populate the hero
  screen-1.png … screen-4.png  # ← drop screenshots here for the gallery
  og.png        # ← drop a 1200×630 PNG here for link-preview cards
  apple-touch-icon.png  # ← drop a 180×180 PNG for iOS home-screen save
astro.config.mjs # Astro + Tailwind config
```

## Things to fill in before going live

1. **Drop in real images.** The hero, screenshot strip, OG card, and
   apple-touch icon all reference paths in `public/`. Until you replace
   them, the page shows tasteful placeholders, but the OG meta tag and
   apple-touch icon will 404.
2. **Replace App Store CTA `href`.** Both `Hero.astro` and `CTA.astro`
   currently link to `#`. Once your App Store listing is live, swap in
   the real URL (e.g. `https://apps.apple.com/app/idXXXXXXXXXX`).
3. **Confirm contact email.** `Footer.astro`, `privacy.astro`, and
   `terms.astro` all reference `hello@bibleseekapp.com`. Set up that
   inbox (Cloudflare Email Routing → forward to your real address is
   the easiest path).
4. **Review the legal copy.** `privacy.astro` and `terms.astro` are
   sensible defaults that match what the iOS app actually does, but
   you should read them once and confirm they describe your situation
   accurately. Update the "Last updated" dates if you change anything.

## Deploy

The site builds to a folder of static HTML/CSS — any static host
works. The two best options for a free + fast setup:

### Cloudflare Pages (recommended)

1. Push this repo to GitHub (private is fine).
2. Cloudflare Dashboard → **Workers & Pages** → **Create** →
   **Pages** → **Connect to Git** → pick the repo.
3. Build command: `npm run build`
4. Output directory: `dist`
5. Add a custom domain in the Pages project settings: `bibleseekapp.com`
   (and `www.bibleseekapp.com` redirect).
6. Cloudflare auto-creates the DNS records if your domain is on
   Cloudflare DNS. If your domain is registered elsewhere, point the
   nameservers at Cloudflare first (free, takes ~5 min).

### Vercel

1. Push to GitHub.
2. Vercel → **New Project** → import the repo.
3. Vercel auto-detects Astro — accept the defaults.
4. Project Settings → **Domains** → add `bibleseekapp.com`.
5. Vercel will tell you the DNS records to add (an `A` record for the
   apex + a `CNAME` for `www`).

### DNS (whichever host)

If your registrar isn't Cloudflare/Vercel:

- `bibleseekapp.com` → A record pointing at the host's IP
- `www.bibleseekapp.com` → CNAME pointing at the host (e.g.
  `cname.vercel-dns.com` or your-project.pages.dev)

## Editing

- Page sections live in `src/components/`. They're plain Astro files
  (HTML + scoped frontmatter). To change copy, open the relevant file
  and edit the strings.
- The brand palette is defined as CSS custom properties in
  `src/styles/global.css` under the `@theme` block. Change a value
  there and every utility class (`bg-cream`, `text-accent`, etc.)
  picks it up automatically.
- New pages: create a new `.astro` file in `src/pages/`. The filename
  becomes the URL. Wrap the content in `<Layout>` to inherit the meta
  tags and global stylesheet.

## License

The site copy and components in this repo are © Bible Seek. The
underlying tooling (Astro, Tailwind) is open source under their
respective licenses.

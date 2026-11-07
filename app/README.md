# Bible Seek web reader

The Bible Seek reader for browsers, served at https://bibleseekapp.com/read/.
A Flutter web app that mirrors the iOS app's features and stores everything in
the browser under the iOS app's keys, so backups move between the two.

## Run locally

```sh
flutter build web --release --base-href /read/
mkdir -p build/site && ln -sfn ../web build/site/read
python3 -m http.server 8686 --directory build/site   # http://localhost:8686/read/
```

## Bible text

`web/content/` is generated from the iOS app's bundled JSON and committed, so the
deploy doesn't need the source assets:

```sh
dart run tool/pack_content.dart /path/to/bibleseek/lib/assets
```

## Deploy

`.github/workflows/deploy.yml` builds the Astro site, builds this app with
`--base-href /read/`, copies it into `dist/read/`, and publishes both to GitHub Pages.

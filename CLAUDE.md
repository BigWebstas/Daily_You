# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Flutter journaling app (mood tracking, daily logs, photo memories, Markdown notes).
This repo is a **fork of Demizo/Daily_You** that adds desktop packaging the
upstream project does not ship: Windows installer (Inno Setup), Linux AppImage,
macOS package, plus AUR, Flatpak, Chocolatey, and Snap distribution. Upstream
is merged in periodically (`Merge branch 'Demizo:master'`). Keep app-logic
changes upstreamable; keep packaging changes local to this fork.

## Commands

```bash
flutter pub get                 # restore deps (also fetches shared_storage from git)
flutter run                     # run on attached device / desktop
flutter analyze                 # lint (uses flutter_lints via analysis_options.yaml)
flutter gen-l10n                # regenerate localizations after editing lib/l10n/*.arb

# Android: two flavors, "independent" (signed, self-distributed) and "fdroid"
flutter build apk --flavor independent --release --split-per-abi
flutter build appbundle --flavor independent --release

# Desktop
flutter build windows --release   # then: iscc windows/installer/daily_you.iss
flutter build linux --release     # AppImage via AppImageBuilder.yml
flutter build macos --release
```

There is **no `test/` directory** — the project has no automated test suite.

Local Android builds use a Nix dev shell (`flake.nix`) that pins the Android
SDK/NDK; `nix develop` (or direnv via `.envrc`) provides the toolchain.
`build_release.sh` and `prepare_release.sh` are the upstream maintainer's
release scripts and contain hardcoded paths (`/home/demizo/...`) — not for use
here. Releases in this fork run through `.github/workflows/release.yml`
(triggered by a `v*.*.*` tag or manual dispatch), which builds Windows, Linux
AppImage, and macOS artifacts, then packages AUR, Flatpak, Chocolatey, and
Snap from the published release. `build-flatpak`/`build-snap` run after
`release` (they fetch the just-published GitHub Release), while
`build-arch-pkg` runs alongside it. `push-choco` is split from `build-choco`
so a Chocolatey moderation rejection can't block the rest.

The `submodules/flutter` submodule pins a Flutter SDK checkout; it is empty
unless initialized with `git submodule update --init`.

## Architecture

**State** — `provider` package. `ConfigProvider` (`lib/config_provider.dart`) is
the central settings/config store, loaded before `runApp`. Per-domain providers
in `lib/providers/` (`entries_provider`, `tags_provider`, `templates_provider`,
`entry_images_provider`) wrap the DAO layer and notify the UI.

**Persistence** — SQLite via `sqflite` (mobile) / `sqflite_common_ffi` (desktop).
`lib/database/app_database.dart` owns schema + migrations; one DAO per table in
`lib/database/*_dao.dart`. Images are stored as files, not blobs —
`image_storage.dart` and `lib/utils/file_layer.dart` abstract over local storage
vs. Android Storage Access Framework (SAF, `saf_util` / `shared_storage`), which
is how "choose where your data lives / external storage" works. `saf_transfer.dart`
moves the DB + image folder between locations.

**Import/export** — `lib/utils/imports/` has one importer per competing app
(Daylio, Diarium, Diaro, Pixels, One Shot, Day book, My Brain, plain JSON), all
implementing the `ImportFormat` interface in `import_format.dart`. Export/backup
lives in `backup_restore_utils.dart`, `export_utils.dart`, `zip_utils.dart`.

**Localization** — `lib/l10n/intl_*.arb` (~35 languages, Weblate-managed),
generated to Dart by `flutter gen-l10n` per `l10n.yaml`. Custom locale fallback
logic in `lib/custom_locale_delegates.dart` and `lib/language_option.dart`.

**Notifications / reminders** — `lib/notification_manager.dart` plus
`android_alarm_manager_plus` for the "random daily nudge" scheduling.
`flashback_manager.dart` surfaces past entries ("on this day").

**UI** — `lib/pages/` (screens) and `lib/widgets/` (shared components).
`lib/layouts/responsive_layout.dart` switches phone/tablet/desktop layouts.
`main.dart` wires up providers, theme (`theme_mode_provider.dart`), and routing.

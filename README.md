# JARVIS — Bengali voice assistant for Android

A voice-first Android assistant inspired by ChatGPT and JARVIS. It talks in natural Bengali, can be woken
hands-free with "Hey JARVIS", automates common phone tasks through official Android APIs, and keeps an optional,
private memory with reminders and daily summaries.

Stack: Kotlin, Jetpack Compose, Material 3, Room, WorkManager, OkHttp, kotlinx.serialization.
Minimum Android 8.0 (API 26). Target and compile SDK 34.

> **Build status:** the project was written and statically checked (resource references, XML validity, unit tests
> written) but **not compiled** in the environment that produced it, because that environment had no Android SDK
> or network. The first build on your side or in CI is the first real compile. If it fails, send the log and the
> errors will be fixed.

## What it does

* **Bengali voice conversation:** speech recognition in `bn-BD`, speech output in Bengali (`bn-BD`, `bn-IN`, then `bn`).
* **Hey JARVIS wake word:** foreground microphone service, see `docs/DOCOMO.md` for Android and Docomo notes.
* **Phone automation (official APIs only):** flashlight, alarms, timers, dialer, open apps, notes, timed reminders,
  notification summary. Commands are matched offline first (Bengali and English), then handed to the AI.
* **Notification summaries:** local counts by default. Sending notification text to the AI is a separate opt-in.
* **Personal memory:** notes, conversation log, daily summary at 21:00, 30-day retention for logs, per-item delete,
  and a "delete all data" button.
* **Secure AI backend:** the app never contains an AI provider key (see below).
* **Permissions in Bengali:** every permission has a Bengali explanation shown before the system dialog.

## Setup

### 1. Deploy the AI proxy (holds the API key)

Requires Node.js and a free Cloudflare account.

```bash
cd backend
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY   # your provider key, stays on the server
npx wrangler secret put APP_TOKEN           # a long random string you invent; the app sends it
npx wrangler deploy
```

Wrangler prints a URL such as `https://jarvis-proxy.<your-subdomain>.workers.dev`. Add a Cloudflare rate-limiting
rule on that route to cap abuse. The model name is the `MODEL` variable in `backend/wrangler.toml`.

### 2. Get the APK

**Option A, Android Studio (Koala or newer, JDK 17):** open the `JarvisAssistant` folder, let Gradle sync, then
*Build → Build APK(s)*. The APK appears in `app/build/outputs/apk/debug/`.
If Studio does not generate the Gradle wrapper on its own, run `scripts/bootstrap_wrapper.sh` once.

**Option B, GitHub Actions:** push this folder to a GitHub repository. The workflow in `.github/workflows/android.yml`
runs unit tests, lint and `assembleDebug`, and uploads `jarvis-debug-apk` as a downloadable artifact.

**Option C, command line:** with JDK 17 and the Android SDK installed, run `scripts/verify.sh`.

### 3. First run on the phone

1. Install the APK (allow installs from your file manager or browser when asked).
2. Open **সেটিংস** (Settings), enter the proxy URL and `APP_TOKEN`, then **সংরক্ষণ** (Save).
3. Grant microphone and notification permissions from the same screen.
4. If a banner says the Bengali voice is missing, tap **বাংলা ভয়েস ইনস্টল করুন** and install the voice data
   (this uses the phone's text-to-speech engine, usually Google's).
5. Tap the orb and speak. Try "ফ্ল্যাশলাইট জ্বালাও", "সকাল ৭টায় অ্যালার্ম সেট করো", "১০ মিনিট পরে মনে করিয়ে দাও চা খেতে".
6. Optional: turn on **হেই জার্ভিস**, then lock the phone and say "Hey JARVIS".
   On Docomo and other carrier-customised phones also set battery to Unrestricted (see `docs/DOCOMO.md`).

## Security and privacy design

* No AI key in the app, in `BuildConfig`, or in the repository. Only the proxy URL and your own access token are
  stored on the phone, and the token is encrypted with an AES-GCM key held in the Android Keystore.
* HTTPS is enforced; cleartext traffic is disabled; backups are disabled (`allowBackup=false`).
* Conversation history sent to the AI lives in RAM only. The memory database is local to the app.
* Saved notes are inserted into the AI prompt as data, with an instruction not to follow them as commands.
* The AI can only trigger a fixed list of actions (see `ActionParser`); everything else is ignored.
* Notification collection, sending notification text to the AI, logging and daily summaries are separate toggles.

## Architecture

Single Gradle module `:app` with layered packages, wired by a small manual container (`core/AppContainer`):

| Package | Responsibility |
|---|---|
| `domain` | `IntentRouter` (offline command routing), `ActionParser`, `SystemPrompt`, `AssistantEngine` |
| `data` | AI backend client, Room database, settings |
| `voice` | speech recognition, Bengali TTS, wake word engine interface, turn orchestration |
| `automation` | action executor, reminders, notification helpers |
| `service` | wake word foreground service, notification listener |
| `work` | daily summary worker |
| `ui` | Compose screens (Home, Memory, Settings), Material 3 theme |

The packages are already separated so `domain` and `data` can be moved into their own Gradle modules later.

## Testing and automation

* JVM unit tests cover command routing, AI action parsing and wake phrase matching: `gradle testDebugUnitTest`.
* CI runs tests, lint and the debug build on every push and publishes test reports and the APK.
* Instrumented tests for the voice and permission flows are not included, because they need a physical device.

## Limitations

* The wake word engine is speech-recognizer based (no key, higher battery use). See `docs/DOCOMO.md` for how to
  swap in a dedicated keyword spotter through the `WakeWordEngine` interface.
* Bengali recognition and speech quality depend on the phone's speech services.
* Android blocks background activity launches, so alarms, timers and the dialer need the app visible; otherwise
  the assistant posts a tap-to-complete notification.
* Reminders use inexact alarms, so they can fire a little late under battery restrictions.
* The release build has minification off until tested on a device; sign it with your own keystore for distribution.
* UI strings are Bengali only. Source code, identifiers, comments and project files are English.

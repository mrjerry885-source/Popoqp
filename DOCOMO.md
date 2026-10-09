# Background listening on Japanese Docomo Android devices

## Summary

"Docomo" is a carrier, not a hardware maker. Docomo-branded phones are made by Sony (Xperia), Sharp (AQUOS),
Samsung (Galaxy), Google (Pixel) and others, usually with a carrier-customised build of Android. So the practical
behaviour depends on the manufacturer layer, not on Docomo itself. This project could not be tested on a physical
Docomo handset, so treat the notes below as an informed checklist, not as verified results.

## What Android itself allows (all devices, official behaviour)

| Android version | What matters for a background microphone |
|---|---|
| 8–9 | Background services are restricted; a foreground service with a visible notification is required. |
| 10 | Apps cannot start activities from the background; background mic capture is silenced unless a foreground service is running. |
| 11 | Mic access from a foreground service needs the `microphone` service type to be declared. |
| 12 | A foreground service cannot be started from the background (e.g. from boot or a broadcast). |
| 14 | Foreground services must declare a type and hold the matching `FOREGROUND_SERVICE_MICROPHONE` permission; `RECORD_AUDIO` must already be granted when the service starts. |

How the app complies:

* `WakeWordService` is a foreground service of type `microphone`, with a persistent notification and a Stop action.
* It is started only from the visible UI (the wake word switch), never from boot or a background receiver.
* `BootReceiver` only re-arms reminders. It never starts the microphone.
* Anything that needs a screen (alarm, timer, dialer, opening an app) is launched directly only when the app is
  visible; otherwise a tap-to-complete notification is posted, because background activity launches are blocked.
* While the app is on screen, wake word listening pauses so the UI and the service never fight over the recognizer.

## Manufacturer layer (what is most likely to bite on Docomo models)

General reports from the community project dontkillmyapp.com say stock-like Android (Pixel) is the most
permissive, and that vendor battery managers on other brands can stop apps even when they run a foreground
service. Sony's older Stamina Mode is documented as stopping background processes and alarms. I did not find
Docomo-specific published results, so the following are recommendations rather than confirmed facts:

1. Settings → Apps → JARVIS → Battery: choose **Unrestricted** (the app's Settings screen opens the system
   screen for this).
2. Turn off any battery saver, Stamina or "adaptive" power mode that lists JARVIS as limited.
3. Lock the app in Recents if the device offers it.
4. Keep the foreground notification visible. If the system hides it, the service is more likely to be killed.
5. Docomo-bundled voice agents may compete for the microphone. If wake word detection is flaky, disable
   other always-listening assistants.

## Known limitations of this implementation

* The default wake word engine loops short speech-recognition sessions looking for "Hey JARVIS". It needs no
  API key, but it uses more battery than a dedicated keyword spotter, depends on the phone's speech service,
  and some devices play a recognizer start sound.
* Recognition may go through the phone's speech service (typically Google's), which can use the network.
* For a production-grade wake word, implement `WakeWordEngine` with an on-device keyword spotter (for example
  Picovoice Porcupine or openWakeWord) and register it in `WakeWordService`. The interface is a single
  suspend function, so nothing else changes.

## How to verify on a real device

1. Install the APK, grant the microphone permission, and turn on the wake word switch.
2. Lock the screen and wait 30 minutes, then say "Hey JARVIS" and give a command.
3. If it fails, install the free *DontKillMyApp* benchmark app and compare how the phone treats background work.
4. Report the model, Android version and what happened, and the wake word logic can be tuned for that device.

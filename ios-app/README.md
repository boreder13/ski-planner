# Ski Planner – native iPhone app

Native wrapper (Capacitor) around the trail planner, adding GPS that keeps tracking with the screen locked and last-lift reminder notifications.

## Install on your iPhone (free Apple ID, needs a Mac)

1. Install **Xcode** from the Mac App Store and open it once to finish setup.
2. Install **Node.js LTS** from nodejs.org if you don't have it.
3. Download this repository (Code → Download ZIP on GitHub), unzip it, open Terminal in the `ios-app` folder and run `bash setup.sh`.
4. In Xcode: **Settings → Accounts → +** → sign in with your Apple ID.
5. Click **App** in the left sidebar → **Signing & Capabilities** → Team: *your name (Personal Team)*.
6. Connect your iPhone with a cable, unlock it and tap **Trust**. Pick it as the run destination at the top of Xcode.
7. Press **▶ Run**. The first time, on the iPhone go to **Settings → General → VPN & Device Management** and trust your developer certificate, and turn on **Settings → Privacy & Security → Developer Mode** (restart when asked).

With a free Apple ID the app stops opening after **7 days**. Plug in the phone and press Run again to renew it, ideally the day before your trip.

## Updating the app after changes

Replace `www/index.html` (or pull the latest repository), then run `npx cap sync ios` and press Run in Xcode.

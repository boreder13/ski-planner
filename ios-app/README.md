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

## Connections (Stats tab → Connections)

- **Apple Health** (native app): tap Connect, allow access, then "Save this day to Health". Heart rate from Health shows per run in the Stats timeline.
- **Strava** (native app and web app): tap **Share GPX file**, save it to Files or AirDrop it to your Mac, then upload it at strava.com/upload with sport Snowboard. Strava's API now needs a paid Strava subscription; subscribers can instead create an app at strava.com/settings/api (website and Authorization Callback Domain `boreder13.github.io`), paste its Client ID and Secret under "Strava subscriber? Set up one-tap upload", then Connect and "Upload this day".
- **Whoop** (native app): create an app at developer-dashboard.whoop.com with redirect URL `https://boreder13.github.io/ski-planner/callback.html` and scopes `read:workout`, `read:cycles`, `offline`; paste its Client ID and Secret, then Connect. Shows day strain and heart rate plus each workout's strain and heart rate.

## Share location (Ride tab)

- **Send where I am now:** a one-time message with Apple Maps and Google Maps links.
- **Live sharing:** sends a link to `live.html`, a live map friends open in any browser, with buttons to open your spot in Apple Maps or Google Maps. Positions go through the free ntfy.sh relay on a random, unguessable channel, about every 2 minutes, and expire after 12 hours.

Keys and tokens are stored only on your phone, never in this repository.

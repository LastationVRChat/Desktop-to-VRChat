# Desktop to VRChat stream

Stream your desktop (or a window) into VRChat’s video player over the internet. OBS captures and sends video via RTMP to MediaMTX, which serves HLS locally; a Cloudflare quick tunnel exposes that stream over HTTPS so you can paste one URL into VRChat. An optional batch file starts MediaMTX and the tunnel for you.

> **Note:** Even with these settings you’ll have about 3–5 seconds delay between desktop and VRChat. Best for streaming content to watch in VRChat rather than a real-time desktop feed.

---

## Table of contents

| Section | Description |
|--------|-------------|
| [Dependencies](#dependencies) | What you need (OBS, MediaMTX, VB-Cable, Cloudflared) |
| [Pipeline](#pipeline-full-flow) | How video flows: Desktop → OBS → RTMP → MediaMTX → HTTPS → VRChat |
| [Folder setup](#folder-setup) | Where to put files for the batch launcher |
| [Batch File Launcher](#batch-file-launcher-optional) | One-click start for MediaMTX + tunnel |
| [MediaMTX](#mediamtx-converts-obs-output-into-a-vrchat-stream) | Download, configure, run (RTMP → HLS) |
| [OBS](#obs-capturing-the-stream) | Capture, stream settings, output settings |
| [Virtual Cable](#virtual-cable-audio-routing) | Route app audio into OBS |
| [Cloudflared](#cloudflared-expose-hls-over-https) | Temporary tunnel, batch usage, optional persistent tunnel |
| [Notes / Tips](#notes--tips) | Performance and reminders |

---

# Dependencies

* [OBS Studio](https://obsproject.com/) – captures your desktop or specific windows.
* [MediaMTX](https://github.com/bluenviron/mediamtx/releases) – converts your OBS stream to a VRChat-compatible format.
* [VB-Audio Virtual Cable](https://vb-audio.com/Cable/) – routes audio from applications into your stream.
* [Cloudflare Tunnel](https://github.com/cloudflare/cloudflared/releases/latest) – exposes your stream over HTTPS for remote access.
---

# Pipeline (full flow)

Video and audio move through the stack like this:

```
Desktop
   ↓
OBS (capture + encode, streams via RTMP)
   ↓
RTMP (rtmp://127.0.0.1/live, key: vrchat)
   ↓
MediaMTX (RTMP → HLS at http://localhost:8888/live/vrchat/)
   ↓
HTTPS (Cloudflare Tunnel → public https://….trycloudflare.com)
   ↓
VRChat Video Player (HLS URL: https://….trycloudflare.com/live/vrchat/index.m3u8)
```

---

# Folder setup

To use the batch file launcher, create a folder (for example on your C: drive):

```
C:\vrcstreamserver\
```

Place the batch file, MediaMTX, and Cloudflared there as described below. The batch file also works if you put it elsewhere—it uses its own folder as the base path.

---

# Batch File Launcher (Optional)

The `launch_vrc_stream.bat` file starts MediaMTX and a temporary Cloudflare tunnel so you don’t have to open multiple consoles by hand. You still need to set up OBS, MediaMTX, and Cloudflared once (see sections below); the batch is only a quick launcher.

**What it does:**

- Checks that MediaMTX and Cloudflared exist at the expected paths; if not, asks you to enter the full path to each.
- Starts **MediaMTX** in a separate window (local RTMP/HLS server).
- Starts a **temporary Cloudflare tunnel** in the same window. After a few seconds you’ll see a URL in a box (e.g. `https://something.trycloudflare.com`).
- Shows clear instructions: **your full stream URL for VRChat or OBS** is that URL plus `/live/vrchat/index.m3u8` (e.g. `https://something.trycloudflare.com/live/vrchat/index.m3u8`). Copy the URL from the box, add `/live/vrchat/index.m3u8`, and paste that full URL into VRChat or OBS.
- When you’re done streaming, close the tunnel window to stop the tunnel. You can leave MediaMTX running or close that window too.

**Expected folder layout (if you use the default paths):**

```
C:\vrcstreamserver\
  launch_vrc_stream.bat
  mediamtx\
    mediamtx.exe
    mediamtx.yml
  Cloudflared\
    cloudflared.exe
```

You can place the batch file in another folder; it will look for `mediamtx\mediamtx.exe` and `Cloudflared\cloudflared.exe` relative to its own location, or prompt you for paths if they’re missing.

---

# MediaMTX (Converts OBS output into a VRChat stream)

## Step 1 — Download & Extract

Download the Windows zip for MediaMTX and extract it so you have a folder like:

```
C:\vrcstreamserver\mediamtx\
```

(with `mediamtx.exe` and `mediamtx.yml` inside).

## Step 2 — Configure `mediamtx.yml`

A preconfigured `mediamtx.yml` can be found at [Download mediamtx.yml](https://raw.githubusercontent.com/LastationVRChat/Desktop-to-VRChat/main/mediamtx.yml)

Open `mediamtx.yml` in a text editor and replace or add the following:

```yaml
rtmp: yes
rtmpAddress: :1935

hls: yes
hlsAddress: :8888
hlsAlwaysRemux: yes
hlsVariant: mpegts            # VRChat works best with MPEG-TS segments
hlsSegmentDuration: 500ms        # half-second segments
hlsSegmentCount: 3            # keep only 3 segments
hlsPartDuration: 100ms        # fine-grained parts
hlsAllowOrigins: ['*']        # allow VRChat to access

paths:
  vrchat:
```

> **Tip:** You can try `hlsSegmentDuration: 250ms` for even lower latency; if playback stutters, use 500ms or 1s.

> **Warning:** Do not change MediaMTX to `fmp4` or `lowLatency` variant unless you’ve confirmed VRChat supports it.

optionally: you can disable unused protocols
```
rtsp: false
webrtc: false
srt: false
```

## Step 3 — Run MediaMTX

If you use the batch launcher, it starts MediaMTX for you. Otherwise, run `mediamtx.exe` from the MediaMTX folder. Leave the window open; your PC is then acting as a local stream server.

---

# OBS (Capturing the Stream)

## Step 1 — Add Sources

* In the **Sources** tab, click `+` and add a **Display Capture** or **Window Capture** depending on what you want to stream.

## Step 2 — Configure Streaming

Open **Settings → Stream**:

```
Service: Custom
Server: rtmp://127.0.0.1/live
Stream Key: vrchat
```

Click **Apply**.

## Step 3 — Start Streaming

* Click **Start Streaming** in OBS.
* You can test the local HLS stream at:

```
http://127.0.0.1:8888/live/vrchat/index.m3u8
```

## Step 4 — Output Settings

**Settings → Output → Streaming**:

```
Encoder: x264                   # (Advanced → Custom x264 Options) — add `tune=zerolatency` to reduce encoder buffering (may slightly reduce quality).
Rate Control: CBR
Bitrate: 3000
Keyframe Interval: 1            # keep at 1 second (required for HLS; shorter = lower latency).
CPU Preset: veryfast            # `veryfast` is a good balance; `superfast` or `ultrafast` reduces encoding delay at the cost of quality or CPU.
```

**Settings → Video**:

```
Resolution: 1280x720 or 1920x1080
FPS: 30
```

---

# Virtual Cable (Audio Routing)

## Step 1 — Route Audio

* Open **Windows Settings → System → Sound → Advanced Sound Options → App volume and device preferences**.
* For the app/browser you want to capture, set **Output** to `CABLE Input (VB-Audio Virtual Cable)`.

## Step 2 — Add Audio to OBS

* In OBS: **Sources → + → Audio Input Capture → Create New**.
* Select `CABLE Output (VB-Audio Virtual Cable)` as the device.

---

# Cloudflared (Expose HLS over HTTPS)

Temporary tunnels give you a public HTTPS URL so VRChat (or others) can reach your stream. **You don’t need a Cloudflare account or your own domain** for the temporary tunnel used by the batch file.

> **Usage and terms (quick tunnels)**  
> Cloudflare documents TryCloudflare / quick tunnels as a free feature intended for **testing and development**, with no uptime guarantees and some limits. For personal or occasional VRChat streams this is usually fine, but for any regular, production, or commercial use you should set up a named Cloudflare Tunnel under a Cloudflare account instead and follow their terms.

## Step 1 — Download Cloudflared

1. Go to [Cloudflared Releases](https://github.com/cloudflare/cloudflared/releases/latest).
2. Download `cloudflared-windows-amd64.exe`.
3. Put it in a folder, for example:

```
C:\vrcstreamserver\Cloudflared\cloudflared.exe
```

4. Optional: add that folder to your **Windows PATH**.

## Step 2 — Using the Batch Launcher

When you run `launch_vrc_stream.bat`, it starts a temporary tunnel in the same window. After a few seconds you’ll see output like:

```
|  Your quick Tunnel has been created! Visit it at (it may take some time to be reachable):  |
|  https://something-random.trycloudflare.com                                                |
```

**Your full stream URL for VRChat or OBS is:**

```
https://something-random.trycloudflare.com/live/vrchat/index.m3u8
```

Copy the `https://...trycloudflare.com` URL from the box, add `/live/vrchat/index.m3u8` to the end, and paste that into VRChat or OBS. No login or certificates are required. Close the batch window when you’re done to stop the tunnel. The URL changes each time you start a new tunnel.

## Step 3 — Manual Tunnel (without the batch file)

To run the tunnel yourself in a command prompt:

```
cloudflared tunnel --url http://localhost:8888
```

You’ll see a box with the `https://...trycloudflare.com` URL. Use that URL + `/live/vrchat/index.m3u8` as your stream URL in VRChat or OBS.

## Step 4 — Optional: Persistent Tunnel (same URL every time)

For a fixed URL and to run the tunnel as a Windows service (e.g. always on):

1. Create a Cloudflare account and run:

   ```
   cloudflared tunnel login
   ```

   When the browser opens, log in and select a zone (you need at least one site/domain in Cloudflare for this).

2. Create a named tunnel and route DNS:

   ```
   cloudflared tunnel create myvrchat
   cloudflared tunnel route dns myvrchat myvrchat.trycloudflare.com
   ```

3. Install and run as a Windows service (run Command Prompt as Administrator):

   ```
   cloudflared service install
   ```

Configure the service to run your tunnel (see Cloudflare’s docs). Your stream URL would then be something like `https://myvrchat.trycloudflare.com/live/vrchat/index.m3u8`. This setup is separate from the batch launcher, which only uses temporary tunnels.

---

# Notes / Tips

* For best performance, close unnecessary apps while streaming.
* Test your local stream at `http://127.0.0.1:8888/live/vrchat/index.m3u8` before using the tunnel.
* The temporary tunnel URL changes every time you run the batch file; update VRChat with the new full URL each session.

---

↑ [Back to top](#desktop-to-vrchat-stream)

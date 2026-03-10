
# Dependencies

* [OBS Studio](https://obsproject.com/) – captures your desktop or specific windows.
* [MediaMTX](https://github.com/bluenviron/mediamtx/releases) – converts your OBS stream to a VRChat-compatible format.
* [VB-Audio Virtual Cable](https://vb-audio.com/Cable/) – routes audio from applications into your stream.
* [Cloudflare Tunnel](https://github.com/cloudflare/cloudflared/releases/latest) – exposes your stream over HTTPS for remote access.

Make a folder on your C: drive at root if you wnat to use the batch file launcher.
`C:\vrcstreamserver\`

---

# Batch File Launcher (Optional)

You can down the `.bat` file to launch both MediaMTX and Cloudflared automatically. This is useful if you want to avoid opening multiple consoles manually.

Download:

**Features:**

- Checks if MediaMTX and Cloudflared exist, otherwise asks for the path.
- Starts MediaMTX for local RTMP/HLS streaming.
- Starts a temporary Cloudflare Tunnel and copies the HTTPS URL to your clipboard.
- Optionally prompts to create a persistent tunnel for always-on streaming.
- Place this `.bat` file inside `C:\vrcstreamserver\` or any folder you prefer.

---

# MediaMTX (Converts OBS output into a VRChat stream)

## Step 1 — Download & Extract

Download the Windows zip for MediaMTX and extract it somewhere like:

```
C:\vrcstreamserver\mediamtx\
```

## Step 2 — Configure `mediamtx.yml`

Open `mediamtx.yml` in a text editor and replace or add the following:

```yaml
rtmp: yes
rtmpAddress: :1935

hls: yes
hlsAddress: :8888
hlsAlwaysRemux: yes
hlsVariant: mpegts            # VRChat works best with MPEG-TS segments
hlsSegmentDuration: 1s        # 1-second segments
hlsSegmentCount: 3            # keep only 3 segments
hlsPartDuration: 200ms        # fine-grained parts
hlsAllowOrigins: ['*']        # allow VRChat to access

paths:
  vrchat:
```

> **Tip:** Keep `hlsEncryption: false` if you plan to use Cloudflare Tunnel; it handles HTTPS.

## Step 3 — Run MediaMTX

Inside the MediaMTX folder, run:

```
mediamtx.exe
```

A console window will appear — leave it running.
Your PC is now acting as a local stream server.

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
* Check your local HLS stream at:

```
http://127.0.0.1:8888/live/vrchat/index.m3u8
```

## Step 4 — Output Settings

**Settings → Output → Streaming**:

```
Encoder: x264
Rate Control: CBR
Bitrate: 3000
Keyframe Interval: 1
CPU Preset: veryfast
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

## Step 1 — Create Cloudflare Account

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Create an account or log in.
3. You **don’t need a domain**; temporary tunnels get a `.trycloudflare.com` URL.

## Step 2 — Download Cloudflared

1. Go to: [Cloudflared Releases](https://github.com/cloudflare/cloudflared/releases/latest)
2. Download `cloudflared-windows-amd64.exe`
3. Place it somewhere like:

```
C:\vrcstreamserver\Cloudflared\cloudflared.exe
```

4. Optional: add the folder to **Windows PATH** for easier access.

## Step 3 — Start a Tunnel

Run in **Command Prompt**:

```
cloudflared tunnel --url http://localhost:8888
```

* The first time, it will prompt a login via browser.
* After login, you’ll see:

```
INFO: URL (https) tunnel ready: https://random-name.trycloudflare.com
```

* Copy this HTTPS URL. This is your **public VRChat stream URL**.

## Step 4 — Update VRChat / OBS

Change your HLS stream URL to the Cloudflare Tunnel URL:

```
https://random-name.trycloudflare.com/live/vrchat/index.m3u8
```

> No certificates are needed; Cloudflare handles HTTPS.

## Step 5 — Optional: Persistent Tunnel

To make it always run:

1. Create a named tunnel:

```
cloudflared tunnel create myvrchat
```

2. Map it to your local HLS server:

```
cloudflared tunnel route dns myvrchat randomname.trycloudflare.com
```

3. Install it as a Windows service:

```
cloudflared service install
```

Now it starts automatically with Windows.

---

# Notes / Tips

* Keep `hlsSegmentDuration` and `hlsPartDuration` low for minimal VRChat latency.
* For best performance, **close unnecessary apps** while streaming.
* Always test your local stream before exposing it online.

# Server Yako ya Live Streaming (RTMP ingest → HLS 360p/480p → Player wa browser)

Stack ndogo, unayoimiliki mwenyewe: **nginx-rtmp** kwa kupokea stream, **FFmpeg** kwa
kupunguza ubora hadi **360p (SD)** na 480p, na **player wa hls.js** unaocheza kwenye
browser yoyote (Chrome, Firefox, Edge, Safari, Android, iOS).

> **Muhimu:** tumia hii kwa maudhui unayomiliki au uliyopewa haki/leseni ya kuyasambaza.
> Kurusha upya chaneli za kulipia bila ruhusa ni kinyume cha sheria za hakimiliki.

## Sehemu za mfumo

| Sehemu | Maelezo |
| --- | --- |
| `nginx/nginx.conf` | RTMP ingest (`/live`), HLS output (`/hls`), player, takwimu `/stat` |
| `transcoder/run.sh` | Sidecar ya FFmpeg: husubiri stream, hutengeneza 360p (SD) + 480p |
| `web/index.html` | Player wa browser (hls.js + fallback ya HLS asili kwa Safari) |
| `web/vendor/hls.min.js` | hls.js (imewekwa ndani, hakuna utegemezi wa CDN) |
| `scripts/push-source.sh` | Tuma file/chanzo chako kwenye server kupitia RTMP |
| `scripts/transcode-360p.sh` | Toa HLS 360p moja kwa moja bila RTMP |
| `docker-compose.yml` | Kuendesha kila kitu kwa amri moja |

## Kuanzisha

```bash
docker compose up -d
```

Bandari: `1935` (RTMP ingest), `8080` (player + HLS).

## Kutuma stream (ingest)

**OBS Studio** → Settings → Stream:
- Service: `Custom...`
- Server: `rtmp://SERVER_YAKO:1935/live`
- Stream Key: `stream` (chagua key yako mwenyewe)

**FFmpeg / file:**

```bash
./scripts/push-source.sh video.mp4 stream rtmp://SERVER_YAKO:1935
```

## Kutazama

- Player: `http://SERVER_YAKO:8080/`
- Moja kwa moja: `http://SERVER_YAKO:8080/hls/stream.m3u8` (ABR: 360p + 480p)
- 360p pekee: `http://SERVER_YAKO:8080/hls/stream_360p/index.m3u8`
- Takwimu: `http://SERVER_YAKO:8080/stat`

Player inaweza kupewa URL kupitia query string:
`http://SERVER_YAKO:8080/?src=/hls/stream.m3u8`

## Bila RTMP (rahisi zaidi)

```bash
./scripts/transcode-360p.sh input.mp4 ./web/hls-out
# tazama: http://SERVER_YAKO:8080/?src=/hls-out/stream.m3u8
```

## Kupeleka kwenye VPS (production)

1. Fungua bandari 1935/tcp na 8080/tcp (au weka nginx/Caddy mbele kwa TLS).
2. Weka HTTPS — browsers nyingi zinahitaji `https` kwa embed kwenye tovuti za https:

   ```
   server {
     listen 443 ssl;
     server_name stream.mfano.com;
     ssl_certificate     /etc/letsencrypt/live/stream.mfano.com/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/stream.mfano.com/privkey.pem;
     location / { proxy_pass http://127.0.0.1:8080; }
   }
   ```

3. Linda ingest: badilisha `allow publish all;` kuwa IP yako pekee, au tumia
   `on_publish` callback kuthibitisha stream key.

## Kurekebisha ubora

Katika `transcoder/run.sh`, badilisha `-b:v` na `scale=-2:360`
(na sasisha `hls_variant` kwenye `nginx/nginx.conf` ikibidi):

| Ubora | Bitrate ya video | scale |
| --- | --- | --- |
| 240p | 400k | `scale=-2:240` |
| 360p (SD) | 800k | `scale=-2:360` |
| 480p | 1400k | `scale=-2:480` |
| 720p | 2800k | `scale=-2:720` |

## Kuchunguza matatizo

```bash
docker compose logs -f stream        # logs za nginx/RTMP
docker compose logs -f transcoder    # logs za FFmpeg (360p/480p)
docker compose exec stream ls -R /tmp/hls   # segments zinazotengenezwa
```

- Stream key mpya? Iongeze kwenye `STREAM_KEYS` ya service ya `transcoder`
  (`docker-compose.yml`), mfano `STREAM_KEYS: "stream stream2"`.
- Player ikionyesha 404, maana yake stream bado haijaanza kuingia (angalia `/stat`).

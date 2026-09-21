import subprocess, urllib.parse, urllib.request, json, re, time, sys

def fetch_lyrics(artist, title):
    url = f"https://lrclib.net/api/get?artist_name={urllib.parse.quote(artist)}&track_name={urllib.parse.quote(title)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'SerpantinumLyrics/1.0'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            if 'syncedLyrics' in data and data['syncedLyrics']:
                lines = []
                for line in data['syncedLyrics'].split('\n'):
                    match = re.match(r'\[(\d+):(\d+\.\d+)\](.*)', line)
                    if match:
                        m, s, text = match.groups()
                        lines.append({"time": int(m) * 60 + float(s), "text": text.strip()})
                return lines
    except:
        pass
    return []

try:
    status = subprocess.check_output(['playerctl', 'status']).decode().strip()
    if status != 'Playing':
        sys.exit(0)
    title = subprocess.check_output(['playerctl', 'metadata', 'title']).decode().strip()
    artist = subprocess.check_output(['playerctl', 'metadata', 'artist']).decode().strip()
    
    # In a real app we'd cache this, but for this quick script let's just fetch it.
    # Wait, fetching on every second is a BAD idea (API rate limits!). 
    # So we MUST cache the lyrics to a file.
    cache_file = "/tmp/lyric_cache.json"
    try:
        with open(cache_file, "r") as f:
            cache = json.load(f)
    except:
        cache = {"title": "", "lyrics": []}
        
    if cache.get("title") != title:
        lyrics = fetch_lyrics(artist, title)
        cache = {"title": title, "lyrics": lyrics}
        with open(cache_file, "w") as f:
            json.dump(cache, f)
    else:
        lyrics = cache.get("lyrics", [])
        
    if lyrics:
        pos_str = subprocess.check_output(['playerctl', 'position']).decode().strip()
        pos = float(pos_str) if pos_str else 0.0
        current_lyric = ""
        for i in range(len(lyrics)):
            if pos >= lyrics[i]['time']:
                current_lyric = lyrics[i]['text']
            else:
                break
        print(current_lyric)
except Exception as e:
    pass

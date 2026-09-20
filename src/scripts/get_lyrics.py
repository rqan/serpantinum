import subprocess, urllib.parse, urllib.request, json, re

def get_lyrics():
    try:
        artist = subprocess.check_output(['playerctl', 'metadata', 'artist']).decode().strip()
        title = subprocess.check_output(['playerctl', 'metadata', 'title']).decode().strip()
    except:
        return json.dumps([{"time": 0, "text": "No music playing"}])
    if not artist or not title:
        return json.dumps([{"time": 0, "text": "Unknown song"}])
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
                if lines: return json.dumps(lines)
            if 'plainLyrics' in data and data['plainLyrics']:
                return json.dumps([{"time": 0, "text": line} for line in data['plainLyrics'].split('\n')])
            return json.dumps([{"time": 0, "text": "No lyrics found."}])
    except:
        return json.dumps([{"time": 0, "text": "No lyrics found."}])

if __name__ == "__main__":
    import sys; sys.stdout.write(get_lyrics())

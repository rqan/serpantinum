import subprocess
import urllib.parse
import urllib.request
import json

def get_lyrics():
    try:
        artist = subprocess.check_output(['playerctl', 'metadata', 'artist']).decode().strip()
        title = subprocess.check_output(['playerctl', 'metadata', 'title']).decode().strip()
    except:
        return "No music playing"
    
    if not artist or not title:
        return "Unknown song"
        
    url = f"https://lrclib.net/api/get?artist_name={urllib.parse.quote(artist)}&track_name={urllib.parse.quote(title)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'SerpantinumLyrics/1.0'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            if 'plainLyrics' in data and data['plainLyrics']:
                return data['plainLyrics']
            return "No lyrics found for this song."
    except:
        return "No lyrics found for this song."

if __name__ == "__main__":
    print(get_lyrics())

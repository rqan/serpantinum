#!/usr/bin/env python3
import subprocess
import urllib.parse
import json
import re
import time
import sys

def clean_title_candidates(t):
    candidates = []
    # Strip feat, with, remastered, etc.
    t1 = re.sub(r'[\(\[\{](?:feat|ft|with|w\/|remastered|remaster|deluxe|bonus|version|edit|live)[\.\:\s][^\)\]\}]*[\)\]\}]', '', t, flags=re.IGNORECASE).strip()
    t1 = re.sub(r'\s*-\s*(?:feat|ft|remastered|remaster|deluxe|bonus|version|edit|live).*$', '', t1, flags=re.IGNORECASE).strip()
    if t1 and t1.lower() != t.lower() and t1 not in candidates:
        candidates.append(t1)

    # Strip any trailing parenthetical e.g. (w/ 9lives), (Deluxe)
    t2 = re.sub(r'\s*[\(\[\{][^\)\]\}]*[\)\]\}]\s*$', '', t).strip()
    if t2 and t2.lower() != t.lower() and t2 not in candidates:
        candidates.append(t2)

    # Strip any trailing dash e.g. - Single, - Extended
    t3 = re.sub(r'\s*-\s*[^-]+$', '', t).strip()
    if t3 and t3.lower() != t.lower() and t3 not in candidates:
        candidates.append(t3)

    return candidates

def fetch_lrclib(artist, track):
    url = f"https://lrclib.net/api/get?artist_name={urllib.parse.quote(artist)}&track_name={urllib.parse.quote(track)}"
    try:
        out = subprocess.check_output(['curl', '-4', '-s', '-m', '4', '--connect-timeout', '3', url], stderr=subprocess.DEVNULL)
        if out:
            data = json.loads(out)
            if 'syncedLyrics' in data and data['syncedLyrics']:
                lines = []
                for line in data['syncedLyrics'].split('\n'):
                    match = re.match(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)', line)
                    if match:
                        m, s, text = match.groups()
                        lines.append({"time": int(m) * 60 + float(s), "text": text.strip()})
                return lines
    except Exception:
        pass
    return []

def fetch_lyrics(artist, title):
    # 1. Exact match with artist and title
    res = fetch_lrclib(artist, title)
    if res:
        return res

    # 2. Match with cleaned title candidates, still strictly verifying artist
    for alt in clean_title_candidates(title):
        res = fetch_lrclib(artist, alt)
        if res:
            return res

    return []

def get_active_player():
    try:
        players = subprocess.check_output(['playerctl', '-l'], stderr=subprocess.DEVNULL).decode().strip().splitlines()
        for p in players:
            p = p.strip()
            if not p:
                continue
            st = subprocess.check_output(['playerctl', '-p', p, 'status'], stderr=subprocess.DEVNULL).decode().strip()
            if st == 'Playing':
                return p
    except Exception:
        pass
    try:
        st = subprocess.check_output(['playerctl', 'status'], stderr=subprocess.DEVNULL).decode().strip()
        if 'Playing' in st.splitlines():
            return None
    except Exception:
        pass
    return False

try:
    player = get_active_player()
    if player is False:
        sys.exit(0)

    cmd_prefix = ['playerctl', '-p', player] if player else ['playerctl']
    title = subprocess.check_output(cmd_prefix + ['metadata', 'title'], stderr=subprocess.DEVNULL).decode().strip()
    artist = subprocess.check_output(cmd_prefix + ['metadata', 'artist'], stderr=subprocess.DEVNULL).decode().strip()

    if not title:
        sys.exit(0)

    cache_file = "/tmp/lyric_cache.json"
    cache = {"title": "", "artist": "", "lyrics": [], "time": 0}
    try:
        with open(cache_file, "r") as f:
            cache = json.load(f)
    except Exception:
        pass

    now = time.time()
    need_fetch = (cache.get("title") != title or cache.get("artist") != artist)
    if not need_fetch and not cache.get("lyrics"):
        # If lyrics failed or empty, retry after 15 seconds
        if now - cache.get("time", 0) > 15:
            need_fetch = True

    if need_fetch:
        lyrics = fetch_lyrics(artist, title)
        cache = {"title": title, "artist": artist, "lyrics": lyrics, "time": now}
        with open(cache_file, "w") as f:
            json.dump(cache, f)
    else:
        lyrics = cache.get("lyrics", [])

    if lyrics:
        pos_str = subprocess.check_output(cmd_prefix + ['position'], stderr=subprocess.DEVNULL).decode().strip()
        pos = float(pos_str) if pos_str else 0.0
        current_lyric = ""
        for item in lyrics:
            if pos >= item['time']:
                current_lyric = item['text']
            else:
                break
        print(current_lyric)
except Exception:
    pass

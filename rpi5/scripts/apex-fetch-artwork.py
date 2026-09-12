#!/usr/bin/env python3
import sys, json, urllib.request, urllib.parse, shutil

def fetch(query, out_path='/tmp/apex_bt_album_art.jpg'):
    try:
        q = urllib.parse.quote(query)
        url = f'https://itunes.apple.com/search?term={q}&entity=song&limit=1'
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux aarch64)'})
        with urllib.request.urlopen(req, timeout=5) as r:
            d = json.loads(r.read().decode('utf-8'))
            if d.get('resultCount', 0) > 0:
                art = d['results'][0]['artworkUrl100'].replace('100x100bb', '600x600bb')
                urllib.request.urlretrieve(art, out_path)
                if out_path != '/tmp/apex_bt_album_art.jpg':
                    try:
                        shutil.copyfile(out_path, '/tmp/apex_bt_album_art.jpg')
                    except Exception:
                        pass
                print('SAVED:', art)
                return True
    except Exception as e:
        print('ERR:', e)
    return False

if __name__ == '__main__':
    if len(sys.argv) > 2:
        fetch(sys.argv[1], sys.argv[2])
    elif len(sys.argv) > 1:
        fetch(sys.argv[1])

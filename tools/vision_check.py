# Send one image (a red square left of a blue square, built in memory) and print the answer and timing.
import base64, json, struct, time, urllib.request, zlib

def png(w, h, px):
    raw = b"".join(b"\x00" + b"".join(bytes(px(x, y)) for x in range(w)) for y in range(h))
    chunk = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")

img = png(256, 128, lambda x, y: (220, 30, 30) if x < 128 else (30, 60, 220))
body = {"model": json.load(urllib.request.urlopen("http://127.0.0.1:5000/v1/models"))["data"][0]["id"],
        "messages": [{"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": "data:image/png;base64," + base64.b64encode(img).decode()}},
            {"type": "text", "text": "This image has two colored halves. Name the color of the left half and the right half, in that order."}]}]}
t = time.time()
req = urllib.request.Request("http://127.0.0.1:5000/v1/chat/completions", json.dumps(body).encode(), {"Content-Type": "application/json"})
d = json.load(urllib.request.urlopen(req, timeout=600))
ans = (d["choices"][0]["message"].get("content") or "").strip()
ok = "red" in ans.lower() and "blue" in ans.lower() and ans.lower().find("red") < ans.lower().find("blue")
print(f"VISION {'PASS' if ok else 'FAIL'} in {time.time() - t:.1f}s: {ans[:200]!r}")

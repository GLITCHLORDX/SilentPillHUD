import os, re, hashlib, bz2, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT / "repo"
REPO.mkdir(exist_ok=True)

def read_ar_members(path: Path):
    data = path.read_bytes()
    if not data.startswith(b"!<arch>\n"):
        raise ValueError(f"{path.name} is not a valid .deb ar archive")
    pos = 8
    members = {}
    while pos + 60 <= len(data):
        header = data[pos:pos+60]
        pos += 60
        name = header[:16].decode("utf-8", "ignore").strip()
        size_txt = header[48:58].decode("utf-8", "ignore").strip()
        try:
            size = int(size_txt)
        except ValueError:
            break
        body = data[pos:pos+size]
        pos += size
        if pos % 2:
            pos += 1
        name = name.rstrip("/")
        members[name] = body
    return members

def control_from_deb(path: Path) -> str:
    import tarfile, io, gzip, lzma
    members = read_ar_members(path)
    ctrl_name = None
    for n in members:
        if n.startswith("control.tar"):
            ctrl_name = n
            break
    if not ctrl_name:
        raise ValueError(f"No control.tar found inside {path.name}")
    raw = members[ctrl_name]
    if ctrl_name.endswith(".gz"):
        raw = gzip.decompress(raw)
    elif ctrl_name.endswith(".xz"):
        raw = lzma.decompress(raw)
    # Python tarfile can read uncompressed tar from BytesIO
    with tarfile.open(fileobj=io.BytesIO(raw), mode="r:") as tf:
        for m in tf.getmembers():
            if m.name.endswith("control"):
                f = tf.extractfile(m)
                return f.read().decode("utf-8", "replace").strip()
    raise ValueError(f"No control file found inside {path.name}")

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def md5(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    debs = sorted(REPO.glob("*.deb"))
    if not debs:
        raise SystemExit("No .deb found in repo folder. Put your final .deb in repo/ first.")
    stanzas = []
    for deb in debs:
        control = control_from_deb(deb)
        rel = deb.relative_to(REPO).as_posix()
        size = deb.stat().st_size
        # Remove stale fields if they already exist
        control = re.sub(r"\n?(Filename|Size|MD5sum|SHA256):.*", "", control)
        stanza = control + f"\nFilename: {rel}\nSize: {size}\nMD5sum: {md5(deb)}\nSHA256: {sha256(deb)}\n"
        stanzas.append(stanza)
    packages = "\n".join(stanzas).strip() + "\n"
    (REPO / "Packages").write_text(packages, encoding="utf-8")
    (REPO / "Packages.bz2").write_bytes(bz2.compress(packages.encode("utf-8"), compresslevel=9))

    pkg = REPO / "Packages"
    pkgbz2 = REPO / "Packages.bz2"
    release = f"""Origin: GlitchLord Repo
Label: GlitchLord Repo
Suite: stable
Version: 1.0
Codename: ios
Architectures: iphoneos-arm
Components: main
Description: GlitchLord Cydia Repository
Date: {time.strftime('%a, %d %b %Y %H:%M:%S +0000', time.gmtime())}
MD5Sum:
 {md5(pkg)} {pkg.stat().st_size} Packages
 {md5(pkgbz2)} {pkgbz2.stat().st_size} Packages.bz2
SHA256:
 {sha256(pkg)} {pkg.stat().st_size} Packages
 {sha256(pkgbz2)} {pkgbz2.stat().st_size} Packages.bz2
"""
    (REPO / "Release").write_text(release, encoding="utf-8")
    print("Done. Generated repo/Packages, repo/Packages.bz2, and repo/Release")

if __name__ == "__main__":
    main()

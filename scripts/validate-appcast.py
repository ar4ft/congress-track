"""Check generated feed metadata before it is published (never modify signed XML)."""
import base64
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
from release_config import metadata

NS = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"


def validate(feed, archive, prefix, value):
    root = ET.parse(feed).getroot()
    items = root.findall("./channel/item")
    if len(items) != 1:
        raise ValueError("Expected one full update in the generated feed")
    item = items[0]
    enclosure = item.find("enclosure")
    if enclosure is None:
        raise ValueError("Update feed has no archive enclosure")
    version = item.findtext(NS + "version") or enclosure.get(NS + "version")
    if version != str(value["build"]):
        raise ValueError("Feed build number differs from Release.json")
    short = item.findtext(NS + "shortVersionString") or enclosure.get(NS + "shortVersionString")
    if short != value["version"]:
        raise ValueError("Feed version differs from Release.json")
    if item.findtext(NS + "minimumSystemVersion") != value["minimumSystemVersion"]:
        raise ValueError("Feed must enforce the app's minimum macOS version")
    if enclosure.get("url") != prefix + Path(archive).name:
        raise ValueError("Feed archive URL differs from its immutable versioned release URL")
    if int(enclosure.get("length", "0")) != Path(archive).stat().st_size:
        raise ValueError("Feed archive length mismatch")
    signature = enclosure.get(NS + "edSignature", "")
    try:
        if len(base64.b64decode(signature, validate=True)) != 64:
            raise ValueError()
    except Exception:
        raise ValueError("Update archive has no valid Ed25519 signature metadata") from None
    return signature


if __name__ == "__main__":
    try:
        signature = validate(sys.argv[1], sys.argv[2], sys.argv[3], metadata())
        print(signature)
    except (ValueError, ET.ParseError) as error:
        sys.exit(str(error))

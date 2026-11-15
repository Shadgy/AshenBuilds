"""Generate unverified Octo armor records from a scoped item list and saved public pages."""

import argparse
import hashlib
import html
import json
from pathlib import Path
import re


SLOTS = {
    1: ("HEAD", "Head"), 3: ("SHOULDER", "Shoulder"), 5: ("CHEST", "Chest"),
    6: ("WAIST", "Waist"), 7: ("LEGS", "Legs"), 8: ("FEET", "Feet"),
    9: ("WRIST", "Wrist"), 10: ("HANDS", "Hands"), 11: ("FINGER", "Finger"),
    20: ("ROBE", "Chest"),
}
ARMOR_TYPES = {0: "", 1: "Cloth", 2: "Leather", 3: "Mail", 4: "Plate"}
FLAT_STATS = {
    "strength": "str", "agility": "agi", "stamina": "sta",
    "intellect": "int", "spirit": "spi",
    "fire resistance": "fireRes", "frost resistance": "frostRes",
    "nature resistance": "natureRes", "shadow resistance": "shadowRes",
    "arcane resistance": "arcaneRes", "holy resistance": "holyRes",
}
BIND_TYPES = {
    "Binds when picked up": 1,
    "Binds when equipped": 2,
    "Binds when used": 3,
}
EFFECT_TRIGGERS = {"Use": 0, "Equip": 1, "Chance on hit": 2}
MODIFIERS = (
    (r"\+(\d+) Attack Power", ("ap",)),
    (r"\+(\d+) Ranged Attack Power", ("rap",)),
    (r"Improves your chance to hit by (\d+)%", ("hit",)),
    (r"Improves your chance to hit with spells by (\d+)%", ("spellHit",)),
    (r"Improves your chance to get a critical strike by (\d+)%", ("crit",)),
    (r"Improves your chance to get a critical strike with spells by (\d+)%", ("spellCrit",)),
    (r"Increases (?:your )?attack speed by (\d+)%", ("haste",)),
    (r"Increases damage and healing done by magical spells and effects by up to (\d+)", ("spellPower", "healing")),
    (r"Increases healing done by spells and effects by up to (\d+)", ("healing",)),
    (r"Restores (\d+) mana per 5 sec", ("mp5",)),
    (r"Restores (\d+) health per 5 sec", ("hp5",)),
    (r"Decreases the magical resistances of your spell targets by (\d+)", ("spellPen",)),
    (r"\+(\d+) All Resistances", ("fireRes", "frostRes", "natureRes", "shadowRes", "arcaneRes")),
    (r"Increases defense by (\d+)", ("defense",)),
    (r"Increases your chance to dodge an attack by (\d+)%", ("dodge",)),
    (r"Increases your chance to parry an attack by (\d+)%", ("parry",)),
    (r"Increases your chance to block attacks with a shield by (\d+)%", ("block",)),
)
TAG = re.compile(r"<[^>]*>")
EFFECT = re.compile(r"<span\b[^>]*>\s*(Equip|Use|Chance on hit):\s*(.*?)</span>", re.S)
ACQUISITION_TABS = {
    "sold-by", "dropped-by", "reward-from-q", "rewarded-by", "created-by",
}


def capture(pattern, source, label):
    match = re.search(pattern, source, re.S)
    if match is None:
        raise ValueError(f"missing {label}")
    return match


def plain(source):
    return " ".join(html.unescape(TAG.sub(" ", source)).split())


def integer_field(source, name):
    return int(capture(rf"\b{name}:\s*(-?\d+)\b", source, name)[1])


def add_stats(stats, effect):
    """Count only unconditional effects with a corresponding planner stat."""
    for pattern, keys in MODIFIERS:
        match = re.fullmatch(pattern, effect.removesuffix("."), re.I)
        if match:
            for key in keys:
                stats[key] = stats.get(key, 0) + int(match[1])
            return True
    return False


def read_effects(tooltip, stats):
    effects, unmapped = [], []
    for line in EFFECT.finditer(tooltip):
        effect = plain(line[2])
        spell = re.search(r'\?spell=(\d+)', line[2])
        trigger = EFFECT_TRIGGERS[line[1]]
        effects.append([trigger, effect, int(spell[1]) if spell else 0])
        if trigger == 1 and not add_stats(stats, effect):
            mixed = re.fullmatch(r"Improves spell critical strike chance by (\d+)% and (.+)\.", effect)
            if mixed:
                stats["spellCrit"] = stats.get("spellCrit", 0) + int(mixed[1])
                unmapped.append(mixed[2])
            else:
                unmapped.append(effect)
    if len(effects) != len(re.findall(r"\b(?:Equip|Use|Chance on hit):", plain(tooltip))):
        raise ValueError("an effect could not be read from the tooltip")
    return effects, unmapped


def parse_item(item_id, listing, page):
    listed_id, item_level, fields, listed_name = listing
    if listed_id != item_id:
        raise ValueError("listing ID does not match")
    kind = integer_field(fields, "classs")
    subclass = integer_field(fields, "subclass")
    slot_number = integer_field(fields, "slot")
    if kind != 4 or subclass not in ARMOR_TYPES or slot_number not in SLOTS:
        raise ValueError("not a supported wearable armor slot")
    slot, slot_label = SLOTS[slot_number]
    tooltip = capture(rf'<div id="tooltip{item_id}-generic"[^>]*>(.*?)</div>', page, "item tooltip")[1]
    title = capture(r'<b class="q(\d+)">(.*?)</b>', tooltip, "item title and quality")
    quality, name = int(title[1]), plain(title[2])
    name_match = capture(r"\{name:\s*'(\d)((?:\\.|[^'])*)'", listed_name, "listing name")
    expected_name = html.unescape(name_match[2].replace("\\'", "'"))
    if name != expected_name or quality != 6 - int(name_match[1]):
        raise ValueError("tooltip name or quality does not match the listing")
    if int(capture(r"<div>Level:\s*(\d+)</div>", page, "item level")[1]) != item_level:
        raise ValueError("tooltip item level does not match the listing")
    armor_slot = capture(r'<table width="100%">\s*<tr>\s*<td>(.*?)</td>\s*<th>(.*?)</th>', tooltip, "equipment slot")
    if plain(armor_slot[1]) != slot_label or plain(armor_slot[2]) != ARMOR_TYPES[subclass]:
        raise ValueError("tooltip equipment slot or armor type does not match the listing")

    base = plain(tooltip)
    level = re.search(r"\bRequires Level (\d+)\b", base)
    armor = re.search(r"\b(\d+) Armor\b", base)
    durability = re.search(r"\bDurability (\d+) / (\d+)\b", base)
    required_level = int(level[1]) if level else 0
    armor_value = int(armor[1]) if armor else 0
    if required_level != integer_field(fields, "reqlevel") or armor_value != integer_field(fields, "armor"):
        raise ValueError("tooltip armor or required level does not match the listing")
    class_mask = int(capture(r"<div>Class Mask:\s*(-?\d+)</div>", page, "class mask")[1])
    race_mask = int(capture(r"<div>Race Mask:\s*(-?\d+)</div>", page, "race mask")[1])
    icon = capture(rf"ge\('icon{item_id}-generic'\)\.appendChild\(Icon\.create\('([A-Za-z0-9_]+)'", page, "icon")[1]

    binding = next((text for text in BIND_TYPES if text in base), "")
    unique = re.search(r"\bUnique(?:\s*\((\d+)\))?\b", base)
    stats = {"armor": armor_value} if armor_value else {}
    effect_start = EFFECT.search(tooltip)
    base_html = tooltip[:effect_start.start()] if effect_start else tooltip
    for match in re.finditer(r"([+-]\d+) ([A-Za-z ]+)<br\s*/?>", base_html):
        label = match[2].strip().lower()
        if label not in FLAT_STATS:
            raise ValueError(f"unrecognized base stat {label!r}")
        stats[FLAT_STATS[label]] = int(match[1])
    effects, unmapped = read_effects(tooltip, stats)

    relation_tabs = []
    for listview in re.findall(r"new Listview\(\{(.*?)\}\);", page, re.S):
        tab = re.search(r"\bid:\s*'([\w-]+)'", listview)
        if tab and re.search(r"\bdata:\s*\[\s*\{", listview) and tab[1] not in {"comments", "similar"}:
            relation_tabs.append(tab[1])

    item = [
        name, quality, slot, required_level, item_level, icon, kind, subclass,
        armor_value, 0, class_mask, race_mask, BIND_TYPES.get(binding, 0),
        int(unique[1] or 1) if unique else 0, 0, 0, 0, "", stats, [],
    ]
    details = [binding, int(durability[2]) if durability else 0, 0, "", 0, 0, 0, 0, effects]
    return item, details, unmapped, relation_tabs


def lua(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, dict):
        return "{" + ",".join(f"{key}={lua(val)}" for key, val in sorted(value.items())) + "}"
    return "{" + ",".join(map(lua, value)) + "}"


def generate(listing_file, pages, output, report_file):
    scope = json.loads(listing_file.read_text(encoding="utf-8"))
    report = {"scanned": len(scope), "added": [], "skipped": {}, "relations": {}, "unmodeled_equip": {}, "pages": {}}
    digest = hashlib.sha256()
    lines = [
        "-- Generated by tools/build_octo_unverified_items.py. See docs/octo-item-audit.md.",
        "AshenDB.OctoUnverifiedItems = AshenDB.OctoUnverifiedItems or {}",
        "local function Add(id,item,details)",
        "  if AshenDB.Items[id] then return end",
        "  AshenDB.Items[id]=item",
        "  AshenDB.ItemDetails[id]=details",
        "  AshenDB.OctoUnverifiedItems[id]=true",
        "  table.insert(AshenDB.ItemOrder,id)",
        "end",
    ]
    for item_id in sorted(map(int, scope)):
        identifier = str(item_id)
        try:
            raw = (pages / f"{item_id}.html").read_bytes()
            page_hash = hashlib.sha256(raw).hexdigest()
            report["pages"][identifier] = page_hash
            digest.update(f"{item_id} {page_hash}\n".encode("ascii"))
            item, details, unmapped, relations = parse_item(item_id, scope[identifier], raw.decode("utf-8"))
        except FileNotFoundError:
            report["skipped"][identifier] = "no cached item page"
            continue
        except (UnicodeError, ValueError) as error:
            report["skipped"][identifier] = str(error)
            continue
        if relations:
            report["relations"][identifier] = relations
        if ACQUISITION_TABS.intersection(relations):
            report["skipped"][identifier] = "direct acquisition relation requires review"
            continue
        if unmapped:
            report["unmodeled_equip"][identifier] = unmapped
        lines.append(f"Add({item_id},{lua(item)},{lua(details)})")
        report["added"].append(item_id)

    lines.append("AshenDB.Manifest.itemCount=table.getn(AshenDB.ItemOrder)")
    report["pages_digest"] = digest.hexdigest()
    lines.insert(1, f"-- Octo item page digest (ID and SHA256): {report['pages_digest']}")
    output.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    report_file.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print(f"Scanned {len(scope)} IDs, exported {len(report['added'])}, skipped {len(report['skipped'])}.")
    print(f"Page digest: {report['pages_digest']}; see {report_file} for details.")


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("listing", type=Path)
    cli.add_argument("pages", type=Path)
    cli.add_argument("--output", type=Path, required=True)
    cli.add_argument("--report", type=Path, required=True)
    options = cli.parse_args()
    generate(options.listing, options.pages, options.output, options.report)


if __name__ == "__main__":
    main()

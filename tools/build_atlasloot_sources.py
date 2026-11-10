"""Record acquisition evidence from the installed AtlasLoot data, without changing stats.

python tools/build_atlasloot_sources.py PATH_TO_ATLASLOOT --database SNAPSHOT.sqlite

Only declarative Database files are loaded, in a restricted Lua environment with no
I/O, package loader, game APIs or ordinary libraries. Showcase tables never count.
Set collections need a recognized acquisition family or independent mapped phase.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import re
import sqlite3

from lupa.lua51 import LuaRuntime, lua_type

ROOT = Path(__file__).resolve().parents[1]
DATA_FILES = ("Instances.lua", "WorldBosses.lua", "Crafting.lua", "PvP.lua", "Sets.lua",
              "Factions.lua", "WorldEvents.lua", "TableRegister.lua", "Spells.lua")
RAIDS = {"Molten Core": 0, "Onyxia's Lair": 0, "Lower Karazhan Halls": 0,
         "Zul'Gurub": 1, "Blackwing Lair": 2, "Emerald Sanctum": 3,
         "Ruins of Ahn'Qiraj": 4, "Temple of Ahn'Qiraj": 4, "Ahn'Qiraj": 4,
         "Timbermaw Hold": 5, "Naxxramas": 6, "Tower of Karazhan": 7}
INSTANCE_ALIASES = {"Karazhan": "Lower Karazhan Halls", "Upper Karazhan Halls": "Tower of Karazhan",
                    "Dire Maul (East)":"Dire Maul","Dire Maul (West)":"Dire Maul","Dire Maul (North)":"Dire Maul",
                    "Lower Blackrock Spire":"Blackrock Spire","Upper Blackrock Spire":"Blackrock Spire",
                    "Scarlet Monastery (Armory)":"Scarlet Monastery","Scarlet Monastery (Cathedral)":"Scarlet Monastery",
                    "Scarlet Monastery (Graveyard)":"Scarlet Monastery","Scarlet Monastery (Library)":"Scarlet Monastery",
                    "The Sunken Temple":"The Temple of Atal'Hakkar","The Crescent Grove":"Crescent Grove",
                    "Caverns of Time: Black Morass":"The Black Morass"}
EXCLUDED_GROUPS = set()
EXCLUDED_TABLES = {"EmptyInstance", "Legendaries", "RarePets1", "RarePets2"}
EXCLUDED_ITEM_IDS={13262:"Original Ashbringer: no supported acquisition route",
                   18582:"Twin Blades of Azzinoth: unsupported showcase item",
                   18583:"Twin Blades of Azzinoth: unsupported showcase item",
                   18584:"Twin Blades of Azzinoth: unsupported showcase item",
                   17782:"Talisman of Binding Shard: removed/test loot",
                   22736:"Andonisus: temporary encounter weapon, not permanent equipment"}
SAFE_GROUPS = {"AtlasLootItems", "AtlasLootWBItems", "AtlasLootCrafting",
               "AtlasLootBGItems", "AtlasLootGeneralPvPItems", "AtlasLootRepItems",
               "AtlasLootWorldEvents", "AtlasLootSetItems"}
HONOR_PHASE={11:1,12:2,13:3,14:6}
SET_FAMILIES=(("T35",7,"Tower of Karazhan"),("T3",6,"Naxxramas"),("T25",4,"Temple of Ahn'Qiraj"),
              ("T2",2,"Blackwing Lair"),("T1",0,"Molten Core"),
              ("T0",0,None),("TMH",5,"Timbermaw Hold"),
              ("AQ20",4,"Ruins of Ahn'Qiraj"),("AQ40",4,"Temple of Ahn'Qiraj"),
              ("ZG",1,"Zul'Gurub"))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def code_only(text):
    """Remove strings/comments before checking the small declarative input language."""
    out, i = [], 0
    while i < len(text):
        if text.startswith("--", i):
            long = re.match(r"--\[(=*)\[", text[i:])
            if long:
                close = "]" + long.group(1) + "]"
                end = text.find(close, i + long.end())
                if end < 0:
                    raise ValueError("Unterminated Lua comment")
                i = end + len(close)
            else:
                end = text.find("\n", i)
                i = len(text) if end < 0 else end + 1
            out.append(" ")
        elif text[i] in "\"'":
            quote = text[i]
            i += 1
            while i < len(text):
                if text[i] == "\\":
                    i += 2
                elif text[i] == quote:
                    i += 1
                    break
                else:
                    i += 1
            else:
                raise ValueError("Unterminated Lua string")
            out.append("'string'")
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


def validate_declarations(text):
    code = code_only(text)
    if re.search(r"\b(?:function|for|while|repeat|until|if|then|return|goto|do|end)\b", code):
        raise ValueError("AtlasLoot export accepts declarative tables only")
    if any(char in code for char in "():"):
        raise ValueError("Function calls and methods are not allowed in AtlasLoot data")


class DataLoader:
    def __init__(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.env, self.run = self.lua.execute("""
            local env={AtlasLoot_Data={},AtlasLootBossButtons={},GREEN_FONT_COLOR_CODE="|cff00ff00",FONT_COLOR_CODE_CLOSE="|r",ITEM_RANDOM_ENCHANT="Random enchantment"}
            env.AtlasLoot={L=setmetatable({},{__index=function(_,key) return key end})}
            return env,function(source)
                local f,err=loadstring(source)
                if not f then error(err) end
                setfenv(f,env); f()
            end
        """)

    def load(self, text):
        # This client-formatting-only field is irrelevant to acquisition IDs.
        text=re.sub(r"format\(ITEM_SPELL_CHARGES_P1,\s*\d+\)", '"Charges"', text)
        validate_declarations(text)
        self.run(text)


def plain(value):
    if lua_type(value) == "table":
        return {k: plain(v) for k, v in value.items()}
    return value


def lua(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (list, tuple)):
        return "{" + ",".join(lua(v) for v in value) + "}"
    if isinstance(value, dict):
        return "{" + ",".join("[" + lua(k) + "]=" + lua(v)
                              for k, v in sorted(value.items(), key=lambda pair: str(pair[0]))) + "}"
    raise TypeError(type(value))


def strip_colors(value):
    return re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", str(value or ""))


def flatten_titles(table):
    titles = {}
    for key, row in table.items():
        if not isinstance(row, dict):
            continue
        if isinstance(row.get(1), str) and isinstance(row.get(2), str):
            titles[key] = row
        else:
            titles.update(flatten_titles(row))
    return titles


def rows(table):
    if not isinstance(table, dict):
        return
    first = table.get(1)
    if isinstance(first, (int, str)):
        yield table
        return
    for _, child in sorted(table.items(), key=lambda pair: (0,pair[0]) if isinstance(pair[0],int) else (1,str(pair[0]))):
        if isinstance(child, dict):
            yield from rows(child)


def phase_hint(record):
    """A resolved route is a usable phase; a lower bound remains only a lower bound."""
    if not isinstance(record, dict):
        return {}
    if isinstance(record.get("p"), (int, float)):
        return {"phase": int(record["p"])}
    if isinstance(record.get("l"), (int, float)) and record["l"] > 0:
        return {"minimumPhase": int(record["l"])}
    return {}


def table_route(key, group, title):
    context = strip_colors(title.get(3, ""))
    label = strip_colors(title.get(1, key))
    route = {"table": key, "kind": "source", "source": label}
    if context:
        # TableRegister records the raid or dungeon name after [RAID]/[level range].
        match = re.match(r"\[[^]]+\]\s*(.+)", context)
        instance = match.group(1).strip() if match else context.strip()
        instance = INSTANCE_ALIASES.get(instance, instance)
        route["instance"] = instance
        if instance in RAIDS:
            route.update(phase=RAIDS[instance], kind="raid")
        elif re.match(r"\[\d+[-\d ]*\]", context):
            route.update(phase=0, kind="dungeon")
    if group == "AtlasLootCrafting":
        route["kind"] = "craft"
    elif group == "AtlasLootRepItems":
        route["kind"] = "reputation"
        if key.startswith("Zandalar"):
            route.update(phase=1, instance="Zul'Gurub")
        elif key == "AQBroodRings":
            route.update(phase=4, instance="Temple of Ahn'Qiraj")
    elif group in ("AtlasLootBGItems", "AtlasLootGeneralPvPItems"):
        route["kind"] = "pvp"
    elif group == "AtlasLootWorldEvents":
        route["kind"] = "event"
        if key.startswith("ScourgeInvasion"):
            route["phase"] = 6
    elif group == "AtlasLootWBItems":
        route["kind"] = "worldboss"
    return route


def add_route(destination, identifier, route):
    if not isinstance(identifier, int) or identifier <= 0 or identifier in EXCLUDED_ITEM_IDS:
        return
    record = destination.setdefault(identifier, {"routes": []})
    if route not in record["routes"]:
        record["routes"].append(dict(route))


def fallback_phase(route, record):
    result = dict(route)
    if "phase" not in result:
        result.update(phase_hint(record))
    return result


def row_route(route,row,record,group,key,summaries,inherited_rank=None):
    result=dict(route)
    if group=="AtlasLootSetItems":
        classes=r"(?:Druid|Hunter|Mage|Paladin|Priest|Rogue|Shaman|Warlock|Warrior)C?"
        family=next((entry for entry in SET_FAMILIES
                     if re.fullmatch(re.escape(entry[0])+classes,key)
                     or (entry[0]=="TMH" and re.fullmatch(r"TMH(?:ClothHealer|ClothDps|Leather|Mail|Plate)",key))
                     or (entry[0]=="ZG" and key in ("ZGRings","ZGRingsC"))),None)
        if family:
            _,phase,instance=family
            result.update(phase=phase,kind="raid" if instance else "quest",evidence="set-family")
            if instance:result["instance"]=instance
            # Real mapped low-phase sources, e.g. T2 Onyxia helmets, take priority
            # over the general set family. Never apply this to Legendaries.
            hint=phase_hint(record)
            if "phase" in hint:
                result["phase"]=hint["phase"]
                if hint["phase"]!=phase:result.pop("instance",None)
                for zone in record.get("z",()):
                    location=summaries.get("locations",{}).get(zone,{})
                    if location.get("phase")==hint["phase"] and location.get("type") in (1,2):
                        result["instance"]=location["name"];break
        else:
            # Generic collections need independent mapped acquisition. This path
            # cannot admit excluded showcase pages such as Legendaries.
            hint=phase_hint(record)
            if not hint:return None
            result.update(hint,evidence="mapped-collection",kind="worlddrop" if key.startswith("WorldEpics") else "source")
    if group in ("AtlasLootBGItems","AtlasLootGeneralPvPItems"):
        description=" ".join(str(value) for value in row.values() if isinstance(value,str))
        match=re.search(r"\bRank\s+(\d+)\b",description)
        rank=int(match.group(1)) if match else inherited_rank
        if rank is not None:
            result.update(rank=rank,phase=HONOR_PHASE.get(rank,0) if 1<=rank<=14 else None)
            if result["phase"] is None:result.pop("phase")
        elif group=="AtlasLootBGItems":
            result["phase"]=0
    return fallback_phase(result,record)


def database_links(path):
    """Spell/item IDs supply joins only, never make an unlisted item verified."""
    created, application, taught = defaultdict(set), defaultdict(set), defaultdict(set)
    if path is None:
        return created, application, taught
    connection = sqlite3.connect(f"file:{Path(path).resolve().as_posix()}?mode=ro", uri=True)
    try:
        for spell, item in connection.execute("select spell,item from spell_creates"):
            created[spell].add(item)
        for spell, item in connection.execute("select spell,item from spell_taught_item"):
            taught[spell].add(item)
        fields=",".join("spellid_"+str(i)+",spelltrigger_"+str(i) for i in range(1,6))
        for row in connection.execute("select entry,"+fields+" from items where hidden=0"):
            for offset in range(1,len(row),2):
                spell,trigger=row[offset:offset+2]
                if spell and trigger==0:
                    application[spell].add(row[0])
    finally:
        connection.close()
    return created, application, taught


def collect(data, titles, spells, enchants, summaries, created=None, application=None, taught=None):
    created, application, taught = created or {}, application or {}, taught or {}
    items, spell_routes = {}, defaultdict(list)
    counts = defaultdict(int)
    for group, tables in sorted(data.items()):
        if group not in SAFE_GROUPS or group in EXCLUDED_GROUPS:
            counts["excludedGroups"] += 1
            continue
        for key, table in sorted(tables.items()):
            if key in EXCLUDED_TABLES or not isinstance(table, dict):
                counts["excludedTables"] += 1
                continue
            if group=="AtlasLootGeneralPvPItems" and key.endswith(("AC","HC")):
                # These are collection aliases; the actual rank pages have the
                # rank requirement per row and must be used instead.
                counts["excludedTables"]+=1
                continue
            title = titles.get(key)
            if not title or title.get(2) != group:
                counts["unregisteredTables"] += 1
                # These are still inside an explicit acquisition data group,
                # e.g. crafting armor sets or faction/rank reward subpages.
                title={1:key,2:group}
            route = table_route(key, group, title)
            counts["acquisitionTables"] += 1
            rank_context=None
            for row in rows(table):
                identifier = row.get(1)
                if identifier==0 and group in ("AtlasLootBGItems","AtlasLootGeneralPvPItems"):
                    header=" ".join(str(value) for value in row.values() if isinstance(value,str))
                    rank=re.search(r"\bRank\s+(\d+)\b",header)
                    if rank:rank_context=int(rank.group(1))
                if isinstance(identifier, int) and identifier > 0:
                    actual=row_route(route,row,summaries.get("items",{}).get(identifier),group,key,summaries,rank_context)
                    if actual:add_route(items, identifier, actual)
                elif isinstance(identifier, str) and re.fullmatch(r"[es]\d+", identifier):
                    spell = int(identifier[1:])
                    if route not in spell_routes[spell]:
                        spell_routes[spell].append(route)
                    kind = "enchants" if identifier[0] == "e" else "craftspells"
                    extra = spells.get(kind, {}).get(spell, {})
                    products = set(created.get(spell, ()))
                    if isinstance(extra.get("item"), int):
                        products.add(extra["item"])
                    for item in products:
                        add_route(items, item, fallback_phase(route, summaries.get("items", {}).get(item)))
    # A collection is corroboration, not an alternative acquisition route. If
    # actual loot/craft/reputation evidence exists, it alone supplies the routes.
    # Otherwise generic SQL p=0 could reopen a phased event or raid reward.
    for record in items.values():
        actual=[route for route in record["routes"] if not route.get("evidence")]
        if actual:record["routes"]=actual
    enchant_records = {}
    for stable_id, enchant in sorted(enchants.items()):
        spell = enchant.get("spell")
        for route in spell_routes.get(spell, ()):
            add_route(enchant_records, stable_id, fallback_phase(route, summaries.get("enchants", {}).get(stable_id)))
        # Applied arcanums, oils and armor kits can be numeric AtlasLoot loot rows.
        for item in application.get(spell, ()):
            for route in items.get(item, {}).get("routes", ()):
                joined = dict(route, item=item)
                add_route(enchant_records, stable_id, fallback_phase(joined,summaries.get("enchants",{}).get(stable_id)))
        # Recipe loot also proves the taught enchant, but not an unrelated spell.
        for recipe in taught.get(spell, ()):
            for route in items.get(recipe, {}).get("routes", ()):
                joined = dict(route, recipe=recipe)
                add_route(enchant_records, stable_id, fallback_phase(joined,summaries.get("enchants",{}).get(stable_id)))
    for records in (items, enchant_records):
        for record in records.values():
            record["routes"].sort(key=lambda route: json.dumps(route, sort_keys=True))
    counts["spellRows"] = len(spell_routes)
    return items, enchant_records, dict(counts)


def build(atlas, root=ROOT, database=None, checked="2026-11-10"):
    atlas, root = Path(atlas), Path(root)
    loader = DataLoader()
    hashes = {}
    for name in DATA_FILES:
        path = atlas / "Database" / name
        text = path.read_text(encoding="utf-8-sig")
        loader.load(text)
        hashes["Database/" + name] = sha(path)
    for name in ("Data/Enchants.lua", "Data/ContentSources.lua"):
        path = root / name
        text=path.read_text(encoding="utf-8-sig")
        if name=="Data/Enchants.lua": text=text.split("AshenBuildsEnchantOrder",1)[0]
        loader.load(text)
        hashes[name] = sha(path)
    toc = atlas / "AtlasLoot.toc"
    version = re.search(r"(?m)^## Version:\s*(\S+)", toc.read_text(encoding="utf-8-sig")).group(1)
    hashes["AtlasLoot.toc"] = sha(toc)
    source = plain(loader.env)
    created, application, taught = database_links(database)
    items, enchants, counts = collect(source["AtlasLoot_Data"], flatten_titles(source["AtlasLoot_TableNames"]),
                                      source["GetSpellInfoAtlasLootDB"], source["AshenBuildsEnchants"],
                                      source["AshenBuildsContentSources"], created, application, taught)
    meta = {"source": "Installed AtlasLoot TurtleWOW", "version": version,
            "checked": checked, "files": hashes, "itemCount": len(items),
            "enchantCount": len(enchants), "counts": counts,
            "excluded": sorted(EXCLUDED_GROUPS | EXCLUDED_TABLES)}
    meta["excludedItemIds"]=EXCLUDED_ITEM_IDS
    catalog=source["AshenBuildsContentSources"].get("items",{})
    meta["catalogItemCount"]=sum(identifier in catalog for identifier in items)
    meta["phaseMappedCatalogItems"]=sum(identifier in catalog and any("phase" in route for route in record["routes"])
                                         for identifier,record in items.items())
    meta["missingEnchants"]=[{"id":identifier,"name":enchant["n"],"spell":enchant.get("spell")}
                              for identifier,enchant in sorted(source["AshenBuildsEnchants"].items())
                              if identifier not in enchants]
    if database:
        meta["joinDatabaseSha256"] = sha(database)
    return {"meta": meta, "items": items, "enchants": enchants}


def write(data, destination):
    lines = ["-- Generated AtlasLoot acquisition evidence; see docs/atlasloot-sources.md.",
             "AshenBuildsAtlasLootSources={meta=" + lua(data["meta"]) + ",items={},enchants={}}",
             "local I=AshenBuildsAtlasLootSources.items"]
    lines.extend("I[" + str(identifier) + "]=" + lua(record) for identifier, record in sorted(data["items"].items()))
    lines.append("local E=AshenBuildsAtlasLootSources.enchants")
    lines.extend("E[" + str(identifier) + "]=" + lua(record) for identifier, record in sorted(data["enchants"].items()))
    Path(destination).write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("atlasloot", type=Path)
    parser.add_argument("--database", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "Data/AtlasLootSources.lua")
    args = parser.parse_args()
    data = build(args.atlasloot, database=args.database)
    write(data, args.output)
    print(json.dumps(data["meta"], indent=2))


if __name__ == "__main__":
    main()

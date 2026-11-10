"""Export native permanent-enchant IDs from a recorded Tortoise SQLite snapshot."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sqlite3


ROOT=Path(__file__).resolve().parents[1]


def export(database, enchants, output):
    text=Path(enchants).read_text(encoding="utf-8")
    addon_spells={int(a):int(s) for a,s in re.findall(r'\[(\d+)\]=\{[^\n]*?\bspell=(\d+)',text)}
    if not addon_spells:
        raise ValueError("No planner enchant spell IDs found")
    native={}
    with sqlite3.connect(str(database)) as con:
        for addon,spell in sorted(addon_spells.items()):
            row=con.execute("select effects from spells where entry=?",(spell,)).fetchone()
            if row is None:
                raise ValueError("Missing enchant spell in source snapshot: "+str(spell))
            effects=json.loads(row[0] or "[]")
            for effect in effects:
                ident=int(effect.get("misc") or 0)
                if effect.get("effect")==53 and ident>0:
                    native.setdefault(ident,set()).add(addon)
    if not native:
        raise ValueError("No native permanent enchant effects found")
    digest=hashlib.sha256(Path(database).read_bytes()).hexdigest()
    lines=["-- Generated from "+Path(database).name+"; SHA256 "+digest,
           "-- A shared native effect can have several slot-compatible planner applications.",
           "AshenBuilds=AshenBuilds or {}", "AshenBuilds.NativeEnchantIds={"]
    for ident,candidates in sorted(native.items()):
        lines.append("  ["+str(ident)+"]={"+",".join(str(n) for n in sorted(candidates))+"},")
    lines.append("}\n")
    Path(output).write_text("\n".join(lines),encoding="utf-8",newline="\n")
    return len(native)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database",type=Path,required=True)
    parser.add_argument("--enchants",type=Path,default=ROOT/"Data"/"Enchants.lua")
    parser.add_argument("--output",type=Path,default=ROOT/"Data"/"EnchantIds.lua")
    args=parser.parse_args()
    print("Exported",export(args.database,args.enchants,args.output),"native enchant effects")


if __name__=="__main__":
    main()

"""Export complete acquisition-route summaries without replacing the embedded item catalog.

python tools/build_content_sources.py tools/work/tortoise-VERSION.sqlite
"""
from __future__ import annotations
import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[1]
# Map IDs, not English NPC/item names, identify phased raid content.
RAID_PHASE = {249:0,409:0,532:0,309:1,469:2,807:3,509:4,531:4,819:5,533:6,814:7}
MAP_NAMES = {34:'The Stockade',36:'The Deadmines',109:"The Temple of Atal'Hakkar",269:'The Black Morass',531:"Temple of Ahn'Qiraj"}
HONOR_PHASE = {11:1,12:2,13:3,14:6}


def lua(value):
    if value is None: return 'nil'
    if isinstance(value, bool): return 'true' if value else 'false'
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int,float)): return str(value)
    if isinstance(value, (list,tuple,set)): return '{'+','.join(lua(v) for v in value)+'}'
    if isinstance(value, dict): return '{'+','.join(('['+lua(k)+']='+lua(v)) for k,v in sorted(value.items(),key=lambda kv:str(kv[0])))+'}'
    raise TypeError(type(value))


def location_records(maps):
    return {mid:{'name':MAP_NAMES.get(mid,row['name']),'type':row['type'],
                 'phase':RAID_PHASE.get(mid,0) if mid in RAID_PHASE or mid in (0,1) or row['type'] in (1,3) else None}
            for mid,row in maps.items() if not row['hidden']}


class Sources:
    def __init__(self, database):
        c=sqlite3.connect(f'file:{Path(database).resolve().as_posix()}?mode=ro',uri=True)
        c.row_factory=sqlite3.Row
        self.maps={r['id']:dict(r) for r in c.execute('select id,name,type,hidden from maps')}
        self.areas={r['entry']:(r['map_id'],r['zone_id']) for r in c.execute('select entry,map_id,zone_id from areas')}
        for r in c.execute('select areaid,mapid from zones'): self.areas[r['areaid']]=(r['mapid'],0)
        self.items={r['entry']:dict(r) for r in c.execute('select * from items')}
        self.creatures={r['entry']:dict(r) for r in c.execute('select entry,zone,hidden,vendor_id from creatures')}
        self.npc_maps=defaultdict(set); self.object_maps=defaultdict(set)
        for r in c.execute('select entry,map from creature_instance'): self.npc_maps[r['entry']].add(r['map'])
        for r in c.execute('select kind,id,map from spawn_points'):
            (self.npc_maps if r['kind']=='c' else self.object_maps)[r['id']].add(r['map'])
        self.routes=defaultdict(list); self.categories=defaultdict(set)
        for r in c.execute('select item,source from item_sources'): self.categories[r['item']].add(r['source'])
        for r in c.execute('select src,owner,item from drops where chance>0'):
            self.routes[r['item']].append((r['src'],r['owner']))
        self.quests={r['entry']:dict(r) for r in c.execute('select entry,zone,prevquest from quests')}
        self.quest_maps=defaultdict(set); self.quest_items=defaultdict(list); self.quest_npcs=defaultdict(set)
        for r in c.execute('select quest,zone from quest_dungeon'):
            if r['zone'] in self.areas: self.quest_maps[r['quest']].add(self.areas[r['zone']][0])
        for r in c.execute('select quest,id from creature_quest_start'): self.quest_npcs[r['quest']].add(r['id'])
        for r in c.execute('select quest,item,role from quest_item'):
            if r['role'] in ('reward','choice'): self.routes[r['item']].append(('quest',r['quest']))
            elif r['role']=='req': self.quest_items[r['quest']].append(r['item'])
        for r in c.execute('select entry,item from npc_vendor'): self.routes[r['item']].append(('vendor',r['entry']))
        templates=defaultdict(set)
        for npc,row in self.creatures.items():
            if row['vendor_id']: templates[row['vendor_id']].add(npc)
        for r in c.execute('select entry,item from npc_vendor_template'):
            for npc in templates[r['entry']]: self.routes[r['item']].append(('vendor',npc))
        self.spell_sources=defaultdict(list); self.reagents=defaultdict(list)
        for r in c.execute('select spell,item from spell_creates'): self.routes[r['item']].append(('craft',r['spell']))
        for r in c.execute('select spell,item from spell_taught_item'): self.spell_sources[r['spell']].append(('recipe',r['item']))
        for r in c.execute('select spell,npc from spell_trainer'): self.spell_sources[r['spell']].append(('trainer',r['npc']))
        for r in c.execute('select spell,trainer,recipe_item,auto from craft_source'):
            if r['recipe_item']: self.spell_sources[r['spell']].append(('recipe',r['recipe_item']))
            if r['auto']: self.spell_sources[r['spell']].append(('profession',0))
            elif r['trainer'] and not any(kind=='trainer' for kind,_ in self.spell_sources[r['spell']]):
                self.spell_sources[r['spell']].append(('unlocatedTrainer',0))
        for r in c.execute('select spell,item from spell_reagent'): self.reagents[r['spell']].append(r['item'])
        self.application_items=defaultdict(set); self.disenchant_items=defaultdict(set)
        for item,row in self.items.items():
            if row['hidden']: continue
            if row['disenchant_id']: self.disenchant_items[row['disenchant_id']].add(item)
            for n in range(1,6):
                if row['spellid_'+str(n)] and row['spelltrigger_'+str(n)]==0:
                    self.application_items[row['spellid_'+str(n)]].add(item)
        self.cache={}; self.busy=set()
        c.close()

    @staticmethod
    def unknown(): return {'p':None,'l':0,'u':True,'z':set(),'r':0}

    def location(self, maps):
        phases=[]; unknown=False; zones=set()
        for mid in sorted(maps):
            row=self.maps.get(mid)
            if not row or row['hidden']: unknown=True; continue
            zones.add(mid)
            if mid in RAID_PHASE: phases.append(RAID_PHASE[mid])
            elif mid in (0,1) or row['type'] in (1,3): phases.append(0)
            else: unknown=True
        return {'p':min(phases) if phases else None,'l':min(phases) if phases and not unknown else 0,'u':unknown or not phases,'z':zones,'r':1}

    def npc(self,npc):
        row=self.creatures.get(npc)
        if not row or row['hidden']: return self.unknown()
        maps=self.npc_maps.get(npc,set())
        if not maps and row['zone'] in self.areas: maps={self.areas[row['zone']][0]}
        return self.location(maps)

    @staticmethod
    def any(results):
        results=list(results); ps=[r['p'] for r in results if r['p'] is not None]
        return {'p':min(ps) if ps else None,'l':min((r.get('l',0) for r in results),default=0),'u':not results or any(r['u'] for r in results),'z':set().union(*(r['z'] for r in results)) if results else set(),'r':len(results)}

    @staticmethod
    def required(results):
        results=list(results)
        # Every dependency is necessary. An unresolved dependency cannot certify a route.
        ps=[r['p'] for r in results if r['p'] is not None]
        return {'p':None if any(r['p'] is None for r in results) else max(ps,default=0),
                'l':max((r.get('l',0) for r in results),default=0),'u':any(r['u'] for r in results),'z':set().union(*(r['z'] for r in results)) if results else set(),'r':1}

    def quest(self,qid):
        key=('quest',qid)
        if key in self.cache: return self.cache[key]
        if key in self.busy: return self.unknown()
        self.busy.add(key); q=self.quests.get(qid)
        if not q: result=self.unknown()
        else:
            maps=set(self.quest_maps.get(qid,set()))
            if not maps and q['zone'] in self.areas: maps.add(self.areas[q['zone']][0])
            base=self.location(maps) if maps else self.any(self.npc(n) for n in sorted(self.quest_npcs.get(qid,set())))
            dependencies=[base]+[self.item(it) for it in self.quest_items.get(qid,[]) if it in self.items]
            if q['prevquest'] and q['prevquest']>0: dependencies.append(self.quest(q['prevquest']))
            result=self.required(dependencies)
        self.busy.remove(key); self.cache[key]=result; return result

    def spell(self,sid):
        key=('spell',sid)
        if key in self.cache: return self.cache[key]
        if key in self.busy: return self.unknown()
        self.busy.add(key); routes=[]
        for kind,owner in sorted(set(self.spell_sources.get(sid,[]))):
            if kind=='recipe': routes.append(self.item(owner))
            elif kind=='trainer': routes.append(self.npc(owner))
            elif kind=='profession': routes.append({'p':0,'l':0,'u':False,'z':set(),'r':1})
            else: routes.append(self.unknown())
        learning=self.any(routes)
        # Required materials can impose a later phase too. Keep learning locations for
        # raid filters rather than misclassifying an enchant as a material's raid drop.
        result=self.required([learning]+[self.item(i) for i in self.reagents.get(sid,[])])
        result['z']=learning['z']
        self.busy.remove(key); self.cache[key]=result; return result

    def item(self,iid):
        key=('item',iid)
        if key in self.cache: return self.cache[key]
        if key in self.busy: return self.unknown()
        row=self.items.get(iid)
        if not row: return self.unknown()
        self.busy.add(key); routes=[]; covered=set()
        for kind,owner in sorted(set(self.routes.get(iid,[]))):
            if kind in ('c','p','s','vendor'):
                routes.append(self.npc(owner)); covered.add({'c':'drop','p':'pick','s':'skin','vendor':'vendor'}[kind])
            elif kind=='o': routes.append(self.location(self.object_maps.get(owner,set()))); covered.add('object')
            elif kind=='i': routes.append(self.item(owner)); covered.add('container')
            elif kind=='e': routes.append(self.any(self.item(it) for it in sorted(self.disenchant_items.get(owner,set())))); covered.add('disenchant')
            elif kind=='quest': routes.append(self.quest(owner)); covered.add('quest')
            elif kind=='craft': routes.append(self.spell(owner)); covered.add('crafted')
            else: routes.append(self.unknown())
        result=self.any(routes)
        cats=self.categories[iid]-{'unobtainable','pvp'}
        if 'drop' in covered: covered.add('worlddrop')
        if cats-covered: result['u']=True; result['l']=0
        # Honor enum5 is Private(rank1); enum17 is FieldMarshal(rank13).
        rank=max(0,int(row['required_honor_rank'] or 0)-4)
        rank_phase=HONOR_PHASE.get(rank,0)
        if result['p'] is not None: result['p']=max(result['p'],rank_phase)
        result['l']=max(result.get('l',0),rank_phase)
        if rank: result['h']=rank
        elif 'pvp' in self.categories[iid]:
            # A PvP vendor relation without an explicit rank does not prove that
            # honor/season restrictions have been restored in this server profile.
            result['p']=None; result['u']=True
        self.busy.remove(key); self.cache[key]=result; return result


def compact(r):
    out={'u':r['u'],'z':sorted(r['z']),'r':r['r']}
    if r['p'] is not None: out['p']=r['p']
    if r.get('h'): out['h']=r['h']
    if r.get('l',0)>0: out['l']=r['l']
    return out


def generate(database,root=ROOT):
    source=Sources(database)
    catalog=set()
    for path in (root/'Data/AshenDB/Data/Items').glob('*.lua'):
        catalog.update(map(int,re.findall(r'^I\[(\d+)\]',path.read_text(encoding='utf-8'),re.M)))
    enchants={int(eid):int(spell) for eid,spell in re.findall(r'^\s*\[(\d+)\]=\{[^\n]*?spell=(\d+)',(root/'Data/Enchants.lua').read_text(encoding='utf-8'),re.M)}
    records={iid:compact(source.item(iid)) for iid in sorted(catalog) if iid in source.items}
    enchant_records={}
    for eid,sid in sorted(enchants.items()):
        applying=sorted(source.application_items.get(sid,set()))
        routes=[source.item(iid) for iid in applying]
        if source.spell_sources.get(sid): routes.append(source.spell(sid))
        record=compact(source.any(routes)); record['spell']=sid
        if applying: record['items']=applying
        recipes=sorted({owner for kind,owner in source.spell_sources.get(sid,[]) if kind=='recipe'})
        trainers=sorted({owner for kind,owner in source.spell_sources.get(sid,[]) if kind=='trainer'})
        if recipes: record['recipes']=recipes
        if trainers: record['trainers']=trainers
        enchant_records[eid]=record
    meta={'database':'Tortoise-WoW','snapshot':Path(database).stem.replace('tortoise-',''),
          'sha256':hashlib.sha256(Path(database).read_bytes()).hexdigest(),'profileChecked':'2026-11-10',
          'itemCount':len(records),'enchantCount':len(enchant_records),'source':'https://github.com/Xian55/tortoise-db-viewer'}
    locations=location_records(source.maps)
    lines=['-- Generated complete acquisition summaries. See docs/content-sources.md; do not edit by hand.',
           'AshenBuildsContentSources={meta='+lua(meta)+',locations='+lua(locations)+',items={},enchants={}}',
           'local I=AshenBuildsContentSources.items']
    lines.extend('I['+str(iid)+']='+lua(record) for iid,record in records.items())
    lines.append('local E=AshenBuildsContentSources.enchants')
    lines.extend('E['+str(eid)+']='+lua(record) for eid,record in enchant_records.items())
    return '\n'.join(lines)+'\n',records,enchant_records


def main():
    p=argparse.ArgumentParser(description=__doc__); p.add_argument('database',type=Path); p.add_argument('--check',action='store_true'); args=p.parse_args()
    text,items,enchants=generate(args.database); path=ROOT/'Data/ContentSources.lua'
    if args.check:
        if not path.exists() or path.read_text(encoding='utf-8')!=text: raise SystemExit('ContentSources.lua differs from generated source')
    else: path.write_text(text,encoding='utf-8',newline='\n')
    for label,records in (('items',items),('enchants',enchants)):
        counts={'open':0,'future':0,'unknown':0}
        for r in records.values():
            status='open' if r.get('p',99)<=2 else ('future' if r.get('l',0)>2 else 'unknown')
            counts[status]+=1
        print(label,len(records),counts)

if __name__=='__main__': main()

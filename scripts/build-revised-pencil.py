"""Convert our browser-rendered PDF pages to editable Pencil specifications.

No .pen file is read or written. The JSON is applied through Pencil execute.
Text and vector objects remain native; original bitmap assets stay separate.
"""
import collections
import argparse
import importlib.util
import io
import json
import shutil
from pathlib import Path

import pymupdf
from PIL import Image

root = Path(__file__).resolve().parents[1]
captures = root / '.impeccable/review/research-flow'
output = root / 'designs/revised'
assets = output / 'assets'
assets.mkdir(parents=True, exist_ok=True)
pen_assets = None
spec = importlib.util.spec_from_file_location('original_pdf', root / 'scripts/rebuild-pencil-from-pdf.py')
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
num, color, svg_path = helpers.number, helpers.color, helpers.svg_path
scale = 4 / 3
cases = json.loads((captures / 'cases.json').read_text(encoding='utf-8'))
parser = argparse.ArgumentParser()
parser.add_argument('--scene', choices=[key for key, _ in cases], action='append')
parser.add_argument('--pen-assets', type=Path, default=root/'designs/assets/next-stop/revised')
options = parser.parse_args()
pen_assets = options.pen_assets
pen_assets.mkdir(parents=True, exist_ok=True)
pages = []
combined = pymupdf.open()

for index, (key, title) in enumerate(cases):
    doc = pymupdf.open(captures / (key + '.pdf'))
    combined.insert_pdf(doc)
    if options.scene and key not in options.scene:
        continue
    page = doc[0]
    operations = []
    for trace in page.get_texttrace():
        if trace['type'] != 0:
            continue
        rows = collections.defaultdict(list)
        for char in trace['chars']:
            rows[round(char[2][1], 2)].append(char)
        for baseline, chars in rows.items():
            chars.sort(key=lambda c: c[2][0])
            content = ''.join(chr(c[0]) for c in chars)
            if not content.strip():
                continue
            size = trace['size'] * scale
            node = {'type': 'text', 'name': content[:70], 'content': content,
                    'x': num(min(c[2][0] for c in chars) * scale),
                    'y': num(baseline * scale - size * .88),
                    'fontFamily': 'Noto Sans KR', 'fontWeight': '700' if 'Bold' in trace['font'] else '400',
                    'fontSize': num(size), 'lineHeight': 1.0,
                    'fill': color(trace['color'], trace['opacity']),
                    'metadata': {'type': 'editable-text', 'scene': key}}
            operations.append((trace['seqno'], node))
    mask_sequences = set()
    groups = []
    for drawing in page.get_drawings(extended=True):
        level = drawing['level']
        groups = [g for g in groups if g['level'] < level]
        if drawing['type'] == 'group':
            groups.append(drawing)
            continue
        if drawing['type'] == 'clip':
            continue
        for group in groups:
            if group['opacity'] >= .999 or not drawing.get('fill') or min(drawing['fill']) < .95:
                continue
            box, frame = drawing['rect'], group['rect']
            if abs(box.width-frame.width) < 2 and abs(box.height-frame.height) < 2:
                mask_sequences.add(drawing['seqno'])
                if not group.get('border_created'):
                    group['border_created'] = True
                    operations.append((drawing['seqno'], {'type':'rectangle','name':'기록 구분선',
                        'x':num(frame.x0*scale),'y':num(frame.y0*scale),
                        'width':num(frame.width*scale),'height':num(frame.height*scale),
                        'cornerRadius':16,'fill':'#00000000','stroke':color((1,1,1),group['opacity']),
                        'strokeWidth':1,'strokeAlignment':'inner','metadata':{'type':'editable-vector','scene':key}}))
    for drawing in page.get_drawings():
        if drawing['seqno'] in mask_sequences:
            continue
        box = drawing['rect']
        stroke_width = drawing.get('width') or 0
        if box.width < .01 or box.height < .01:
            box = box + (-max(.5, stroke_width/2), -max(.5, stroke_width/2), max(.5, stroke_width/2), max(.5, stroke_width/2))
        clipped = box & pymupdf.Rect(0,0,402/scale,874/scale)
        if clipped.is_empty:
            continue
        node = {'type': 'path', 'name': '벡터 · '+title,
                'x': num(clipped.x0*scale), 'y': num(clipped.y0*scale),
                'width': num(clipped.width*scale), 'height': num(clipped.height*scale),
                'geometry': svg_path(drawing),
                'viewBox': [num(v) for v in (clipped.x0, clipped.y0, clipped.width, clipped.height)],
                'fill': color(drawing['fill'], drawing['fill_opacity']) if drawing.get('fill') is not None else '#00000000',
                'fillRule': 'evenodd' if drawing['even_odd'] else 'nonzero',
                'metadata': {'type': 'editable-vector', 'scene': key}}
        if drawing.get('color') is not None:
            node.update(stroke=color(drawing['color'], drawing.get('stroke_opacity') or 1), strokeWidth=num(stroke_width*scale))
        operations.append((drawing['seqno'], node))
    image_sequences = [i for i, item in enumerate(page.get_bboxlog()) if item[0] == 'fill-image']
    for image_index, (seq, info) in enumerate(zip(image_sequences, page.get_image_info(xrefs=True))):
        clipped = pymupdf.Rect(info['bbox']) & pymupdf.Rect(0,0,402/scale,874/scale)
        if clipped.is_empty or not info['xref']:
            continue
        extracted = doc.extract_image(info['xref'])
        bitmap = Image.open(io.BytesIO(extracted['image'])).convert('RGBA')
        if extracted.get('smask'):
            mask = Image.open(io.BytesIO(doc.extract_image(extracted['smask'])['image'])).convert('L')
            bitmap.putalpha(mask.resize(bitmap.size))
        a,b,c,d,e,f = info['transform']
        determinant = a*d-b*c
        if abs(determinant) < .00001:
            continue
        iw,ih = bitmap.size
        # Render only this source bitmap through its original affine transform.
        coeff = (iw*d/determinant/scale, -iw*c/determinant/scale,
                 iw*(d*(clipped.x0-e)-c*(clipped.y0-f))/determinant,
                 -ih*b/determinant/scale, ih*a/determinant/scale,
                 ih*(-b*(clipped.x0-e)+a*(clipped.y0-f))/determinant)
        transformed = bitmap.transform((max(1,round(clipped.width*scale)),max(1,round(clipped.height*scale))), Image.Transform.AFFINE, coeff, Image.Resampling.BICUBIC)
        filename = f'{key}-image-{image_index}-fm-review-v2.png'
        transformed.save(assets/filename)
        shutil.copy2(assets/filename, pen_assets/filename)
        node = {'type':'rectangle','name':'이미지 · '+title,'x':num(clipped.x0*scale),'y':num(clipped.y0*scale),
                'width':num(clipped.width*scale),'height':num(clipped.height*scale),
                'fill':{'type':'image','url':'./assets/next-stop/revised/'+filename,'mode':'stretch'},
                'metadata':{'type':'source-bitmap','scene':key}}
        operations.append((seq,node))
    operations.sort(key=lambda op:op[0])
    children = [node for _,node in operations]
    stats = dict(collections.Counter(node['type'] for node in children))
    # Keep card artwork as separate editable bitmap/vector/text layers, clipped
    # together at the physical card edge. PDF image bboxes omit its clip mask.
    region_file = captures/'card-regions.json'
    regions = json.loads(region_file.read_text(encoding='utf-8')).get(key, []) if region_file.exists() else []
    for region_index, region in enumerate(regions):
        x,y,w,h = (region[prop] for prop in ['x','y','width','height'])
        members = []
        for index,node in enumerate(children):
            nx,ny = node.get('x',0),node.get('y',0)
            nw,nh = node.get('width',0),node.get('height',node.get('fontSize',0)*1.3)
            if not isinstance(nw,(int,float)) or not isinstance(nh,(int,float)):
                continue
            inside = x-2 <= nx+nw/2 <= x+w+2 and y-2 <= ny+nh/2 <= y+h+2
            fits = nw <= w+4 and nh <= h+4
            bitmap = node.get('metadata',{}).get('type') == 'source-bitmap' and not (nw >= 390 and nh >= 800)
            if inside and (fits or bitmap):
                members.append(index)
        if not members:
            continue
        nested = []
        for index in members:
            child = children[index].copy()
            child['x'],child['y'] = num(child.get('x',0)-x),num(child.get('y',0)-y)
            nested.append(child)
        frame = {'type':'frame','name':'카드 캔버스 · 고정 IC 칩 · '+title,
                 'x':num(x),'y':num(y),'width':num(w),'height':num(h),
                 'layout':'none','clip':True,'cornerRadius':region['radius'],
                 'children':nested,'metadata':{'type':'editable-card-canvas','scene':key}}
        first = members[0]
        children = [frame if index==first else node for index,node in enumerate(children) if index==first or index not in members]
    pages.append({'scene':key,'title':title,'width':402,'height':874,'children':children,'stats':stats})
    shutil.copy2(captures/(key+'.png'),output/(key+'.png'))

if options.scene:
    prior = json.loads((output/'pencil-layers.json').read_text(encoding='utf-8'))
    changes = {page['scene']: page for page in pages}
    prior_by_scene = {page['scene']: page for page in prior}
    pages = [changes.get(key, prior_by_scene.get(key)) for key, _ in cases]
    if any(page is None for page in pages):
        raise ValueError('Capture every new scene before generating Pencil layers')
combined.save(output/'next-stop-revised.pdf')
(output/'pencil-layers.json').write_text(json.dumps(pages,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
print(json.dumps({'screens':len(pages),'nativeText':sum(p['stats'].get('text',0) for p in pages),'nativeVectors':sum(p['stats'].get('path',0) for p in pages)},ensure_ascii=False))

"""Recover editable Pencil layer specifications from the original vector PDF.

The script never reads or writes .pen files. Its JSON output is inserted through
Pencil's execute API. Raster photographs remain separate image layers.
"""

import argparse
import collections
import json
import math
import re
from pathlib import Path

import pymupdf
from PIL import Image


def number(value):
    return round(float(value), 4)


def color(rgb, opacity=1):
    values = [max(0, min(255, round(c * 255))) for c in rgb]
    result = "#" + "".join(f"{c:02X}" for c in values)
    return result if opacity >= 0.999 else result + f"{round(opacity * 255):02X}"


def svg_path(drawing):
    commands = []
    end = None

    def point(p):
        return f"{number(p.x)} {number(p.y)}"

    for item in drawing["items"]:
        kind = item[0]
        if kind in ("l", "c"):
            if end is None or abs(end.x - item[1].x) + abs(end.y - item[1].y) > 0.005:
                commands.append("M " + point(item[1]))
            if kind == "l":
                commands.append("L " + point(item[2]))
                end = item[2]
            else:
                commands.append("C " + " ".join(point(p) for p in item[2:]))
                end = item[4]
        elif kind == "re":
            rect, orientation = item[1:]
            points = [rect.tl, rect.tr, rect.br, rect.bl]
            if orientation < 0:
                points.reverse()
            commands.append("M " + point(points[0]))
            commands.extend("L " + point(p) for p in points[1:])
            commands.append("Z")
            end = None
        elif kind == "qu":
            quad = item[1]
            points = [quad.ul, quad.ur, quad.lr, quad.ll]
            commands.append("M " + point(points[0]))
            commands.extend("L " + point(p) for p in points[1:])
            commands.append("Z")
            end = None
        else:
            raise ValueError(f"Unsupported drawing segment: {kind}")
    if drawing.get("closePath"):
        commands.append("Z")
    return " ".join(commands)


def rectangle_radius(drawing):
    items = drawing["items"]
    box = drawing["rect"]
    if len(items) == 1 and items[0][0] == "re":
        return 0
    if not 25 <= len(items) <= 40:
        return None
    previous = None
    for item in items:
        if item[0] not in ("l", "c"):
            return None
        if previous is not None and abs(previous.x-item[1].x)+abs(previous.y-item[1].y) > 0.01:
            return None
        previous = item[-1]
    radii = []
    sides = set()
    for item in items:
        if item[0] != "l":
            continue
        a, b = item[1:]
        if abs(a.x - b.x) < 0.005 and min(abs(a.x-box.x0), abs(a.x-box.x1)) < 0.005:
            sides.add("l" if abs(a.x-box.x0) < 0.005 else "r")
            radii.extend([min(a.y,b.y)-box.y0, box.y1-max(a.y,b.y)])
        elif abs(a.y - b.y) < 0.005 and min(abs(a.y-box.y0), abs(a.y-box.y1)) < 0.005:
            sides.add("t" if abs(a.y-box.y0) < 0.005 else "b")
            radii.extend([min(a.x,b.x)-box.x0, box.x1-max(a.x,b.x)])
    if len(sides) >= 2 and radii and max(radii)-min(radii) < 0.1:
        return number(sum(radii)/len(radii))
    return None


def font_style(document, font):
    match = re.search(r"\((\d+) 0 R\)", font)
    if not match:
        return "Noto Sans KR", "400"
    descriptor = document.xref_get_key(int(match[1]), "FontDescriptor")[1]
    xref = int(descriptor.split()[0])
    family = document.xref_get_key(xref, "FontFamily")[1]
    weight = document.xref_get_key(xref, "FontWeight")[1]
    return family, weight


def contains(outer, inner, tolerance=1.1):
    return outer[0]-tolerance <= inner[0] and outer[1]-tolerance <= inner[1] and outer[2]+tolerance >= inner[2] and outer[3]+tolerance >= inner[3]


def build_page(document, index, asset_dir):
    page = document[index]
    drawings = page.get_drawings()
    draws_by_seq = {d["seqno"]: d for d in drawings}
    operations = []
    traces = collections.defaultdict(list)
    for trace in page.get_texttrace():
        traces[trace["seqno"]].append(trace)
    removed_outlines = set()
    for seq, runs in traces.items():
        previous = max((s for s in draws_by_seq if s < seq), default=None)
        if previous is None:
            raise ValueError(f"Page {index+1}: missing text outline")
        outline = draws_by_seq[previous]
        removed_outlines.add(previous)
        lines = collections.defaultdict(list)
        for run in runs:
            family, weight = font_style(document, run["font"])
            for char in run["chars"]:
                key = (round(char[2][1], 2), round(run["size"], 3), family, weight)
                lines[key].append(char)
        for (baseline, size, family, weight), chars in lines.items():
            chars.sort(key=lambda c: c[2][0])
            content = "".join(chr(c[0]) for c in chars)
            content = content.replace("\ue092", ":").replace("\ue1d7", "→")
            if index == 36:
                content = content.replace("AJAJA", "A0A0A")
            if index == 8:
                if len(content) == 2 and content[0] in "KLMN" and content[1] in "ABCD":
                    content = str("KLMN".index(content[0])+1)+content[1]
                content = content.replace("JLA", "02A")
            if index == 10:
                content = content.replace("KM.L", "13.2")
            if not content.strip():
                continue
            x = min(c[2][0] for c in chars)
            end = max(c[3][2] for c in chars)
            y = baseline-size*0.88
            node = {
                "type": "text", "name": content.replace("\n", " ")[:70],
                "x": number(x), "y": number(y),
                "content": content, "fontFamily": family, "fontWeight": weight,
                "fontSize": size, "lineHeight": 1.0,
                "fill": color(outline["fill"], outline["fill_opacity"]),
                "metadata": {"type": "editable-text", "pdfBaseline": baseline, "sourcePage": index+1},
            }
            operations.append({"seq": seq, "node": node, "bounds": [x, y, end, y+size]})

    for drawing in drawings:
        if drawing["seqno"] in removed_outlines or drawing.get("fill_opacity", 1) <= 0:
            continue
        box = drawing["rect"]
        if box.width < 0.001 or box.height < 0.001:
            continue
        radius = rectangle_radius(drawing)
        node = {
            "type": "rectangle" if radius is not None else "path",
            "name": "화면 배경" if box.width >= page.rect.width-1 and box.height >= page.rect.height-1 else "벡터 도형",
            "x": number(box.x0), "y": number(box.y0),
            "width": number(box.width), "height": number(box.height),
            "fill": color(drawing["fill"], drawing["fill_opacity"]),
            "metadata": {"type": "editable-vector", "sourcePage": index+1, "paintOrder": drawing["seqno"]},
        }
        if radius is not None:
            node["cornerRadius"] = radius
        else:
            node.update({"geometry": svg_path(drawing), "viewBox": [number(v) for v in (box.x0,box.y0,box.width,box.height)], "fillRule": "evenodd" if drawing["even_odd"] else "nonzero"})
            clipped = box & page.rect
            if clipped != box and not clipped.is_empty:
                node.update({"x":number(clipped.x0), "y":number(clipped.y0), "width":number(clipped.width), "height":number(clipped.height), "viewBox":[number(v) for v in (clipped.x0,clipped.y0,clipped.width,clipped.height)]})
                box = clipped
        candidate = radius is not None and box.width >= 70 and box.height >= 28 and box.width < page.rect.width-1 and box.height < page.rect.height-1 and drawing["fill_opacity"] >= .99
        if candidate:
            node["name"] = "버튼 배경" if box.height <= 65 else "패널 배경"
        operations.append({"seq": drawing["seqno"], "node": node, "bounds": list(box), "container": candidate})

    image_sequences = [i for i, item in enumerate(page.get_bboxlog()) if item[0] == "fill-image"]
    for sequence, info in zip(image_sequences, page.get_image_info(xrefs=True)):
        image = pymupdf.Pixmap(document, info["xref"])
        extracted = Image.frombytes("RGB", (image.width, image.height), image.samples)
        box = pymupdf.Rect(info["bbox"])
        clipped = box & page.rect
        crop = ((clipped.x0-box.x0)/box.width*image.width, (clipped.y0-box.y0)/box.height*image.height, (clipped.x1-box.x0)/box.width*image.width, (clipped.y1-box.y0)/box.height*image.height)
        extracted = extracted.crop(tuple(round(v) for v in crop))
        file_name = f"image-{info['xref']}-page-{index+1:02d}.png"
        extracted.save(asset_dir/file_name)
        node = {"type": "rectangle", "name": "지도 사진" if clipped.height > 800 else "승차권 이미지", "x": number(clipped.x0), "y": number(clipped.y0), "width": number(clipped.width), "height": number(clipped.height), "fill": {"type": "image", "url": "./assets/next-stop/editable/"+file_name, "mode": "stretch"}, "metadata": {"type": "photo-asset", "sourcePage": index+1}}
        operations.append({"seq": sequence, "node": node, "bounds": list(clipped)})

    operations.sort(key=lambda op: (op["seq"], op["bounds"][1], op["bounds"][0]))
    candidates = [op for op in operations if op.get("container")]
    for op in operations:
        eligible = [c for c in candidates if c is not op and c["seq"] < op["seq"] and contains(c["bounds"], op["bounds"]) and (not op.get("container") or (c["bounds"][2]-c["bounds"][0])*(c["bounds"][3]-c["bounds"][1]) > (op["bounds"][2]-op["bounds"][0])*(op["bounds"][3]-op["bounds"][1])+2)]
        op["parent"] = min(eligible, key=lambda c:(c["bounds"][2]-c["bounds"][0])*(c["bounds"][3]-c["bounds"][1])) if eligible else None
        if op.get("container"):
            box = op["bounds"]
            op["wrapper"] = {"type":"frame", "name":"버튼" if box[3]-box[1] <= 65 else "패널", "x":number(box[0]), "y":number(box[1]), "width":number(box[2]-box[0]), "height":number(box[3]-box[1]), "layout":"none", "padding":0, "clip":False, "children":[]}

    root = []
    for op in operations:
        parent = op["parent"]
        destination = parent["wrapper"]["children"] if parent else root
        if op.get("container"):
            wrapper = op["wrapper"]
            if parent:
                wrapper["x"] = number(wrapper["x"]-parent["bounds"][0])
                wrapper["y"] = number(wrapper["y"]-parent["bounds"][1])
            destination.append(wrapper)
            op["node"]["x"] = op["node"]["y"] = 0
            wrapper["children"].insert(0, op["node"])
        else:
            if parent:
                op["node"]["x"] = number(op["node"]["x"]-parent["bounds"][0])
                op["node"]["y"] = number(op["node"]["y"]-parent["bounds"][1])
            destination.append(op["node"])

    def rename(nodes):
        for node in nodes:
            if "children" in node:
                texts = [n["content"] for n in node["children"] if n["type"] == "text"]
                if texts:
                    node["name"] += " · " + texts[0][:45]
                rename(node["children"])
    rename(root)
    def include_borders(nodes):
        for node in nodes:
            children = node.get("children")
            if not children:
                continue
            include_borders(children)
            sized = [child for child in children if "width" in child and "height" in child]
            left = min([0]+[child.get("x",0) for child in sized])
            top = min([0]+[child.get("y",0) for child in sized])
            right = max([node["width"]]+[child.get("x",0)+child["width"] for child in sized])
            bottom = max([node["height"]]+[child.get("y",0)+child["height"] for child in sized])
            node["x"] = number(node["x"]+left)
            node["y"] = number(node["y"]+top)
            node["width"] = number(right-left)
            node["height"] = number(bottom-top)
            for child in children:
                child["x"] = number(child.get("x",0)-left)
                child["y"] = number(child.get("y",0)-top)
    include_borders(root)
    stats = collections.Counter(op["node"]["type"] for op in operations)
    return {"page":index+1, "width":page.rect.width, "height":page.rect.height, "children":root, "stats":dict(stats)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", type=Path, default=Path("designs/final/next-stop-final.pdf"))
    parser.add_argument("--output", type=Path, default=Path("designs/editable"))
    parser.add_argument("--asset-dir", type=Path, required=True)
    options = parser.parse_args()
    options.output.mkdir(parents=True, exist_ok=True)
    options.asset_dir.mkdir(parents=True, exist_ok=True)
    document = pymupdf.open(options.pdf)
    pages = [build_page(document, i, options.asset_dir) for i in range(len(document))]
    (options.output/"pencil-layers.json").write_text(json.dumps(pages, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    for page in pages:
        (options.output/f"page-{page['page']:02d}.json").write_text(json.dumps(page, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps({"pages":len(pages), "layers":{key:sum(p["stats"].get(key,0) for p in pages) for key in ("text","path","rectangle")}}, ensure_ascii=False))


if __name__ == "__main__":
    main()

// Produce a Pencil MCP execute snippet; never read or write encrypted .pen files.
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..');
const snapshot=JSON.parse(fs.readFileSync(path.join(root,'designs/editable/document-snapshot.json'),'utf8'));
const output=process.argv[2]||path.join(root,'.impeccable/review/import-focus-mate-pen.js');
const logic=`
if(Get(n=>n.id,{depth:0}).length)throw Error('Open an empty Pen canvas before importing this snapshot.');
const idMap={},pending=[],created=[];
function clean(node,parent){const copy={...node};delete copy.id;if(copy.children){copy.children=[];node.children.forEach((child,index)=>{if(child.type==='ref')pending.push({parent:node.id,index,node:child});else copy.children.push(clean(child,node.id));});}return copy;}
function mapNodes(oldNode,newNode){idMap[oldNode.id]=newNode.id;const oldChildren=(oldNode.children||[]).filter(c=>c.type!=='ref'),newChildren=newNode.children||[];if(oldChildren.length!==newChildren.length)throw Error('Native child count mismatch: '+oldNode.name);oldChildren.forEach((child,index)=>mapNodes(child,newChildren[index]));}
if(snapshot.variables?.variables)SetVariables(snapshot.variables.variables);
for(const node of snapshot.nodes){const data=clean(node);data.placeholder=true;const id=Insert(document,data);mapNodes(node,Get(id,{depth:50}));created.push(id);}
for(const item of pending){const data={...item.node};delete data.id;delete data.children;data.ref=idMap[data.ref];if(!data.ref)throw Error('Missing component reference: '+item.node.ref);if(data.descendants){const mapped={};for(const [key,value]of Object.entries(data.descendants)){mapped[key.split('/').map(id=>idMap[id]||id).join('/')]=value;}data.descendants=mapped;}const id=Insert(idMap[item.parent],data);Move(id,idMap[item.parent],item.index);idMap[item.node.id]=id;}
for(const id of created)Update(id,{placeholder:false});
Print({roots:created.length,instances:pending.length,ids:idMap});
TakeScreenshot(snapshot.nodes.filter(n=>n.name==='개선 R40 · 카드 꾸미기 · 사진 배치'||n.name==='개선 R12 · 승차 태그 완료').map(n=>idMap[n.id]));
`;
fs.mkdirSync(path.dirname(output),{recursive:true});
fs.writeFileSync(output,'const snapshot='+JSON.stringify(snapshot)+';'+logic);
console.log(JSON.stringify({snippet:output,roots:snapshot.nodes.length}));

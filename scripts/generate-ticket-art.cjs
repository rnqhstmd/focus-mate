// Generate the ticket texture: a dot-matrix of Seoul's 25 districts with the Han River left open.
// Boundary: scripts/data/seoul-municipalities-kostat-2013.json (southkorea/seoul-maps, Apache-2.0).
// Deterministic output so the art does not change between runs.
const fs=require('node:fs'),path=require('node:path');
const out=path.resolve(__dirname,'../designs/final/assets/bus');
const geo=JSON.parse(fs.readFileSync(path.join(__dirname,'data/seoul-municipalities-kostat-2013.json'),'utf8'));
let seed=20261013;const rand=()=>(seed=(seed*1103515245+12345)%2147483648)/2147483648;

const rings=geo.features.flatMap(f=>f.geometry.type==='Polygon'?[f.geometry.coordinates[0]]:f.geometry.coordinates.map(p=>p[0]));
const inside=(x,y)=>rings.some(ring=>{let hit=false;for(let i=0,j=ring.length-1;i<ring.length;j=i++){const [xi,yi]=ring[i],[xj,yj]=ring[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)hit=!hit}return hit});
// Han River centerline across Seoul, west to east (approximate, lon/lat).
const river=[[126.79,37.605],[126.83,37.585],[126.86,37.572],[126.89,37.556],[126.91,37.545],[126.93,37.535],[126.95,37.527],[126.97,37.517],[126.99,37.512],[127.01,37.518],[127.025,37.531],[127.045,37.534],[127.065,37.524],[127.085,37.519],[127.10,37.530],[127.115,37.545],[127.135,37.560],[127.16,37.572],[127.19,37.583]];
const segDist=(px,py,[ax,ay],[bx,by])=>{const dx=bx-ax,dy=by-ay,t=Math.max(0,Math.min(1,((px-ax)*dx+(py-ay)*dy)/(dx*dx+dy*dy)));return Math.hypot(px-ax-t*dx,py-ay-t*dy)};
const riverK=river.map(([x,y])=>[x*Math.cos(37.55*Math.PI/180),y]);const riverDist=(x,y)=>Math.min(...riverK.slice(1).map((p,i)=>segDist(x,y,riverK[i],p)));

const W=360,H=230,step=5,dots=[],k=Math.cos(37.55*Math.PI/180);
const lon0=126.755,lon1=127.195,lat0=37.41,lat1=37.72;
const scale=Math.min((W-24)/((lon1-lon0)*k),(H-16)/(lat1-lat0)),ox=(W-(lon1-lon0)*k*scale)/2,oy=(H-(lat1-lat0)*scale)/2;
for(let y=step/2;y<H;y+=step)for(let x=step/2;x<W;x+=step){
 const lon=lon0+(x-ox)/(scale*k),lat=lat1-(y-oy)/scale;
 if(!inside(lon,lat))continue;
 const r=riverDist(lon*k,lat);if(r<0.0068)continue;
 const o=(r<0.011?0.12:0.16+rand()*0.2).toFixed(2);dots.push(`<circle cx="${x}" cy="${y}" r="1.2" fill-opacity="${o}"/>`);
}
fs.writeFileSync(path.join(out,'ticket-dots.svg'),`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" fill="#ffffff">${dots.join('')}</svg>\n`);
console.log(JSON.stringify({dots:dots.length}));

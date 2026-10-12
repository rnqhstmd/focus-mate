const $ = id => document.getElementById(id);
const SVG = 'http://www.w3.org/2000/svg';
const names = ['첫 이용','현재 정류장 홈','출발 정류장 검색','반대편 정류장 확인','시간과 도착지 선택','할 일 입력','태그 선택','태그 만들기와 편집','좌석 선택','소리 선택','승차권과 카드 태그','집중 여행','남은 정류장 상세','일시정지','중도 종료 확인','도착과 하차','집중 기록','기록 상세','태그 관리','설정','지도와 움직임','도착 알림 안내','기록 없는 첫 상태','여행 메모 수정','출발 가능한 버스 없음','검색 결과 없음','지도 로딩','지도 연결 오류','태그 이름 오류','태그 삭제 확인','탑승 성공','집중 중 더보기','앱 정보','진행 중인 여행 복원','알림 권한 꺼짐','할 일 입력 키보드'];
const steps = [{page:1,label:'처음 시작',screens:[1]},{page:3,label:'출발 정류장',screens:[3,4,25,26]},{page:2,label:'버스 선택',screens:[2]},{page:5,label:'시간과 도착지',screens:[5]},{page:6,label:'할 일과 태그',screens:[6,7,8,29,36]},{page:11,label:'카드로 탑승',screens:[9,10,11,31]},{page:12,label:'집중 여행',screens:[12,13,14,15,21,27,28,32,34]},{page:16,label:'도착과 하차',screens:[16]},{page:17,label:'여행 기록',screens:[17,18,19,20,22,23,24,30,33,35]}];
const descriptions = {
  1:['처음 만나는 정류장','앱 속에서 떠나는 집중 여행을 소개합니다. 출발할 정류장과 버스를 고르고, 이번에 집중할 일을 챙깁니다.','출발 정류장 선택을 눌러 시작하세요.'],
  2:['여행은 여기서 시작합니다','현재 정류장과 승차 방향을 확인합니다. 여행을 마치면 도착 정류장이 다음 여행의 출발지가 됩니다.','집중 여행 시작을 눌러 시간을 고르세요.'],
  3:['어디서 출발할까요?','정류장 이름으로 검색하고 방향을 확인합니다. 성수역 또는 서울숲역을 눌러 선택할 수 있습니다.','정류장을 선택하고 하단의 출발 버튼을 누르세요.'],
  4:['반대편 정류장','같은 이름의 정류장도 방향이 다를 수 있습니다. 이동할 방향을 확인한 뒤 출발지를 바꿉니다.','이동하거나 현재 정류장을 유지하세요.'],
  5:['시간이 목적지를 정합니다','시간 눈금과 빠른 선택으로 15분부터 6시간까지 정합니다. 선택한 시간에 맞춰 목적지와 이동량이 바뀝니다.','시간을 고른 뒤 이 여정으로 탑승을 누르세요.'],
  6:['버스에서 할 일 하나','이번 시간에 할 일을 입력합니다. 최근 할 일을 선택하거나 태그를 바꿀 수 있습니다.','할 일을 입력한 뒤 이 할 일로 여행을 누르세요.'],
  7:['나의 시간을 구분합니다','독서·업무·공부 중 태그를 고릅니다. 새 태그도 만들 수 있고 선택한 태그가 승차권에 반영됩니다.','태그를 누르고 하단의 선택 버튼을 누르세요.'],
  8:['태그를 직접 편집합니다','이름, 아이콘, 색과 기본 집중 시간을 바꿉니다. 빈 이름이나 중복 이름에는 오류 화면을 보여줍니다.','이름을 바꾸고 태그 저장을 누르세요.'],
  9:['지도에서 바라보는 시점','좌석은 실제 좌석 예약이 아닌 지도 추적 시점을 고르는 시안입니다. 좌석을 누르면 선택이 바뀝니다.','원하는 자리를 고르고 탑승 준비로 돌아가세요.'],
  10:['여행의 소리를 고릅니다','버스 주행 소리, 빗소리, 소리 없음 중에서 선택합니다. 선택한 소리는 집중 여행 중 반복됩니다.','소리와 음량을 고른 뒤 선택 완료를 누르세요.'],
  11:['카드 한 번으로 탑승','버스, 출발지와 도착지, 집중 시간과 이동량을 최종 확인합니다. 카드 자체가 탑승 버튼입니다.','승차권 카드를 터치하세요.'],
  12:['나를 위한 집중 여행','지도와 함께 남은 시간·정류장·거리를 확인합니다. 30초로 압축한 여정이 진행되며 완료하면 도착 화면으로 넘어갑니다.','일시정지, 경로 상세, 더보기를 눌러볼 수 있습니다.'],
  13:['앞으로의 정류장','다음 정류장부터 목적지까지 남은 경로와 시간을 자세히 봅니다. 상세를 보고 있는 동안에도 집중은 이어집니다.','지도 계속 보기를 눌러 돌아가세요.'],
  14:['잠깐 쉬어가도 됩니다','버스와 남은 시간이 함께 멈춥니다. 다시 이어가거나 이번 여행을 마칠 수 있습니다.','집중 계속하기 또는 이번 여행 종료를 누르세요.'],
  15:['여기까지의 여행','그만두기 전에 한 번 확인합니다. 진행한 시간을 기록하고, 지나온 마지막 정류장에서 다음 여행을 시작합니다.','계속 집중하거나 여기서 여행을 마치세요.'],
  16:['도착, 그리고 다음 정류장','여행 기록을 저장했습니다. 하차 카드를 터치하면 도착지가 현재 정류장으로 바뀌고 홈으로 돌아갑니다.','카드 아무 곳이나 터치해 하차하세요.'],
  17:['작은 집중이 쌓입니다','태그별 시간과 최근 여행을 확인합니다. 새로 완료한 여행은 최근 기록에 반영됩니다.','최근 여행을 눌러 상세와 메모를 확인하세요.'],
  18:['완료한 여행을 돌아봅니다','집중 시간, 출발과 도착, 이동량과 메모를 함께 확인합니다. 이 정류장에서 새 여행도 시작할 수 있습니다.','메모 수정 또는 새 여행을 눌러보세요.'],
  19:['집중 태그 관리','태그를 편집하거나 삭제합니다. 태그를 삭제해도 기존 여행 기록은 남습니다.','태그를 눌러 편집하세요.'],
  20:['나에게 맞는 설정','태그, 소리, 지도 움직임, 도착 알림과 앱 정보를 설정합니다. 아래 여행 탭에서 다시 홈으로 돌아갑니다.','설정 항목을 눌러 세부 화면을 확인하세요.'],
  21:['지도 움직임을 선택합니다','높은 시점에서 따라가기와 고정된 노선 지도를 선택합니다. 동작 줄이기를 켜면 이동 연출을 줄입니다.','원하는 설정을 선택하고 적용하세요.'],
  22:['도착 알림 안내','여행이 끝났을 때 알림을 받는 흐름입니다. 이 브라우저 시연에서는 실제 iOS 권한 창을 열지 않습니다.','허용 또는 나중에를 선택하세요.'],
  23:['아직 여행 기록이 없다면','첫 여행을 시작할 수 있는 빈 기록 상태입니다. 첫 정거장을 채우는 행동을 바로 안내합니다.','첫 여행 시작을 누르세요.'],
  24:['여행을 한 줄로 남깁니다','메모를 직접 수정하고 저장할 수 있습니다. 최대 200자까지 입력할 수 있습니다.','메모를 작성하고 메모 저장을 누르세요.'],
  25:['이 방향의 버스가 없다면','지원하는 다른 정류장을 선택하거나 반대편을 확인하도록 안내합니다.','다른 정류장 선택 또는 반대편 확인을 누르세요.'],
  26:['검색 결과가 없다면','검색어를 짧게 바꾸거나 다른 이름으로 다시 검색하도록 안내합니다.','검색어 다시 입력을 눌러 재검색하세요.'],
  27:['지도를 기다리는 동안','지도 로딩 중에도 집중 시간과 이동 수치는 유지되는 상태입니다.','화면을 누르면 로딩을 마치고 여행으로 돌아갑니다.'],
  28:['지도가 끊겨도 집중은 계속','연결 오류를 보여주고 다시 불러오는 동작을 제공합니다. 타이머와 여행 기록은 유지합니다.','지도 다시 불러오기를 누르세요.'],
  29:['태그 이름을 확인합니다','빈 이름이나 기존 태그와 중복된 이름을 수정하도록 안내합니다.','이름을 수정하고 저장하세요.'],
  30:['태그를 삭제하기 전에','기록은 남고 태그가 없어진다는 점을 확인합니다. 삭제하거나 현재 태그를 유지할 수 있습니다.','태그 유지 또는 태그 삭제를 누르세요.'],
  31:['탑승 완료','카드가 태그되었다는 피드백을 보여준 뒤 집중 화면으로 넘어갑니다.','잠시 기다리거나 바로 집중하기를 누르세요.'],
  32:['필요한 조작만 모았습니다','경로, 소리, 지도 설정과 일시정지를 한곳에서 제공합니다.','원하는 여행 조작을 선택하세요.'],
  33:['앱 정보','여행의 의미와 기기에 저장되는 정보, 지도·노선의 기준을 확인합니다.','오른쪽 위의 뒤로가기로 설정으로 돌아가세요.'],
  34:['진행 중인 여행으로 복귀','앱을 다시 열었을 때 진행 상태를 이어서 보여주는 시안입니다.','집중 화면으로 돌아가기를 누르세요.'],
  35:['알림이 꺼져 있다면','알림 없이도 시간과 기록이 동작함을 안내합니다. 실제 기기 설정은 이 시연에서 열지 않습니다.','이대로 사용하기를 눌러 설정으로 돌아가세요.'],
  36:['할 일 입력 중','키보드가 올라온 상태에서도 입력과 완료 버튼을 사용할 수 있습니다.','할 일을 입력하고 완료를 누르세요.']
};
const story = [1,3,2,5,6,7,11,31,12,14,12,16,2,17];
let pages = [], current = 1, history = [], tourTimer, tagTimer, tourIndex = -1, lastTick = 0, soundReturn = 11, settingsReturn = 20, tagReturn = 11, recordReturn = 18;
let editingNew = false, tagDraft = '', selectedColor = 0, selectedIcon = 0, toastTimer, soundAttempt = 0;
const defaults = () => ({origin:'성수역',destination:'성수대교 북단',direction:'성수동 방향',duration:120,task:'책 한 챕터 읽기',tag:'독서',seat:'2A',sound:'none',volume:.35,progress:0,running:false,paused:false,records:[],memo:'한 챕터를 끝냈다. 다음은 독서 노트.',customTags:[],reduced:matchMedia('(prefers-reduced-motion: reduce)').matches,completed:false});
let state = defaults();
try { const saved = JSON.parse(localStorage.getItem('next-stop-flow-demo-v1')||'null'); if(saved) for(const key of ['records','memo','customTags']) if(saved[key]!==undefined)state[key]=saved[key]; } catch {}
const audio = new Audio(); audio.loop = true;
function persist(){try{localStorage.setItem('next-stop-flow-demo-v1',JSON.stringify({records:state.records,memo:state.memo,customTags:state.customTags}));}catch{}}
function durationLabel(){return state.duration<60?`${state.duration}분`:state.duration%60?`${Math.floor(state.duration/60)}시간 ${state.duration%60}분`:`${state.duration/60}시간`;}
function remaining(){const total=Math.ceil(state.duration*60*(1-state.progress));return total>=3600?`${Math.floor(total/3600)}:${String(Math.floor(total/60)%60).padStart(2,'0')}:${String(total%60).padStart(2,'0')}`:`${Math.floor(total/60)}:${String(total%60).padStart(2,'0')}`;}
function audioFailure(){if(state.sound==='none'||!state.running||state.paused)return;$('phone').querySelector('.audio-notice')?.remove();const notice=document.createElement('div');notice.className='toast audio-notice';notice.setAttribute('role','alert');const message=document.createElement('p');message.textContent='소리가 재생되지 않았어요. 여행은 계속됩니다.';const retry=document.createElement('button');retry.type='button';retry.textContent='다시 재생';retry.setAttribute('aria-label','소리 다시 재생');retry.onclick=()=>{notice.remove();sound();};const silent=document.createElement('button');silent.type='button';silent.textContent='소리 없이 계속';silent.setAttribute('aria-label','소리 없이 계속');silent.onclick=()=>{state.sound='none';++soundAttempt;audio.pause();notice.remove();};notice.append(message,retry,silent);$('phone').append(notice);announcement(message.textContent);}
function sound(){const attempt=++soundAttempt;audio.pause();if(state.sound==='none'||!state.running||state.paused)return;audio.src=`assets/audio/${state.sound==='bus'?'bus-ride':'rain-window'}.wav`;audio.volume=state.volume;audio.play().catch(error=>{if(attempt!==soundAttempt||state.sound==='none'||!state.running||state.paused)return;console.warn('Travel audio playback failed:',error.name,error.message);audioFailure();});}
audio.addEventListener('error',()=>{if(state.sound!=='none'&&state.running&&!state.paused){console.warn('Travel audio file failed:',audio.error?.code);audioFailure();}});
function pauseTour(){clearTimeout(tourTimer);tourIndex=-1;$('tour').querySelector('span').textContent='흐름 재생';$('tour').setAttribute('aria-pressed','false');}
function announcement(message){$('announcement').textContent=message;}
function toast(message){clearTimeout(toastTimer);const old=$('phone').querySelector('.toast');old?.remove();const el=document.createElement('div');el.className='toast';el.textContent=message;$('phone').append(el);announcement(message);toastTimer=setTimeout(()=>el.remove(),3000);}
function complete(interrupted=false){if(state.completed)return;state.completed=true;state.running=false;state.paused=false;audio.pause();const minutes=interrupted?Math.max(1,Math.round(state.duration*state.progress)):state.duration;state.records.unshift({task:state.task,tag:state.tag,minutes,origin:state.origin,destination:interrupted?'뚝섬역':state.destination,memo:'',date:new Date().toISOString()});persist();}
function go(page, options={}){
  if(!pages.length)return;
  clearTimeout(tagTimer); if(!options.tour)pauseTour();
  if(!options.back&&page!==current)history.push(current);
  if(page===14||page===15){state.paused=true;audio.pause();}
  if(page===12&&options.start){state.progress=0;state.running=true;state.completed=false;}
  if(page===12&&options.resume){state.paused=false;state.running=true;}
  if(page===16){state.progress=1;complete();}
  current=page;render();lastTick=performance.now();
  if(page===31){state.running=true;state.paused=false;state.completed=false;state.progress=0;tagTimer=setTimeout(()=>go(12,{start:true,tour:tourIndex>=0}),1100);}
  if(page===12)sound();
  announcement(names[page-1]);
}
function back(){const page=history.pop()||2;go(page,{back:true});}
function home(){state.running=false;state.paused=false;audio.pause();go(2);}
function alight(){state.origin=state.destination;state.destination=state.origin==='성수대교 북단'?'서울숲 입구':'성수대교 북단';home();}
function openSound(from=current){soundReturn=from;go(10);}
function openMap(from=current){settingsReturn=from;go(21);}
function setDuration(minutes){state.duration=minutes;state.destination=minutes<=45?'서울숲 입구':minutes<120?'뚝섬역':'성수대교 북단';render();}
function saveTag(){const value=$('tagInput')?.value.trim()||tagDraft.trim();const existing=['독서','업무','공부',...state.customTags];if(!value||(editingNew&&existing.includes(value))){tagDraft=value;go(29);return;}state.tag=value;tagDraft=value;if(editingNew&&!state.customTags.includes(value))state.customTags.push(value);persist();go(tagReturn===19?19:7);}
function textValue(content,page){
  if(page===2){if(content==='성수역')return state.origin;if(content==='현재 정류장 · 성수역')return `현재 정류장 · ${state.origin}`;if(content==='● 성수동 방향')return `● ${state.direction}`;}
  if([5,6,8,11,12,13,18,29,30,31,36].includes(page)&&content==='독서')return state.tag;
  if([5,11,12,13,27,28].includes(page)&&content==='책 한 챕터 읽기')return state.task;
  if(page===5){if(content==='2')return state.duration>=60?String(Math.floor(state.duration/60)):String(state.duration);if(content==='시간')return state.duration>=60?(state.duration%60?`시간 ${state.duration%60}분`:'시간'):'분';if(content==='성수대교 북단')return state.destination;if(content.startsWith('2014 · 가상 순환'))return `2014 · 가상 순환 / ${Math.max(3,Math.round(state.duration/5))}정류장 · ${(state.duration*.11).toFixed(1)} `;}
  if(page===7&&content==='독서 선택')return `${state.tag} 선택`;
  if(page===9&&content==='02A · ')return `0${state.seat} · `;
  if(page===11){if(content==='2014 · 독서 / 책 한 챕터 읽기')return `2014 · ${state.tag} / ${state.task}`;if(content==='성수역')return state.origin;if(content==='성수대교 북단')return state.destination;if(content==='2시간')return durationLabel();if(content==='24개')return `${Math.max(3,Math.round(state.duration/5))}개`;if(content==='13.2 km')return `${(state.duration*.11).toFixed(1)} km`;}
  if([12,13,14,27,28,34].includes(page)&&/^(1:29:42|18:42)$/.test(content))return remaining();
  if([12,27,28].includes(page)&&['18','4'].includes(content))return String(Math.ceil(state.duration/5*(1-state.progress)));
  if([12,27,28].includes(page)&&['9.9','2.8'].includes(content))return (state.duration*.11*(1-state.progress)).toFixed(1);
  if(page===16){if(content==='성수대교 북단에 도착')return `${state.destination}에 도착`;if(content==='2시간만큼 집중했어요')return `${durationLabel()}만큼 집중했어요`;}
  if(page===17&&state.records.length){const r=state.records[0];if(content==='책 한 챕터 읽기')return r.task;if(content==='독서 · 25분 · 서울숲 입구')return `${r.tag} · ${r.minutes}분 · ${r.destination}`;}
  if(page===18&&state.records.length){const r=state.records[0];if(content==='책 한 챕터 읽기')return r.task;if(content==='독서')return r.tag;if(content==='25 MIN')return `${r.minutes} MIN`;if(content==='성수역 → 서울숲 입구')return `${r.origin} → ${r.destination}`;}
  if(page===18&&content==='한 챕터를 끝냈다. 다음은 독서 노트.')return state.memo;
  if(page===30&&content==='독서 태그를 삭제할까요?')return `${state.tag} 태그를 삭제할까요?`;
  if(page===31&&content==='성수대교 북단까지 · 2시간')return `${state.destination}까지 · ${durationLabel()}`;
  return content;
}
function skipLayer(node,x,y,page){
  if(page===9&&x>=39&&x<=327&&y>=415&&y<=650&&node.width<=54&&node.height<=48)return true;
  if(page===9&&node.type==='text'&&/^[1-4][ABCD]$/.test(node.content))return true;
  if(page===3&&node.type==='text'&&node.content==='성수')return true;
  if(page===6&&node.type==='text'&&node.content==='책 한 챕터 읽기 |')return true;
  if([8,29].includes(page)&&node.type==='text'&&node.content==='독서 |')return true;
  if(page===36&&node.type==='text'&&node.content==='책 한 챕터 읽기 |')return true;
  if(page===24&&node.type==='text'&&['한 챕터를 끝냈다.','다음은 독서 노트. |','22 / 200'].includes(node.content))return true;
  return false;
}
function layer(node,parent,offsetX=0,offsetY=0){
  const x=offsetX+(node.x||0),y=offsetY+(node.y||0);if(skipLayer(node,x,y,current))return;
  let el;
  if(node.type==='frame'){el=document.createElement('div');el.className='layer';el.style.cssText=`left:${node.x||0}px;top:${node.y||0}px;width:${node.width}px;height:${node.height}px;`;for(const child of node.children||[])layer(child,el,x,y);parent.append(el);return;}
  if(node.type==='path'){el=document.createElementNS(SVG,'svg');el.setAttribute('viewBox',node.viewBox.join(' '));const p=document.createElementNS(SVG,'path');p.setAttribute('d',node.geometry);p.setAttribute('fill',node.fill||'none');p.setAttribute('fill-rule',node.fillRule||'nonzero');el.append(p);}
  else{el=document.createElement('div');if(node.type==='text'){el.textContent=textValue(node.content,current);el.className='layer text-layer';el.style.fontFamily=`"${node.fontFamily}"`;el.style.fontSize=`${node.fontSize}px`;el.style.fontWeight=node.fontWeight||'400';el.style.color=node.fill;el.style.lineHeight=String(node.lineHeight||1);if([12,14,27,28,34].includes(current)&&/^(1:29:42|18:42)$/.test(node.content))el.dataset.timer='true';if(current===12&&['18','4'].includes(node.content))el.dataset.stops='true';if(current===12&&['9.9','2.8'].includes(node.content))el.dataset.distance='true';}
    else if(typeof node.fill==='object'){el.className='layer image-layer';el.style.backgroundImage=`url("${node.fill.url}")`;if(node.name==='지도 사진')el.dataset.map='true';}
    else{el.style.background=node.fill;el.style.borderRadius=`${node.cornerRadius||0}px`;}}
  el.classList.add('layer');el.style.left=`${node.x||0}px`;el.style.top=`${node.y||0}px`;if(node.type==='text'){el.dataset.originalText=node.content;el.style.maxWidth=`${Math.max(20,402-x-18)}px`;el.style.overflow='hidden';el.style.textOverflow='ellipsis';if(current===5&&node.content==='시간'){el.dataset.unitLeft=String(node.x);const extra=state.duration<60?String(state.duration).length-1:0;el.style.left=`${node.x+extra*25}px`;}}if(node.width!==undefined)el.style.width=`${node.width}px`;if(node.height!==undefined)el.style.height=`${node.height}px`;parent.append(el);
}
function hit(x,y,w,h,label,fn){const b=document.createElement('button');b.type='button';b.className='hit';b.style.cssText=`left:${x}px;top:${y}px;width:${w}px;height:${h}px;`;b.setAttribute('aria-label',label);b.onclick=()=>{pauseTour();fn();};$('phone').append(b);return b;}
function input(id,value,x,y,w,h,size,onInput,multiline=false,max=80){const e=document.createElement(multiline?'textarea':'input');e.id=id;e.className=multiline?'live-textarea':'live-input';e.setAttribute('aria-label',id==='stationInput'?'정류장 이름':id==='tagInput'?'태그 이름':id==='memoInput'?'여행 메모':'이번에 할 일');e.value=value;e.maxLength=max;e.style.cssText=`left:${x}px;top:${y}px;width:${w}px;height:${h}px;font-size:${size}px;line-height:1.4;`;e.oninput=()=>{pauseTour();onInput(e.value);};$('phone').append(e);return e;}
function closeButton(fn=back,y=200){hit(326,y,56,44,'닫기',fn);}
function tabs(){hit(23,789,106,49,'여행',home);hit(141,789,106,49,'기록',()=>go(17));hit(259,789,120,49,'설정',()=>go(20));}
function radio(y,selected){const e=document.createElement('div');e.className='radio-mark'+(selected?' selected':'');e.style.cssText=`left:332px;top:${y}px;`;$('phone').append(e);}
function range(id,value,min,max,step,x,y,w,fn){const e=document.createElement('input');e.type='range';e.id=id;e.className='live-range';e.min=min;e.max=max;e.step=step;e.value=value;e.style.cssText=`left:${x}px;top:${y}px;width:${w}px;`;e.setAttribute('aria-label',id==='durationInput'?'집중 시간 (분)':'소리 음량');e.oninput=()=>{pauseTour();fn(Number(e.value));};$('phone').append(e);return e;}
function controls(){
  switch(current){
  case 1:hit(31,706,340,50,'출발 정류장 선택',()=>go(3));closeButton(home,526);break;
  case 2:tabs();hit(32,653,338,54,'집중 여행 시작',()=>{state.completed=false;go(5);});hit(205,463,166,40,'반대편 정류장 확인',()=>go(4));hit(340,73,38,44,'출발 정류장 검색',()=>go(3));hit(32,562,338,54,'2014번 버스 선택',()=>toast('2014번 가상 순환 버스가 선택되었습니다.'));break;
  case 3:input('stationInput','성수',77,309,265,31,16,()=>{});for(const [y,origin,direction]of[[370,'성수역','서울숲 방향'],[445,'성수역','건대 방향'],[520,'서울숲역','성수동 방향']])hit(32,y,338,61,`${origin} ${direction}`,()=>{state.origin=origin;state.direction=direction;render();toast(`${origin} · ${direction} 선택`);});hit(31,739,340,50,'선택한 정류장에서 출발',()=>{const value=$('stationInput').value.trim();if(!/(성수|서울숲)/.test(value)){go(26);return;}go(2);});closeButton(back,206);break;
  case 4:hit(31,708,340,52,'반대편 정류장으로 이동',()=>{state.direction='건대 방향';go(2);});hit(31,768,340,54,'현재 정류장 유지',()=>go(2));closeButton(()=>go(2),430);break;
  case 5:range('durationInput',state.duration,15,360,5,55,560,292,value=>{state.duration=value;state.destination=value<=45?'서울숲 입구':value<120?'뚝섬역':'성수대교 북단';for(const el of $('phone').querySelectorAll('.text-layer')){el.textContent=textValue(el.dataset.originalText,5);if(el.dataset.unitLeft)el.style.left=`${Number(el.dataset.unitLeft)+(value<60?(String(value).length-1)*25:0)}px`;}updateSummary();});for(const [x,m]of[[54,25],[125,60],[196,120],[267,240]])hit(x,640,65,28,`${m}분 선택`,()=>setDuration(m));hit(31,787,340,42,'이 여정으로 탑승',()=>go(6));hit(24,145,97,36,'태그 선택',()=>{tagReturn=5;go(7);});hit(132,145,247,36,'할 일 입력',()=>go(6));closeButton(home,426);break;
  case 6:input('taskInput',state.task,46,368,300,37,19,v=>{state.task=v;});hit(31,762,340,50,'이 할 일로 여행',()=>{state.task=$('taskInput').value.trim();if(!state.task){toast('이번 여행에서 할 일을 입력해주세요.');$('taskInput').focus();return;}go(7);});hit(144,433,227,50,'태그 변경',()=>{tagReturn=6;go(7);});hit(32,552,338,60,'독서 노트 정리 선택',()=>{state.task='독서 노트 정리';state.tag='독서';render();});hit(32,627,338,60,'기획안 작성 선택',()=>{state.task='기획안 작성';state.tag='업무';render();});closeButton(()=>go(5),260);break;
  case 7:for(const [tag,y]of[['독서',458],['업무',534],['공부',610]]){hit(32,y,338,64,`${tag} 태그 선택`,()=>{state.tag=tag;render();});radio(y+7,state.tag===tag);}hit(31,697,340,50,'새 태그 만들기',()=>{editingNew=true;tagDraft='';tagReturn=11;go(8);});hit(31,758,340,50,`${state.tag} 선택 완료`,()=>go(tagReturn===5?5:tagReturn===6?6:11));closeButton(()=>go(6),356);break;
  case 8:input('tagInput',editingNew?tagDraft:(tagDraft||state.tag),42,269,285,40,24,v=>{tagDraft=v;});for(let i=0;i<5;i++){hit(42+i*64,369,54,54,`아이콘 ${i+1} 선택`,()=>{selectedIcon=i;render();});hit(42+i*64,487,48,48,`색상 ${i+1} 선택`,()=>{selectedColor=i;render();});}for(const [x,delta]of[[232,-5],[303,5]])hit(x,611,55,55,delta<0?'기본 시간 줄이기':'기본 시간 늘리기',()=>{state.duration=Math.max(15,Math.min(360,state.duration+delta));render();});hit(23,781,355,50,'태그 저장',saveTag);hit(309,65,45,45,'태그 삭제',()=>go(30));hit(356,66,44,44,'태그 편집 취소',back);const outline=document.createElement('div');outline.className='selection-outline';outline.style.cssText=`left:${42+selectedColor*64}px;top:487px;`;$('phone').append(outline);break;
  case 9:for(let row=0;row<4;row++)for(let col=0;col<4;col++){const seat=`${row+1}${'ABCD'[col]}`;const b=document.createElement('button');b.type='button';b.className='seat'+(seat===state.seat?' selected':'');b.style.left=`${40+col*78}px`;b.style.top=`${416+row*62}px`;b.textContent=seat;b.setAttribute('aria-label',`${seat} 좌석 선택`);b.onclick=()=>{state.seat=seat;render();};$('phone').append(b);}hit(31,766,340,48,'이 자리로 탑승',()=>go(11));closeButton(()=>go(11),285);break;
  case 10:for(const [label,key,y]of[['버스 소리','bus',439],['비 오는 버스','rain',515],['소리 없음','none',591]]){hit(32,y,338,65,label,()=>{state.sound=key;render();});radio(y+8,state.sound===key);}range('volumeInput',Math.round(state.volume*100),0,100,1,42,714,310,v=>{state.volume=v/100;audio.volume=state.volume;});hit(31,760,340,51,'소리 선택 완료',()=>{go(soundReturn);sound();});closeButton(()=>go(soundReturn),335);break;
  case 11:hit(44,574,314,198,'카드 터치하여 탑승',()=>go(31));hit(32,462,174,58,'좌석 선택 열기',()=>go(9));hit(221,462,150,58,'소리 선택 열기',()=>openSound(11));closeButton(()=>go(6),376);break;
  case 12:hit(329,601,56,56,'일시정지',()=>go(14));hit(322,539,57,56,'남은 정류장 상세',()=>go(13));hit(260,539,57,56,'버스 따라가기',()=>toast('버스를 따라가는 시점입니다.'));hit(343,72,44,48,'집중 중 더보기',()=>go(32));hit(24,642,354,58,'남은 경로 보기',()=>go(13));break;
  case 13:hit(31,779,340,47,'지도 계속 보기',()=>go(12));closeButton(()=>go(12),312);break;
  case 14:hit(31,703,340,49,'집중 계속하기',()=>go(12,{resume:true}));hit(31,765,340,50,'이번 여행 종료',()=>go(15));closeButton(()=>go(12,{resume:true}),451);break;
  case 15:hit(31,713,340,51,'계속 집중하기',()=>go(12,{resume:true}));hit(31,774,340,52,'여기서 여행 마치기',()=>{complete(true);state.origin='뚝섬역';home();});closeButton(()=>go(14),470);break;
  case 16:hit(36,548,330,209,'카드 터치하여 하차',alight);break;
  case 17:tabs();hit(24,575,354,67,'최근 여행 상세',()=>go(18));hit(24,647,354,66,'기획안 작성 상세',()=>go(18));hit(356,64,44,44,'홈으로 돌아가기',home);break;
  case 18:hit(31,626,340,51,'메모 수정',()=>{recordReturn=18;go(24);});hit(23,789,356,51,'이 정류장에서 새 여행',()=>{state.origin=state.records[0]?.destination||'서울숲 입구';home();});hit(356,64,44,44,'기록으로 돌아가기',()=>go(17));break;
  case 19:for(const [tag,y]of[['독서',196],['업무',292],['공부',388]])hit(32,y,338,66,`${tag} 태그 편집`,()=>{state.tag=tag;editingNew=false;tagDraft=tag;tagReturn=19;go(8);});hit(31,560,340,51,'새 태그 만들기',()=>{editingNew=true;tagDraft='';tagReturn=19;go(8);});hit(356,64,44,44,'설정으로 돌아가기',()=>go(20));break;
  case 20:tabs();for(const [label,y,target]of[['집중 태그',196,19],['소리',288,10],['지도와 움직임',380,21],['도착 알림',472,22],['앱 정보',564,33]])hit(32,y,338,65,label,()=>{if(target===10)openSound(20);else if(target===21)openMap(20);else go(target);});break;
  case 21:hit(32,379,338,61,'버스 추적 시점',()=>toast('버스를 따라가는 시점을 선택했습니다.'));hit(32,458,338,61,'노선 지도 시점',()=>toast('고정된 노선 지도를 선택했습니다.'));hit(32,554,338,66,'동작 줄이기 전환',()=>{state.reduced=!state.reduced;toast(state.reduced?'동작 줄이기를 켰습니다.':'동작 줄이기를 껐습니다.');});hit(31,764,340,49,'지도 설정 적용',()=>go(settingsReturn));closeButton(()=>go(settingsReturn),280);break;
  case 22:hit(31,708,340,49,'도착 알림 허용 시연',()=>{go(20);toast('도착 알림 허용 흐름을 확인했습니다.');});hit(31,768,340,49,'알림은 나중에',()=>go(20));closeButton(()=>go(20),428);break;
  case 23:hit(23,718,356,51,'첫 여행 시작',home);hit(356,64,44,44,'홈으로 돌아가기',home);break;
  case 24:input('memoInput',state.memo,42,198,314,175,18,v=>{state.memo=v;},true,200);hit(31,495,340,51,'메모 저장',()=>{state.memo=$('memoInput').value;persist();go(recordReturn);});hit(356,64,44,44,'메모 편집 취소',()=>go(recordReturn));hit(230,760,150,50,'키보드 완료',()=>$('memoInput').blur());break;
  case 25:hit(31,716,340,49,'다른 정류장 선택',()=>go(3));hit(31,774,340,49,'반대편 확인',()=>go(4));closeButton(home,444);break;
  case 26:hit(31,765,340,51,'검색어 다시 입력',()=>{go(3);$('stationInput').value='';$('stationInput').focus();});closeButton(()=>go(3),344);break;
  case 27:hit(32,254,338,58,'지도 로딩 완료',()=>go(12));hit(329,601,56,56,'일시정지',()=>go(14));break;
  case 28:hit(42,387,316,48,'지도 다시 불러오기',()=>{go(27);tagTimer=setTimeout(()=>go(12),750);});hit(329,601,56,56,'일시정지',()=>go(14));break;
  case 29:input('tagInput',tagDraft,42,250,288,42,24,v=>{tagDraft=v;});hit(23,788,355,50,'태그 이름 수정 후 저장',saveTag);hit(356,64,44,44,'태그 편집으로 돌아가기',()=>go(8));break;
  case 30:hit(31,703,340,49,'태그 유지',()=>go(19));hit(31,764,340,50,'태그 삭제',()=>{state.customTags=state.customTags.filter(t=>t!==state.tag);state.tag='태그 없음';persist();go(19);toast('태그를 삭제했습니다. 여행 기록은 유지됩니다.');});closeButton(()=>go(19),460);break;
  case 31:hit(31,757,340,49,'바로 집중하기',()=>go(12,{start:true}));break;
  case 32:hit(32,469,338,64,'남은 정류장',()=>go(13));hit(32,546,338,64,'여행의 소리',()=>openSound(12));hit(32,623,338,64,'지도 보기',()=>openMap(12));hit(31,744,340,49,'일시정지',()=>go(14));closeButton(()=>go(12),377);break;
  case 33:hit(356,64,44,44,'설정으로 돌아가기',()=>go(20));break;
  case 34:hit(31,746,340,50,'진행 중인 집중 화면으로 복귀',()=>go(12,{resume:true}));closeButton(()=>go(12,{resume:true}),470);break;
  case 35:hit(31,479,340,50,'기기 설정 열기 시연',()=>toast('실제 iPhone 앱에서는 기기 설정으로 이동합니다.'));hit(23,790,355,50,'알림 없이 사용하기',()=>go(20));hit(356,64,44,44,'설정으로 돌아가기',()=>go(20));break;
  case 36:input('taskInput',state.task,42,197,314,37,19,v=>{state.task=v;});hit(23,405,355,49,'할 일 입력 완료',()=>go(6));hit(230,760,150,50,'키보드 입력 완료',()=>go(6));hit(356,64,44,44,'입력 화면 닫기',()=>go(6));break;
  }
}
function updateSummary(){for(const [id,value]of[['summaryOrigin',state.origin],['summaryDuration',durationLabel()],['summaryTask',state.task||'할 일을 입력해주세요'],['summaryTag',state.tag]])$(id).textContent=value;}
function render(){const phone=$('phone');phone.replaceChildren();phone.setAttribute('aria-busy','false');phone.setAttribute('aria-label',`다음 정류장 · ${names[current-1]}`);phone.classList.toggle('show-hints',$('hints').checked);const surface=document.createElement('div');surface.className='screen-layers';if(state.reduced)surface.style.animation='none';for(const node of pages[current-1].children)layer(node,surface);phone.append(surface);controls();const description=descriptions[current];$('screenNumber').textContent=String(current).padStart(2,'0');$('screenName').textContent=names[current-1];$('guideTitle').textContent=description[0];$('guideText').textContent=description[1];$('guideAction').textContent=$('interactionHint').textContent=description[2];$('previous').disabled=history.length===0;for(const [i,step]of steps.entries())$('journeySteps').children[i].querySelector('button').setAttribute('aria-current',step.screens.includes(current)?'step':'false');updateSummary();resize();}
function resize(){let scale;if(innerWidth<700)scale=Math.min(1,(innerWidth-32)/402);else scale=Math.min(1,Math.max(.55,(innerHeight-210)/874));document.documentElement.style.setProperty('--scale',scale.toFixed(4));}
function tick(now){if(!lastTick)lastTick=now;const delta=Math.min(1000,now-lastTick);lastTick=now;if(state.running&&!state.paused){state.progress=Math.min(1,state.progress+delta/30000);document.querySelectorAll('[data-timer]').forEach(e=>e.textContent=remaining());document.querySelectorAll('[data-stops]').forEach(e=>e.textContent=String(Math.ceil(state.duration/5*(1-state.progress))));document.querySelectorAll('[data-distance]').forEach(e=>e.textContent=(state.duration*.11*(1-state.progress)).toFixed(1));if(!state.reduced)document.querySelectorAll('[data-map]').forEach(e=>e.style.transform=`scale(1.035) translateY(${-state.progress*18}px)`);if(state.progress>=1)go(16,{tour:tourIndex>=0});}requestAnimationFrame(tick);}
function next(){const nextPages={1:3,3:2,2:5,5:6,6:7,7:11,8:7,9:11,10:soundReturn,11:31,31:12,12:16,13:12,14:12,15:2,16:2,17:18,18:20,19:20,20:2,21:settingsReturn,22:20,23:2,24:18,25:3,26:3,27:12,28:12,29:8,30:19,32:12,33:20,34:12,35:20,36:6};if(current===16)alight();else go(nextPages[current]||2,{start:current===31,resume:current===14});}
function tourStep(){if(tourIndex<0)return;const page=story[tourIndex];if(page===2&&tourIndex>10)state.origin=state.destination;if(page===12){state.progress=tourIndex===8?.22:.55;state.running=true;state.paused=false;}go(page,{tour:true});$('tour').querySelector('span').textContent='재생 멈추기';$('tour').setAttribute('aria-pressed','true');if(tourIndex>=story.length-1){pauseTour();return;}tourTimer=setTimeout(()=>{tourIndex++;tourStep();},page===12?4200:2600);}
$('tour').onclick=()=>{if(tourIndex>=0){pauseTour();return;}state={...defaults(),records:state.records,memo:state.memo,customTags:state.customTags};history=[];tourIndex=0;tourStep();};
$('restart').onclick=()=>{pauseTour();audio.pause();state={...defaults(),records:state.records,memo:state.memo,customTags:state.customTags};history=[];current=1;render();announcement('첫 이용 화면부터 다시 시작합니다.');};
$('previous').onclick=back;$('next').onclick=next;$('hints').onchange=()=> $('phone').classList.toggle('show-hints',$('hints').checked);
addEventListener('resize',resize);document.addEventListener('visibilitychange',()=>lastTick=performance.now());
for(const [index,step]of steps.entries()){const li=document.createElement('li');const b=document.createElement('button');b.type='button';const dot=document.createElement('span');dot.className='step-dot';dot.textContent=String(index+1);const label=document.createElement('span');label.textContent=step.label;b.append(dot,label);b.onclick=()=>go(step.page,{start:step.page===12});li.append(b);$('journeySteps').append(li);}
for(let i=1;i<=36;i++){const b=document.createElement('button');b.type='button';b.textContent=`${String(i).padStart(2,'0')} · ${names[i-1]}`;b.onclick=()=>go(i,{start:i===12});$('screenList').append(b);}
try{const response=await fetch('screens.json');if(!response.ok)throw new Error('screen data');pages=await response.json();if(pages.length!==36)throw new Error('screen count');render();requestAnimationFrame(tick);}catch{$('phone').innerHTML='<div class="loading">화면을 불러오지 못했습니다.<br>페이지를 새로고침해주세요.</div>';}
window.flowPrototype={go,readState:()=>({screen:current,...structuredClone(state)}),next,back};

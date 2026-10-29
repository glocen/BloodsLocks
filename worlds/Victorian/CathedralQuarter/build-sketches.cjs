// Original vector drawings: no external assets or generative service.
const fs=require('node:fs'), path=require('node:path');
const sharp=require('C:/Users/gloce/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const C={bg:'#10131e',paper:'#171d2b',ink:'#d9d8cc',muted:'#8c9bad',gold:'#dfb56c',street:'#7e9bad',upper:'#d5ac69',crypt:'#a58bc5',red:'#b75a70',wall:'#536073'};
const e=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;');
const text=(x,y,t,s=17,c=C.ink,a='')=>`<text x="${x}" y="${y}" font-size="${s}" fill="${c}" ${a}>${e(t)}</text>`;
const lines=(x,y,a,s=17,c=C.muted,dy=27)=>a.map((t,i)=>text(x,y+i*dy,t,s,c)).join('');
const poly=(pts,fill,stroke='none',width=2)=>`<polygon points="${pts.map(p=>p.join(',')).join(' ')}" fill="${fill}" stroke="${stroke}" stroke-width="${width}"/>`;
const line=(pts,c,w=3,dash='')=>`<polyline points="${pts.map(p=>p.join(',')).join(' ')}" fill="none" stroke="${c}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round" stroke-dasharray="${dash}"/>`;
const rect=(x,y,w,h,f,s='none',sw=2)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${f}" stroke="${s}" stroke-width="${sw}"/>`;
function svg(w,h,b){return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#302337"/><stop offset=".55" stop-color="#4c3d50"/><stop offset="1" stop-color="#85889d"/></linearGradient><linearGradient id="mist" x2="0" y2="1"><stop stop-color="#adb3c7" stop-opacity="0"/><stop offset="1" stop-color="#adb3c7" stop-opacity=".22"/></linearGradient><radialGradient id="lamp"><stop stop-color="#ffd497" stop-opacity=".6"/><stop offset="1" stop-color="#e99655" stop-opacity="0"/></radialGradient></defs>${rect(0,0,w,h,C.bg)}<g font-family="Georgia, Times New Roman, serif">${b}</g></svg>`;}
function heading(k,t,s){return text(46,42,k,14,C.gold,'letter-spacing="3"')+text(46,85,t,36)+text(46,117,s,17,C.muted);}
const X=x=>540+x*1.7,Z=z=>608+z*1.7;
const wp=a=>a.map(([x,z])=>[X(x),Z(z)]),wr=(x,z,w,d,f,s=C.wall)=>rect(X(x),Z(z),w*1.7,d*1.7,f,s),route=(a,c,d='',w=5)=>line(wp(a),c,w,d);
function label(x,z,t,c=C.ink,s=15){return text(X(x),Z(z),t,s,c,'text-anchor="middle"');}
function dot(x,z,t,c=C.gold,r=14){return `<circle cx="${X(x)}" cy="${Z(z)}" r="${r}" fill="${C.bg}" stroke="${c}" stroke-width="2"/>`+label(x,z+3,t,c,14);}
function plan(){let b=heading('BLOODLOCKS / VICTORIAN / ORIGINAL DESIGN STUDY 01','The Cathedral Quarter','An interconnected first zone: inhabited streets, a ceremonial heart, and useful height. Design proposal; not a finished level.');
 b+=wr(-240,-260,480,500,C.paper,C.muted);
 for(let x=-200;x<=200;x+=40)b+=route([[x,-260],[x,240]],'#293242','',.7);
 for(let z=-240;z<=240;z+=40)b+=route([[-240,z],[240,z]],'#293242','',.7);
 const blocks=[[-224,112,82,96],[-132,154,92,60],[44,158,96,64],[154,108,70,98],[-224,-76,78,126],[158,-92,66,116],[-226,-242,106,98],[122,-244,104,110],[-110,-238,80,36],[32,-238,76,36]];
 for(const[x,z,w,d]of blocks){b+=wr(x,z,w,d,'#30394a','#6c7180');for(let i=8;i<w-8;i+=16)b+=route([[x+i,z],[x+i,z+d]],'#444b5c','',1);}
 b+=wr(-202,136,34,42,C.paper)+wr(174,130,32,48,C.paper)+wr(-202,-50,34,64,C.paper);
 b+=wr(-68,-176,136,144,'#4b5361','#a2a6b0')+wr(-98,-136,30,58,'#444e5e','#929cab')+wr(68,-144,38,54,'#444e5e','#929cab');
 b+=poly(wp([[-32,-176],[0,-202],[32,-176]]),'#4b5361','#a2a6b0')+wr(-48,-157,96,102,'#222b3a','#8390a4');
 for(let z=-156;z<-62;z+=24)for(const x of[-56,56])b+=`<circle cx="${X(x)}" cy="${Z(z)}" r="6" fill="#9096a2"/>`;
 b+=wr(-56,-44,112,12,'#73737b','#b4b0ad');for(let z=-40;z<-20;z+=4)b+=route([[-56,z],[56,z]],'#8a8d98','',1);
 b+=wr(-50,14,100,80,'#424652','#9c9698')+wr(76,28,62,78,'#303a48','#7f8c9b')+wr(-128,18,60,70,'#303a48','#7f8c9b')+wr(-136,-140,28,42,'#34384a','#aa91b4');
 b+=route([[-72,80],[-112,38],[-112,-42],[-38,-74],[42,-74],[110,-38],[130,28],[112,78]],C.crypt,'9 6',6);
 b+=route([[0,214],[0,112],[-72,112],[-142,84],[-142,-94],[-98,-174],[0,-220],[144,-174],[146,-64],[146,82],[72,112],[0,112]],C.street);
 b+=route([[0,112],[0,-24],[0,-54],[-42,-98],[0,-152],[42,-98],[0,-54]],C.street,'',4)+route([[-142,-54],[-78,-54],[-42,-98]],C.street,'',4)+route([[146,-62],[98,-62],[42,-98]],C.street,'',4);
 b+=route([[-154,120],[-118,114],[-104,70],[-92,14],[-86,-36],[-78,-78],[-78,-132]],C.upper)+route([[162,-132],[130,-126],[114,-86],[88,-42],[90,18],[112,58],[130,114]],C.upper)+route([[-92,14],[-42,14],[0,14],[42,14],[90,18]],C.upper,'',6)+route([[-78,-132],[-28,-132],[28,-132],[114,-86]],C.upper,'7 4',4);
 b+=label(0,-82,'CATHEDRAL NAVE',C.ink,17)+label(0,-67,'clear 96 × 102 / +8',C.muted,14)+label(0,73,'PROCESSIONAL COURT',C.ink,16)+label(0,88,'100 × 80 / 0',C.muted,14)+label(-101,44,'CLOISTER',C.ink,13)+label(107,68,'BELL YARD',C.ink,13)+label(-185,184,'TERRACES',C.muted,14)+label(190,190,'SERVICE ROW',C.muted,14)+label(-177,-218,'CHAPTER HOUSES',C.muted,13)+label(174,-224,'BELL WORKS',C.muted,13)+label(0,145,'Lamplighters’ Reach',C.ink,18)+label(0,163,'main approach / 28 wide',C.muted,14)+label(2,-184,'sealed apse / landmark',C.muted,13);
 [[-194,188],[184,178],[-196,-202],[196,-208],[-184,24],[192,-14],[-126,124],[132,-128]].forEach((a,i)=>b+=dot(...a,'S'+(i+1),'#a3c3c0',13));
 for(const[x,z,t]of[[-96,144,'A'],[112,80,'B'],[112,-38,'C'],[-35,-124,'D'],[30,-114,'E'],[-70,26,'F']])b+=dot(x,z,t,C.red,12);
 for(const[x,z,t]of[[0,48,'R1'],[0,-124,'R2'],[-112,38,'O1'],[112,48,'O2'],[-44,-72,'O3'],[-120,-122,'O4']])b+=dot(x,z,t,C.gold,15);
 for(const[x,z,t]of[[-144,106,'U1'],[148,-118,'U2'],[-132,32,'L1'],[140,16,'L2'],[-70,-28,'G1'],[76,-42,'G2']])b+=dot(x,z,t,C.upper,13);
 b+=route([[-210,66],[-240,66]],C.gold,'7 5',7)+route([[210,52],[240,52]],C.gold,'7 5',7)+route([[0,-228],[0,-260]],C.gold,'7 5',7)+text(X(-235),Z(100),'W: future works',13,C.gold)+text(X(144),Z(100),'E: future waterside',13,C.gold)+label(0,-246,'N: future moor / woodland',C.gold,14);
 b+=line([[76,215],[76,156],[67,174],[76,156],[85,174]],C.ink,2)+text(70,144,'N',18)+text(46,245,'−Z',13,C.muted)+line([[X(-220),1080],[X(-120),1080]],C.ink,2)+text(X(-220),1110,'100 studs / proposal scale',15,C.muted);
 b+=text(1080,180,'THREE ROUTE FAMILIES',18,C.gold);
 for(const[y,c,t,d]of[[210,C.street,'Street / nave / two side returns',''],[252,C.upper,'Gallery / roof courts / bridge',''],[294,C.crypt,'Crypt / ossuary / two stair returns','8 5']])b+=line([[1080,y],[1128,y]],c,5,d)+text(1144,y+5,t,17);
 b+=lines(1080,350,['Play floors: −18, 0 / +8, +24 / +36 / +48.','Roof ridge and spire are scenery.','Every height route has two entrances.','A failed jump lands on a lower route.'],17,C.ink,29)+text(1080,500,'READ THE MARKERS',18,C.gold)+lines(1080,535,['S1–S8   sheltered spawn candidates','A–F       authored enemy groups','R1 / R2 ritual / boss space reserved','O1–O4  interactions reserved','U1 / U2 independent upper ascents','L1 / L2   crypt stairs; no one-way pit','G1 / G2 gallery doors'],17,C.ink,30)+text(1080,800,'ANTI-DOMINANCE RULES',18,C.gold)+lines(1080,834,['Break roof sightlines with roof volumes.','Upper routes overlook parts of a court.','No roof sees every spawn or objective.','Keep the two ground returns useful.','Use slate and masonry for the screens.'],17,C.ink,29)+lines(1080,1035,['Companion spec gives exact coordinates.','No Studio or game code changed.','Authored design: 29 Oct 2026.'],15,C.muted,24);
 return svg(1600,1150,b);}
function section(){let b=heading('BLOODLOCKS / CATHEDRAL QUARTER / SECTION & CIRCULATION','Height that returns you to the world','Unfolded section: relationships and clearances are intentional; screen distances are schematic.');const y=h=>585-h*5;
 b+=poly([[65,y(0)],[530,y(0)],[530,y(8)],[1070,y(8)],[1070,y(0)],[1520,y(0)],[1520,785],[65,785]],'#383c4b','#8e96a7');
 b+=rect(355,y(-2),810,80,'#151a28',C.crypt);
 for(const x of[580,720,920,1060])b+=rect(x-9,y(46),18,190,'#444b5b','#9ba1af');
 b+=`<path d="M580 ${y(40)}Q650 ${y(62)} 720 ${y(40)}Q820 ${y(68)} 920 ${y(40)}Q990 ${y(62)} 1060 ${y(40)}" fill="none" stroke="#a5abb7" stroke-width="5"/>`+line([[556,y(48)],[820,y(78)],[1084,y(48)]],'#333d51',19);
 b+=poly([[338,y(36)],[338,y(51)],[385,y(63)],[432,y(51)],[432,y(36)]],'#303a4a','#929cad')+poly([[1195,y(36)],[1195,y(56)],[1236,y(69)],[1277,y(56)],[1277,y(36)]],'#303a4a','#929cad');
 b+=line([[80,y(0)],[500,y(0)],[540,y(8)],[1110,y(8)],[1150,y(0)],[1510,y(0)]],C.street,6)+line([[260,y(0)],[330,y(12)],[385,y(12)],[455,y(24)],[580,y(24)],[720,y(24)]],C.upper,6)+line([[920,y(24)],[1060,y(24)],[1130,y(36)],[1310,y(36)],[1380,y(24)],[1430,y(24)],[1500,y(0)]],C.upper,6)+line([[455,y(24)],[500,y(36)],[580,y(36)]],C.upper,6)+line([[720,y(24)],[755,y(36)],[885,y(36)],[920,y(24)]],C.upper,6)+line([[285,y(0)],[390,y(-18)],[1140,y(-18)],[1245,y(0)]],C.crypt,6)+line([[660,y(8)],[735,y(-18)]],C.crypt,4,'8 5')+line([[990,y(-18)],[1065,y(8)]],C.crypt,4,'8 5');
 for(const h of[-18,0,8,24,36,48])b+=line([[48,y(h)],[1530,y(h)]],'#3d4556',1,'4 8')+text(50,y(h)-8,(h>=0?'+':'')+h,15,C.muted);
 b+=text(107,550,'STREET 0',17,C.street)+text(760,517,'NAVE +8',17,C.street)+text(602,444,'GALLERY +24',17,C.upper)+text(1152,390,'ROOF COURT +36',17,C.upper)+text(645,654,'CRYPT −18 / ceiling −2',17,C.crypt)+text(285,445,'U1',16,C.upper)+text(1370,407,'U2',16,C.upper)+text(350,661,'L1',16,C.crypt)+text(1190,658,'L2',16,C.crypt);
 b+=lines(112,170,['Low route: a full circuit around the church.','Interior route: nave + two side doors.','Upper: stairs, courts, broken sightlines.','Lower: two stair mouths + interior links.'],18,C.ink,29)+lines(1000,170,['Section dimensions to preserve:','16-stud clear crypt; ≥18 above stair pitch.','12-stud upper paths; 18-stud landings.','Nave: central 48 × 64 has no supports.'],18,C.ink,29)+text(85,834,'Ground → upper → interior → ground and ground → crypt → interior → ground are complete loops.',21,C.gold)+text(85,871,'Jump shortcuts add speed and expression. Stairs keep depleted players and grounded companions in the game.',18,C.muted);
 return svg(1600,915,b);}
function win(x,y,w,h,lit=false){return `<path d="M${x} ${y+h}V${y+w*.5}Q${x+w*.5} ${y-12} ${x+w} ${y+w*.5}V${y+h}Z" fill="${lit?'#b59178':'#171d2b'}" stroke="#9296a4" stroke-width="3"/><path d="M${x+w*.5} ${y+4}V${y+h}M${x} ${y+h*.58}H${x+w}" stroke="#636978" stroke-width="3"/>`;}
function lamp(x,y){return `<circle cx="${x}" cy="${y}" r="70" fill="url(#lamp)"/><path d="M${x} ${y+85}V${y+8}M${x-5} ${y+8}H${x+5}L${x+9} ${y-8}L${x} ${y-17}L${x-9} ${y-8}Z" fill="#171b27" stroke="#9d8167" stroke-width="2"/>`+poly([[x-3,y+3],[x+3,y+3],[x+5,y-7],[x-5,y-7]],'#ffd59b');}
function human(x,y,s=1){return `<g transform="translate(${x} ${y}) scale(${s})"><circle cy="-43" r="7" fill="#171c29"/><path d="M-5-34L-12-8L-9 0L-2-18L3 0H10L5-35Z" fill="#171c29"/><path d="M-5-29L-20-16M3-29L18-19" stroke="#171c29" stroke-width="5"/></g>`;}
function approach(){let b=heading('BLOODLOCKS / PLAYER VIEW A / LAMPLIGHTERS’ REACH','The institution above the street','Eye-level composition study: the lived-in district opens toward the raised cathedral; practical light follows the route.');
 b+=rect(45,148,1510,680,'url(#sky)');
 b+=poly([[45,525],[45,400],[95,400],[95,355],[122,324],[148,355],[148,391],[185,391],[185,332],[215,332],[245,424],[275,424],[275,367],[310,367],[310,454],[353,454],[353,398],[386,398],[386,454],[1280,454],[1280,416],[1315,416],[1315,350],[1350,350],[1350,321],[1364,350],[1390,350],[1390,410],[1440,410],[1440,369],[1484,369],[1484,402],[1555,402],[1555,680],[45,680]],'#474356');
 b+=poly([[504,613],[504,388],[554,341],[605,388],[605,613]],'#394354','#6f7a8d',3)+poly([[1080,613],[1080,381],[1130,327],[1180,381],[1180,613]],'#394354','#6f7a8d',3);
 b+=poly([[572,610],[572,313],[612,313],[612,267],[633,232],[654,267],[654,313],[695,313],[695,610]],'#394252','#8c91a0',3)+win(608,340,50,100);
 b+=poly([[660,610],[660,376],[854,243],[1070,376],[1070,610]],'#4b5261','#a3a1aa',3)+line([[660,378],[854,243],[1070,378]],'#29364b',12)+line([[676,392],[854,267],[1050,392]],'#29364b',7)+win(786,332,133,146,true);
 b+=`<path d="M767 611V539Q854 421 941 539V611Z" fill="#202738" stroke="#a5a3aa" stroke-width="12"/><path d="M789 611V544Q854 454 919 544V611" fill="none" stroke="#707c8c" stroke-width="7"/>`;
 for(const x of[703,746,962,1012])b+=poly([[x,612],[x,411],[x+12,390],[x+23,411],[x+23,612]],'#5c6472','#969bab');
 b+=poly([[665,610],[1044,610],[1110,690],[588,690]],'#646a76','#9b9da4');for(let y=620;y<690;y+=10)b+=line([[665-(y-610),y],[1044+(y-610)*.8,y]],'#b0adb0',1.5);
 b+=poly([[45,196],[340,306],[340,661],[45,765]],'#20283a','#495366',4)+poly([[45,196],[340,306],[371,279],[45,166]],'#131c2e')+poly([[340,426],[512,458],[512,622],[340,661]],'#343d4d','#657080',3)+poly([[1555,186],[1266,299],[1266,671],[1555,785]],'#202737','#465164',4)+poly([[1266,428],[1146,464],[1146,626],[1266,671]],'#303948','#69717f',3);
 for(const[x,y,w,h]of[[115,328,43,92],[214,365,36,76],[95,522,50,110],[219,498,40,100],[1376,346,43,90],[1458,303,46,100],[1382,510,48,110],[1462,478,48,116]])b+=win(x,y,w,h,[115,1382].includes(x));
 b+=poly([[45,765],[590,690],[1110,690],[1555,785],[1555,828],[45,828]],'#303846')+line([[413,828],[732,689]],'#8a8390',3)+line([[1191,828],[984,689]],'#8a8390',3)+line([[594,828],[802,689]],'#707784',2)+line([[1052,828],[930,689]],'#707784',2);
 b+=poly([[376,731],[415,731],[454,815],[371,815]],'#6f625b')+poly([[1197,732],[1232,732],[1250,818],[1160,818]],'#5f5856');
 b+=lamp(402,608)+lamp(1217,617)+lamp(692,561)+lamp(1018,562)+human(775,733,1.2)+human(1101,722,.8)+human(487,750,.9);
 b+=line([[310,487],[362,487],[362,504]],'#aea08d',3)+rect(340,503,44,48,'#49363a','#a98d6d')+line([[350,519],[373,536]],'#c1a482',2)+line([[350,536],[373,519]],'#c1a482',2)+rect(45,650,1510,178,'url(#mist)');
 b+=text(63,800,'VIEW A  /  camera (0, 5.5, 198) toward (0, 30, −80)',16,'#dcd4ce')+lines(48,867,['Foreground: occupied thresholds and ironwork. Midground: warm road, walkers, broad stair. Background: cool ceremonial stone.','The bell tower sits left of the nave. Small amber windows imply occupation; the brightest route accent sits at a reachable entrance.'],18,C.muted,29);
 return svg(1600,945,b);}
function vertical(){let b=heading('BLOODLOCKS / PLAYER VIEW B / THE CLOISTER CROSSING','Three ways through one place','Upper paths connect to the court. The lower route is visible, reachable, and returns through the cathedral.');
 b+=rect(45,148,1510,680,'url(#sky)')+poly([[1100,532],[1100,340],[1148,340],[1148,278],[1174,243],[1200,278],[1200,340],[1240,340],[1240,532],[1240,385],[1380,300],[1490,392],[1490,532]],'#444758','#6e7286',3);
 b+=poly([[45,267],[462,324],[462,734],[45,811]],'#333e51','#768296',3)+poly([[462,324],[689,282],[689,680],[462,734]],'#434c60','#8f96a5',3)+win(112,386,88,166)+win(288,418,72,143,true);
 b+=poly([[78,738],[78,358],[99,330],[120,358],[120,730]],'#596273','#8d96a4',3)+poly([[378,682],[378,399],[396,373],[414,399],[414,674]],'#596273','#8d96a4',3)+poly([[45,786],[682,662],[1110,717],[1555,828],[45,828]],'#353b49','#777f90',3);
 b+=poly([[1160,672],[1555,590],[1555,262],[1364,202],[1160,330]],'#273347','#717d91',3)+line([[1154,329],[1364,202],[1555,261]],'#8991a0',5)+win(1266,379,68,144);
 b+=poly([[465,495],[903,435],[1174,490],[892,542],[465,578]],'#7d7c85','#b5acaa',3)+poly([[465,578],[892,542],[1174,490],[1174,511],[892,567],[465,600]],'#4c586c','#9da3ae');
 for(const x of[590,824,1040])b+=line([[x,575-(x-590)*.1],[x,737-(x-590)*.02]],'#647086',21);
 b+=line([[469,492],[903,433],[1170,486]],'#a0a5b0',4)+line([[469,463],[903,405],[1170,458]],'#a0a5b0',4);
 for(let i=0;i<12;i++){const x=490+i*35,y=489-(x-469)*.135;b+=line([[x,y],[x,y-28]],'#7f899d',5);}
 b+=poly([[1011,537],[1091,557],[1262,707],[1193,713]],'#656b78','#a3a2aa',3);for(let i=0;i<10;i++){const y=559+i*14.5,x=1088+i*11;b+=line([[x-63,y],[x+6,y+11]],'#b3abb0',1.5);}
 b+=`<path d="M690 828V743Q777 644 864 743V828Z" fill="#111929" stroke="#8e8b9d" stroke-width="12"/><path d="M710 828V748Q777 669 844 748V828" fill="none" stroke="#4b576e" stroke-width="8"/><path d="M724 828V754Q777 693 830 754V828" fill="none" stroke="#333e55" stroke-width="4"/>`+poly([[765,791],[789,791],[807,828],[748,828]],'#48465c');
 b+=lamp(907,651)+lamp(686,583)+lamp(1200,638)+human(882,491,.9)+human(1021,701,1.15)+human(746,788,.66)+human(1350,702,.85)+rect(45,650,1510,178,'url(#mist)');
 b+=text(489,394,'+24 gallery → +36 bridge → east stair',17,'#ead5af')+text(949,760,'0  court / two ground exits',17,'#c8d4dc')+text(689,806,'−18 crypt loop',17,'#c6b7d6')+text(63,800,'VIEW B  /  camera (148, 5.5, 72) toward (−50, 20, −46)',15,'#dcd4ce')+lines(48,867,['Roof volumes interrupt long fire lanes. A crossing reveals the court; the cathedral mass conceals the far spawns.','The crypt has two stair returns. It is a route choice, not a reward closet. Mist separates depth while leaving stairs visible.'],18,C.muted,29);
 return svg(1600,945,b);}
async function main(){for(const[name,make]of[['01-cathedral-quarter-plan',plan],['02-circulation-section',section],['03-player-view-approach',approach],['04-player-view-vertical-loop',vertical]]){const src=make();fs.writeFileSync(path.join(__dirname,name+'.svg'),src);await sharp(Buffer.from(src)).png().toFile(path.join(__dirname,name+'.png'));console.log(name);}}
main().catch(e=>{console.error(e);process.exitCode=1;});


"""Original vector art direction studies. Schematic design, never reference evidence."""
from pathlib import Path
P=Path(__file__).parent
def svg(name,title,body):
 head='''<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1000" viewBox="0 0 1500 1000"><defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#171b2c"/><stop offset="1" stop-color="#535269"/></linearGradient><linearGradient id="stone" x2="1" y2=".3"><stop stop-color="#232633"/><stop offset="1" stop-color="#687082"/></linearGradient><radialGradient id="warm"><stop stop-color="#f3be79" stop-opacity=".8"/><stop offset="1" stop-color="#ce6b43" stop-opacity="0"/></radialGradient><linearGradient id="mist" x2="0" y2="1"><stop stop-color="#a2a2b4" stop-opacity="0"/><stop offset="1" stop-color="#9ba1ad" stop-opacity=".45"/></linearGradient></defs><rect width="1500" height="1000" fill="#10151d"/><style>text{font-family:Georgia,serif;fill:#e2ddcf} .s{font-family:Arial,sans-serif;font-size:18px;fill:#c1c8d2}.note{font-family:Arial,sans-serif;font-size:17px;fill:#d9dce1}.line{stroke:#d5b77f;fill:none;stroke-width:2}.label{font-size:24px;fill:#d9bb88}</style>'''
 footer=f'<rect y="900" width="1500" height="100" fill="#10151d"/><text x="48" y="943" font-size="26">{title}</text><text x="48" y="978" class="s">BloodLocks · Original design study · 29 October 2026 · Schematic, not a reconstruction or accepted final art</text></svg>'
 (P/name).write_text(head+body+footer,encoding='utf-8')
# Approach: low diagonal with original manor silhouette, deep occupied entrance, framing and value hierarchy.
b='<rect x="0" y="0" width="1500" height="900" fill="url(#sky)"/><circle cx="414" cy="246" r="103" fill="#8f494d" opacity=".65"/><path d="M0 660 Q280 581 540 688 Q930 595 1500 677 V900 H0Z" fill="#363c48"/>'
b+='<path d="M344 654V420L329 410 420 242 513 423V647Z" fill="#292e3d"/><path d="M383 425V235L412 90 443 239V426Z" fill="#303849"/><path d="M398 239L412 90 420 239" fill="#778096" opacity=".4"/>'
b+='<path d="M465 671V429L680 381 873 450V689Z" fill="url(#stone)"/><path d="M443 432L628 273 722 281 882 452 680 390Z" fill="#222b3b"/><path d="M871 693V486L1260 504V732Z" fill="url(#stone)"/><path d="M846 484L918 380 1300 425 1264 509Z" fill="#273247"/><path d="M917 380L1300 425" stroke="#788599" stroke-width="3"/>'
for x in range(910,1255,66):
 b+=f'<path d="M{x} 693V560Q{x+17} 518 {x+35} 560V699Z" fill="#1b202d" stroke="#828695" stroke-width="4"/><path d="M{x} 544V505Q{x+17} 473 {x+35} 506V548Z" fill="#342932" stroke="#7b8092" stroke-width="3"/>'
b+='<path d="M560 703V552L612 506 668 558V711Z" fill="#343a45" stroke="#a2a0a0" stroke-width="6"/><path d="M578 707V591Q580 563 612 545Q645 566 648 591V712Z" fill="#1b1720"/><path d="M592 707V601Q594 577 613 567Q633 580 635 603V712Z" fill="#b06c43" opacity=".65"/><ellipse cx="612" cy="714" rx="130" ry="87" fill="url(#warm)"/>'
b+='<path d="M370 900Q550 752 612 714L647 716Q760 786 888 900Z" fill="#777780" opacity=".65"/><path d="M600 900Q605 775 619 722" stroke="#b6aa98" stroke-width="4" opacity=".5"/>'
# Foreground gravestones and branches have separate scale, no fence blocking route.
for x,y,h in[(140,796,68),(292,738,39),(1040,803,56),(1360,812,92)]:
 b+=f'<path d="M{x} {y}v-{h}q13 -19 26 0v{h}Z" fill="#202733"/><path d="M{x+4} {y-h+5}h18" stroke="#7b7d86" stroke-width="2"/>'
b+='<path d="M0 900V150L58 195 72 348 170 229 95 404 124 595 218 505 142 682 165 900Z" fill="#111923"/><path d="M1500 900V115L1433 205 1418 378 1298 260 1399 471 1369 672 1271 602 1348 783 1325 900Z" fill="#111923"/><path d="M80 332L209 112 163 288 265 201 182 372M1403 344L1280 90 1317 275 1206 210 1351 408" stroke="#17212c" stroke-width="22" fill="none"/>'
b+='<path d="M0 760Q300 706 600 768T1500 752V900H0Z" fill="url(#mist)"/><text x="56" y="62" class="label">ARRIVAL · preserve roof / spire identity, compose the ground</text>'
for text,x,y,path in[('01 · Tower separated against a restrained red moon',60,133,'M350 137L402 234'),('02 · One deep, occupied entrance',720,780,'M730 755L639 644'),('03 · Cool readable ground, worn path and low mist',60,859,'M530 850L593 803'),('04 · Trees frame rather than cover the building',1045,128,'M1190 145L1385 377')]:
 b+=f'<text x="{x}" y="{y}" class="note">{text}</text><path d="{path}" class="line"/>'
svg('manor-arrival-study.svg','01 · The ceremonial manor approach',b)
# Hall: player-height view, two occupied storeys, warm table and dark timber separation.
b='<rect x="0" y="0" width="1500" height="900" fill="#1b202d"/><path d="M50 0H1450L1090 560H410Z" fill="#282a33"/><path d="M50 900V0L410 560 410 680Z" fill="#252a34"/><path d="M1450 900V0L1090 560 1090 680Z" fill="#303441"/><path d="M50 900L410 560H1090L1450 900Z" fill="#493f3d"/>'
for xx in(170,300,435,570,930,1065,1200,1330):
 mid=750+(xx-750)*.46
 b+=f'<path d="M{xx} 0L{mid} 560" stroke="#101721" stroke-width="20"/><path d="M{xx} 900L{mid} 560" stroke="#201e25" stroke-width="4"/>'
b+='<path d="M40 405L423 485H1078L1460 405V450L1080 519H420L40 450Z" fill="#4c4343" stroke="#989190" stroke-width="3"/><path d="M50 453L420 520H1080L1450 453" stroke="#171d27" stroke-width="15"/>'
for side in(-1,1):
 for i in range(4):
  x=750+side*(350+i*93);back=750+side*320
  b+=f'<path d="M{x} 900V192L{x+side*27} 168V900Z" fill="#333741" stroke="#626778" stroke-width="3"/>'
  b+=f'<path d="M{x+side*4} 390V320Q{x+side*38} 240 {x+side*72} 320V403" fill="#141b26" stroke="#898892" stroke-width="5"/>'
b+='<path d="M650 600V320Q750 180 850 320V600Z" fill="#606579" stroke="#9294a4" stroke-width="7"/><path d="M674 600V333Q750 226 826 333V600Z" fill="#242a3a"/><path d="M700 594V355Q750 279 800 355V594Z" fill="#657082" opacity=".4"/>'
b+='<path d="M540 900L696 592H801L965 900Z" fill="#6d2935"/><path d="M550 900L701 592M956 900L796 592" stroke="#ac8b56" stroke-width="3"/>'
b+='<ellipse cx="750" cy="681" rx="218" ry="97" fill="url(#warm)"/><path d="M651 669L704 634H803L853 669 826 696H675Z" fill="#9b8b7c" stroke="#c2a16f" stroke-width="4"/><path d="M675 696L687 760H817L826 696Z" fill="#504344"/>'
for x in(681,714,785,822):b+=f'<path d="M{x} 655v-20" stroke="#cfb38c" stroke-width="5"/><ellipse cx="{x}" cy="631" rx="4" ry="8" fill="#ffd098"/>'
b+='<path d="M564 0L630 215H870L936 0" stroke="#111721" stroke-width="5" fill="none"/><path d="M630 215L687 239H814L870 215" stroke="#171a22" stroke-width="14" fill="none"/>'
for x in(646,678,710,790,822,854):b+=f'<path d="M{x} 220v-17" stroke="#d1b18b" stroke-width="4"/><ellipse cx="{x}" cy="201" rx="4" ry="7" fill="#e9b26e"/>'
b+='<text x="50" y="60" class="label">GATHERING HALL · player camera ~5 studs, reference height schematic</text><text x="70" y="120" class="note">Dark timber fields / dressed stone supports</text><path d="M426 120L399 395" class="line"/><text x="940" y="123" class="note">Gallery keeps visual depth and two-floor use</text><path d="M1190 140L1120 466" class="line"/><text x="75" y="832" class="note">Red runner leads through the occupied table space</text><path d="M530 825L651 780" class="line"/><text x="933" y="832" class="note">Yard doorway remains the cool distant anchor</text><path d="M1078 795L809 436" class="line"/>'
svg('manor-hall-study.svg','02 · Occupied hall and two-storey depth',b)
# Measured architectural section, source anchors rather than speculative reference reconstruction.
b='<text x="52" y="62" class="label">SECTIONS · geometry makes the shadow; surface maps support it</text><text x="52" y="103" class="s">Source anchors: existing porch X ±18; eave Y30.5; gallery Y31.9125; hall ceiling envelope Y78.66.</text>'
b+='<text x="74" y="170" font-size="24">A · Porch elevation / open central route</text><path d="M100 750V350L350 220 600 350V750" fill="none" stroke="#4f6278" stroke-width="6"/><path d="M150 750V501Q150 357 350 295Q550 357 550 501V750" fill="none" stroke="#b7b3a9" stroke-width="35"/><path d="M170 750V520Q170 379 350 322Q530 379 530 520V750" fill="none" stroke="#697486" stroke-width="7"/><path d="M143 750V505M557 750V505" stroke="#d5bd94" stroke-width="7"/><path d="M90 750H610" stroke="#aaa69d" stroke-width="4"/>'
b+='<path d="M195 795H505M195 783V807M505 783V807" class="line"/><text x="243" y="829" class="note">20 studs clear width</text><text x="126" y="875" class="note">26.32 opening apex · 29.435 module top</text><text x="72" y="260" class="note">30.5 eave</text><path d="M183 263L298 246" class="line"/>'
b+='<text x="760" y="170" font-size="24">B · Real reveal section / layers in depth</text><path d="M850 740V295H1310V740" fill="#2b3543" stroke="#596a7d" stroke-width="3"/><path d="M845 740V352L879 352 888 330 907 330 925 350 952 350 966 314 987 300 1008 300 1030 324 1046 352 1073 352 1073 288 1094 274 1122 274 1148 294 1157 300 1157 740" fill="#b5b0a3" stroke="#e2ddd1" stroke-width="2"/><path d="M846 740L846 779M1157 740L1157 779M846 768H1157" class="line"/><text x="914" y="807" class="note">6.5-stud reveal</text><text x="759" y="226" class="note">Drip hood / channel / roll / fillet / inner reveal</text><path d="M1010 239L999 301" class="line"/><text x="760" y="875" class="note">Keep the passage empty; no black cap or glass across it.</text><text x="1200" y="522" class="note" transform="rotate(90 1200 522)">Inside porch → hall</text><text x="770" y="640" class="note" transform="rotate(-90 770 640)">Exterior → approach</text>'
svg('manor-depth-sections.svg','03 · Measured porch module and profile depth',b)
print('MANOR_STUDIES_READY',str(P))


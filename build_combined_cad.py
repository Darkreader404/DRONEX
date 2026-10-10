"""Generate the combined R12 3D DXF using standard-library geometry only."""
from math import sin, cos, pi
from pathlib import Path

entities = []
layers = {'DRONE_FRAME':8, 'DRONE_MOTORS':1, 'DRONE_ELECTRONICS':3,
          'REMOTE_FRAME':8, 'REMOTE_SENSORS':30, 'REMOTE_ELECTRONICS':3,
          'CIRCUIT':7, 'SIGNAL':4, 'POWER':1, 'GROUND':8, 'LABELS':2}

def pairs(items):
    return '\n'.join(str(v) for pair in items for v in pair) + '\n'

def entity(kind, layer, data):
    entities.append(pairs([(0,kind),(8,layer)] + data))

def face(points, layer):
    data=[]
    for i,p in enumerate(points):
        data += [(10+i,p[0]), (20+i,p[1]), (30+i,p[2])]
    entity('3DFACE',layer,data)

def box(x,y,z,w,d,h,layer):
    p=[(x-w/2,y-d/2,z),(x+w/2,y-d/2,z),(x+w/2,y+d/2,z),(x-w/2,y+d/2,z)]
    q=[(a,b,c+h) for a,b,c in p]
    face(p,layer); face(q,layer)
    for i in range(4): face([p[i],p[(i+1)%4],q[(i+1)%4],q[i]],layer)

def tube(x,y,z,r,h,layer,inner=0):
    n=32
    for i in range(n):
        a,b=2*pi*i/n,2*pi*(i+1)/n
        p=[(x+r*cos(a),y+r*sin(a),z),(x+r*cos(b),y+r*sin(b),z)]
        q=[(u,v,z+h) for u,v,_ in p]
        face([p[0],p[1],q[1],q[0]],layer)
        s=[(x+inner*cos(a),y+inner*sin(a),z),(x+inner*cos(b),y+inner*sin(b),z)]
        t=[(u,v,z+h) for u,v,_ in s]
        face([p[0],p[1],s[1],s[0]],layer); face([q[0],q[1],t[1],t[0]],layer)
        if inner: face([s[0],s[1],t[1],t[0]],layer)

def line(a,b,layer='SIGNAL'):
    entity('LINE',layer,[(10,a[0]),(20,a[1]),(30,a[2]),(11,b[0]),(21,b[1]),(31,b[2])])

def text(s,x,y,z=0,size=2.4):
    entity('TEXT','LABELS',[(10,x),(20,y),(30,z),(40,size),(1,s),(7,'STANDARD')])

def call(s,p,q):
    line(p,q,'LABELS'); text(s,*q,size=2.2)

def board(x,y,z,w,d,name,layer):
    box(x,y,z,w,d,1.6,layer)
    box(x,y,z+1.6,7,7,1.5,layer)
    for side in [-1,1]:
        for i in range(6): tube(x+side*(w/2-1.5),y-d/2+2+i*(d-4)/5,z+1.6,.65,1,'POWER')
    return (x,y,z+3.1)

# Drone assembly: approximate envelopes from the existing concept.
text('DRONEX - DRONE / LEFT-HAND REMOTE / CIRCUITS',-65,100,0,5)
text('REV B | 2026-10-05 | mm | 3D faces + editable wiring | prototype layout',-65,92,0,2.5)
text('DRONE - 90 mm motor diagonal',-65,78,0,3.5)
box(0,0,0,32,32,2.3,'DRONE_FRAME')
positions=[(-31.82,31.82),(31.82,31.82),(31.82,-31.82),(-31.82,-31.82)]
for i,(x,y) in enumerate(positions):
    # Physical arms with rectangular cross-section.
    v=(-y/45*3,x/45*3)
    p=[(v[0],v[1],0),(x+v[0],y+v[1],0),(x-v[0],y-v[1],0),(-v[0],-v[1],0)]
    q=[(a,b,2.3) for a,b,_ in p]
    face(p,'DRONE_FRAME'); face(q,'DRONE_FRAME')
    for j in range(4): face([p[j],p[(j+1)%4],q[(j+1)%4],q[j]],'DRONE_FRAME')
    tube(x,y,0,19,23,'DRONE_FRAME',17.5)
    tube(x,y,2.3,5.5,14,'DRONE_MOTORS')
    tube(x,y,16.3,1,4,'DRONE_MOTORS')
    box(x,y,20,31,4,.8,'DRONE_MOTORS')
    tube(x,y,20,2,1,'DRONE_MOTORS')
    text('M%d %s'%(i+1,'CCW' if i%2==0 else 'CW'),x-10,y+21,24,2.2)
    line((x,y,3),(x*.3,y*.3,4),'POWER')
    line((x+1,y,3),(x*.3+1,y*.3,4),'GROUND')
    line((x-1,y,3),(x*.3-1,y*.3,4),'POWER')
board(0,0,3.5,25.5,25.5,'ESC','DRONE_ELECTRONICS')
for x in [-10,10]:
    for y in [-10,10]: tube(x,y,5,1.5,4,'DRONE_FRAME')
board(0,0,9,25.5,25.5,'FC','DRONE_ELECTRONICS')
board(0,-24,9,28,18,'ESP32','DRONE_ELECTRONICS')
box(0,-24,12,16,12,2,'DRONE_ELECTRONICS')
box(0,0,-9,54,20,8,'DRONE_ELECTRONICS')
line((4,-15,11),(4,-10,11))
call('F4/F7 flight controller + IMU; exact board TBD',(0,0,12),(55,28,24))
call('1S 4-in-1 DShot ESC >=5A/ch; model TBD',(9,0,4),(55,18,14))
call('ESP32-WROOM-32 bridge (proposed)',(0,-24,14),(55,-14,18))
call('1103 brushless motor; brand / KV TBD',(31.82,31.82,16),(55,49,25))
call('31mm 2-blade propeller (proposed)',(31.82,31.82,21),(55,60,27))
call('1S 450mAh LiPo; pack model TBD',(27,0,-5),(55,-30,4))

# Remote assembly with left thumb on -X and fingers +Y.
rx=230
text('LEFT-HAND REMOTE - proposed component selection',165,78,0,3.5)
box(rx,0,0,45,65,2.2,'REMOTE_FRAME')
for y in [-26,26]: box(rx,y,-1,76,12,1,'REMOTE_FRAME')
box(rx,-15,2.2,38,25,2,'REMOTE_FRAME')
for x in [-18,18]: box(rx+x,-15,4.2,2,25,9,'REMOTE_FRAME')
board(rx,-15,4.2,28,18,'ESP32','REMOTE_ELECTRONICS')
board(rx,12,2.2,16,12,'IMU','REMOTE_ELECTRONICS')
box(rx,0,-8,36,18,7,'REMOTE_ELECTRONICS')
for x in [-8,8]:
    box(rx+x,57,3,5,55,.7,'REMOTE_SENSORS')
    line((rx+x,29,3),(rx+x,-5,7))
# Thumb strip points toward left thumb.
box(rx-29,24,3,55,5,.7,'REMOTE_SENSORS')
line((rx-10,24,4),(rx-9,-5,7))
call('ESP32-WROOM-32 module (proposed)',(rx,-15,9),(270,-18,18))
call('MPU-6050 / GY-521 breakout (proposed)',(rx,12,6),(270,21,15))
call('Spectra Symbol SEN-10264 2.2in flex x3 (proposed)',(rx+8,65,4),(270,57,12))
call('1S 500mAh LiPo; exact pack TBD',(rx+17,0,-5),(270,-32,2))

# Schematics use actual pin terminals and net labels, no implied power supply.
def block(x,y,w,h,title,pins):
    for a,b in [((x,y,0),(x+w,y,0)),((x+w,y,0),(x+w,y+h,0)),((x+w,y+h,0),(x,y+h,0)),((x,y+h,0),(x,y,0))]: line(a,b,'CIRCUIT')
    text(title,x+2,y+h-5,size=2.5)
    terminals={}
    for i,(name,net) in enumerate(pins):
        py=y+h-12-i*6
        line((x-5,py,0),(x,py,0),'CIRCUIT')
        text(name,x+2,py-1,size=2)
        text(net,x-43,py-1,size=1.8)
        terminals[name]=(x-5,py,0)
    return terminals

text('DRONE CONTROL / FLIGHT CIRCUIT',-65,-84,size=3.5)
block(-20,-169,80,75,'ESP32-WROOM-32 bridge',[
 ('3V3','3V3_BRIDGE'),('GND','GND'),('GPIO17 TX2','FC_RX'),('GPIO16 RX2','FC_TX')])
block(130,-169,92,75,'F4/F7 FC (model TBD)',[
 ('RX','FC_RX'),('TX','FC_TX'),('5V','BEC_5V'),('GND','GND'),('M1..M4','DSHOT1..4')])
block(295,-169,95,75,'1S DShot ESC (model TBD)',[
 ('SIG1..4','DSHOT1..4'),('VBAT','1S_BAT+'),('GND','GND'),('5V BEC','BEC_5V, IF FITTED'),('OUT1..4','MOTOR 3-PHASE x4')])
text('Bridge: dedicated 3.3V regulator sized for ESP32 peak current; share FC ground.',-65,-180,size=2.3)
text('WiFi UDP remote -> bridge UART -> FC stabilization -> DShot ESC -> brushless motors.',-65,-186,size=2.3)

text('LEFT-HAND REMOTE CIRCUIT',-65,-207,size=3.5)
block(-20,-299,95,82,'ESP32-WROOM-32 remote',[
 ('3V3 / GND','3V3_REMOTE / GND'),('GPIO21 SDA','I2C_SDA'),('GPIO22 SCL','I2C_SCL'),('GPIO34 ADC1','FLEX_THUMB'),('GPIO35 ADC1','FLEX_INDEX'),('GPIO32 ADC1','FLEX_MIDDLE')])
block(145,-271,95,54,'MPU-6050 / GY-521',[
 ('VCC / GND','3V3_REMOTE / GND'),('SDA / SCL','I2C_SDA / I2C_SCL'),('AD0','GND (0x68)')])
block(300,-285,95,68,'SEN-10264 flex x3',[
 ('Sensor end A','3V3_REMOTE'),('Sensor end B','ADC NODE'),('10k resistor','ADC NODE -> GND'),('100nF capacitor','ADC NODE -> GND')])
text('Each sensor divider is separate: thumb GPIO34, index GPIO35, middle GPIO32.',-65,-310,size=2.3)
text('Power: 1S LiPo -> protected charger -> 3.3V buck-boost -> remote ESP32 / sensors.',-65,-316,size=2.3)

text('REFERENCE IMAGE CIRCUIT - four servos represent a bench setup',-65,-340,size=3.5)
block(-20,-435,105,86,'ESP32 DevKit V1 (image)',[
 ('GPIO21 / GPIO22','SDA / SCL'),('GPIO16 RX2','GPS_TX'),('GPIO17 TX2','GPS_RX'),('GPIO25/26/27/33','SERVO1/2/3/4 SIG'),('3V3','SENSOR_3V3'),('GND','GND')])
block(150,-400,100,51,'NEO-6M GPS (image)',[
 ('TX / RX','GPS_TX / GPS_RX'),('VCC / GND','MATCH BREAKOUT / GND')])
block(150,-455,100,48,'MPU6050 + BMP280 (image)',[
 ('SDA / SCL','GPIO21 / GPIO22'),('VCC / GND','3V3 / GND')])
block(305,-415,95,66,'Servo x4 (model unknown)',[
 ('SIG1..4','GPIO25/26/27/33*'),('V+','EXTERNAL SERVO_5V'),('GND','COMMON GND')])
text('*PWM and GPS pins are proposed assignments; supplied image does not establish all pins.',-65,-467,size=2.3)
text('No exact servo, FC, ESC, motor, battery or frame model was supplied; envelopes are illustrative.',-65,-474,size=2.3)

header=pairs([(0,'SECTION'),(2,'HEADER'),(9,'$ACADVER'),(1,'AC1009'),(9,'$MEASUREMENT'),(70,1),(0,'ENDSEC')])
tables=pairs([(0,'SECTION'),(2,'TABLES'),(0,'TABLE'),(2,'LTYPE'),(70,1),(0,'LTYPE'),(2,'CONTINUOUS'),(70,0),(3,'Solid'),(72,65),(73,0),(40,0),(0,'ENDTAB'),(0,'TABLE'),(2,'LAYER'),(70,len(layers))])
for name,color in layers.items(): tables+=pairs([(0,'LAYER'),(2,name),(70,0),(62,color),(6,'CONTINUOUS')])
tables+=pairs([(0,'ENDTAB'),(0,'TABLE'),(2,'STYLE'),(70,1),(0,'STYLE'),(2,'STANDARD'),(70,0),(40,0),(41,1),(50,0),(71,0),(42,2.5),(3,'txt'),(4,''),(0,'ENDTAB'),(0,'ENDSEC')])
output=Path(__file__).with_name('DRONEX_drone_and_left_hand_remote_3D.dxf')
output.write_text(header+tables+pairs([(0,'SECTION'),(2,'ENTITIES')])+''.join(entities)+pairs([(0,'ENDSEC'),(0,'EOF')]),encoding='ascii')
print(f'{output.name}: {len(entities)} entities, {output.stat().st_size} bytes')

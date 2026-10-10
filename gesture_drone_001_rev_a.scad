// GESTURE-DRONE-001 REV A — 3D assembly / explanatory CAD model
// Units: millimetres. Open in OpenSCAD; F5 previews, F6 renders.
// Nominal platform: 1S, 90 mm motor-to-motor diagonal, protected tiny-whoop class.

$fn = 40;

// ---- Master dimensions -----------------------------------------------------
wheelbase = 90;
motor_r = wheelbase / (2 * sqrt(2));   // 31.82 mm from centre in X and Y
duct_od = 38;
duct_wall = 1.35;
duct_h = 8;
frame_t = 2.3;
motor_d = 11;
motor_h = 14;
prop_d = 31;
prop_t = 0.8;
stack_xy = 25.5;

show_labels = true;
show_wiring = true;
show_guard_reference = true;

module rounded_box(x, y, z, r) {
    hull()
        for (ix = [-x/2+r, x/2-r])
            for (iy = [-y/2+r, y/2-r])
                translate([ix, iy, 0]) cylinder(h=z, r=r);
}

module plate(x, y, z, r=2) {
    translate([0, 0, z/2]) rounded_box(x, y, z, r);
}

module top_label(s, p, size=3) {
    if (show_labels)
        color([0.05, 0.05, 0.05])
        translate(p)
            linear_extrude(height=0.35)
                text(s, size=size, halign="center", valign="center");
}

module leader(s, start, end, size=2.5) {
    if (show_labels) {
        color("black") {
            hull() {
                translate(start) sphere(r=0.35);
                translate(end) sphere(r=0.35);
            }
            translate([end[0], end[1], end[2]+0.1])
                linear_extrude(height=0.3)
                    text(s, size=size, halign="left", valign="center");
        }
    }
}

module arm_to(x, y) {
    // Rectangular arm aligned from the central stack to each motor duct.
    length = sqrt(x*x + y*y) - 12;
    angle = atan2(y, x);
    color([0.12, 0.12, 0.14])
        rotate([0,0,angle]) translate([length/2+6, 0, frame_t/2])
            rounded_box(length, 6, frame_t, 1.4);
}

module duct(x, y, id) {
    color([0.14, 0.14, 0.17, 0.92])
    translate([x,y,0])
    difference() {
        cylinder(h=duct_h, r=duct_od/2);
        translate([0,0,-1]) cylinder(h=duct_h+2, r=duct_od/2-duct_wall);
        // Bottom relief makes ducts printable and shows the prop cavity.
        translate([0,0,-1]) cylinder(h=frame_t+1, r=duct_od/2-duct_wall-1);
    }
    top_label(id, [x-8,y+20,duct_h+1], 2.3);
}

module motor(x, y, cw=true) {
    // 1103-class motor model: bell, base, shaft and two-blade prop.
    color("slategray") translate([x,y,frame_t]) cylinder(h=motor_h, r=motor_d/2);
    color("silver") translate([x,y,frame_t+motor_h]) cylinder(h=2.2, r=3.5);
    color("silver") translate([x,y,frame_t+motor_h+2]) cylinder(h=4, r=1.1);
    color([0.25,0.25,0.28,0.78])
    translate([x,y,frame_t+motor_h+4])
    for (a=[0,180]) rotate([0,0,a+(cw ? 20 : -20)])
        translate([prop_d/4,0,0]) rounded_box(prop_d/2, 5, prop_t, 2.3);
    color("black") translate([x,y,frame_t+motor_h+3.8]) cylinder(h=1, r=2.2);
}

module esc_board() {
    // ESC immediately above frame; outputs lead out to all four motors.
    color([0.08,0.42,0.15]) translate([0,0,frame_t+1.4]) plate(stack_xy, stack_xy, 1.6, 2.2);
    for (x=[-9,9]) for (y=[-9,9])
        color("gold") translate([x,y,frame_t+3.1]) cylinder(h=0.5,r=1.35);
    top_label("4-IN-1 ESC", [0,0,frame_t+3.9], 2.5);
}

module fc_board() {
    // Soft standoffs isolate IMU board from motor vibration.
    for (x=[-10,10]) for (y=[-10,10])
        color([0.15,0.15,0.15]) translate([x,y,frame_t+3]) cylinder(h=4,r=1.8);
    color([0.10,0.25,0.72]) translate([0,0,frame_t+7]) plate(stack_xy, stack_xy, 1.6, 2.2);
    color("black") translate([0,0,frame_t+8.7]) cube([7,7,1.3],center=true);
    color("white") translate([0,0,frame_t+10.1]) cylinder(h=0.3,r=2.5);
    top_label("F4 FC + IMU", [0,0,frame_t+10.5], 2.3);
}

module esp32_bridge() {
    // ESP32 on rear upper deck. Antenna overhang remains clear of carbon and ESC wiring.
    color([0.10,0.40,0.18]) translate([0,-22,frame_t+8]) plate(30,18,2.2,2);
    color("silver") translate([0,-30,frame_t+10.4]) cube([12,4,1.2],center=true);
    color([0.75,0.1,0.1,0.55]) translate([0,-34,frame_t+11]) cube([28,7,0.6],center=true);
    top_label("ESP32", [0,-21,frame_t+11.1], 2.8);
    top_label("ANTENNA KEEP-OUT", [0,-34,frame_t+12], 1.8);
}

module battery() {
    // Battery underside keeps CG centered and makes the top electronics accessible.
    color([0.10,0.10,0.12]) translate([0,0,-8]) rounded_box(54,20,7,2);
    color("red") translate([-8,-12,-4.5]) cube([8,2,2],center=true);
    color("black") translate([2,-12,-4.5]) cube([8,2,2],center=true);
    top_label("1S 450mAh LiPo", [0,0,-0.7], 2.5);
}

module wire_between(a,b,r=0.65,c="gold") {
    if (show_wiring)
        color(c) hull() { translate(a) sphere(r=r); translate(b) sphere(r=r); }
}

module wiring() {
    // Four DShot signal routes and motor power leads (illustrative, not a harness drawing).
    motor_pts = [[-motor_r,motor_r], [motor_r,motor_r], [motor_r,-motor_r], [-motor_r,-motor_r]];
    for (p=motor_pts) {
        wire_between([p[0]*0.35,p[1]*0.35,frame_t+3.4], [p[0],p[1],frame_t+2], 0.55, "gold");
        wire_between([p[0]*0.40,p[1]*0.40,frame_t+2.6], [p[0]+1,p[1]-1,frame_t+2], 0.45, "red");
        wire_between([p[0]*0.40,p[1]*0.40,frame_t+2.2], [p[0]-1,p[1]+1,frame_t+2], 0.45, "black");
    }
    // ESP32 UART and 3.3 V connection to FC.
    wire_between([0,-14,frame_t+9], [0,-7,frame_t+9], 0.45, "cyan");
    wire_between([5,-14,frame_t+9], [5,-7,frame_t+9], 0.45, "orange");
}

module dimensions() {
    if (show_guard_reference) {
        color([0.25,0.25,0.25,0.38]) {
            // Motor diagonal reference
            hull() { translate([-motor_r,-motor_r,duct_h+18]) sphere(r=.35); translate([motor_r,motor_r,duct_h+18]) sphere(r=.35); }
            // Centre axes
            translate([0,0,duct_h+0.5]) cube([wheelbase+25,.4,.3],center=true);
            translate([0,0,duct_h+0.5]) cube([.4,wheelbase+25,.3],center=true);
        }
        top_label("90 mm MOTOR DIAGONAL", [0,0,duct_h+20], 3);
    }
}

module assembly() {
    // Four ducts and X arms — M1/M3 CCW, M2/M4 CW convention in this drawing.
    positions = [[-motor_r,motor_r], [motor_r,motor_r], [motor_r,-motor_r], [-motor_r,-motor_r]];
    labels = ["M1 CCW", "M2 CW", "M3 CCW", "M4 CW"];
    for (i=[0:3]) {
        arm_to(positions[i][0], positions[i][1]);
        duct(positions[i][0], positions[i][1], labels[i]);
        motor(positions[i][0], positions[i][1], i==1 || i==3);
    }
    color([0.12,0.12,0.14]) plate(32,32,frame_t,3);
    esc_board();
    fc_board();
    esp32_bridge();
    battery();
    wiring();
    dimensions();

    // Callouts are deliberately offset to keep the assembly visible.
    leader("PROP GUARD / DUCT", [-motor_r,motor_r,duct_h], [-68,52,duct_h+2], 2.6);
    leader("1103 MOTOR + 31mm PROP", [motor_r,motor_r,frame_t+motor_h+5], [48,57,duct_h+9], 2.5);
    leader("VIBRATION-ISOLATED FC", [11,8,frame_t+9], [50,13,frame_t+13], 2.5);
    leader("4-IN-1 ESC (DSHOT x4)", [11,-8,frame_t+4], [47,-3,frame_t+5], 2.5);
    leader("ESP32 WiFi / UART BRIDGE", [15,-22,frame_t+11], [49,-29,frame_t+14], 2.4);
    leader("BATTERY BELOW CG", [23,0,-5], [52,-18,3], 2.5);
}

assembly();

// Fabrication / integration notes:
// - This is a fit-and-function layout, not a certified airframe design.
// - Select a 1S-rated FC/ESC and confirm its 3.3 V regulator can supply the ESP32 peak current.
// - Configure an FC failsafe and retain a physical arming method before installing props.

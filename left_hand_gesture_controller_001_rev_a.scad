// LHGC-001 REV A — left-hand wearable gesture controller
// Units: millimetres. Open in OpenSCAD; press F5 to preview or F6 to render.
// Coordinate system: +Y points from the wrist toward the fingertips; left thumb is -X.

$fn = 36;

// ---------- Print / fit parameters ----------
plate_x = 45;
plate_y = 65;
plate_z = 2.2;
plate_radius = 5;
case_x = 38;
case_y = 25;
case_z = 12;
wall = 1.6;
strap_width = 18;

// ---------- Component envelopes ----------
esp_x = 28;
esp_y = 18;
esp_z = 4;
imu_x = 16;
imu_y = 12;
imu_z = 3;
battery_x = 36;
battery_y = 18;
battery_z = 7;
flex_w = 5;
flex_t = 0.7;
flex_l = 63;

show_glove_reference = true;
show_labels = true;

module rounded_box(x, y, z, r) {
    hull() {
        for (px = [-x/2 + r, x/2 - r])
            for (py = [-y/2 + r, y/2 - r])
                translate([px, py, 0]) cylinder(h = z, r = r);
    }
}

module label3d(message, pos, size = 3) {
    if (show_labels)
        color([0.05, 0.05, 0.05])
        translate(pos)
            linear_extrude(height = 0.35)
                text(message, size = size, halign = "center", valign = "center");
}

module slot(x, y, z) {
    translate([x, y, z]) cube([strap_width, 5, 4], center = true);
}

module controller_case() {
    // Lower wrist electronics pod. Case intentionally leaves antenna end clear.
    color("dimgray")
    difference() {
        translate([0, -20, plate_z]) rounded_box(case_x, case_y, case_z, 4);
        translate([0, -20, plate_z + wall]) rounded_box(case_x - 2*wall, case_y - 2*wall, case_z, 2.7);
        // USB / programming opening at wrist edge
        translate([0, -case_y/2 - 20, plate_z + 6]) cube([12, 5, 5], center = true);
    }

    // ESP32 board, mounted inside case with antenna at +Y edge.
    color([0.05, 0.35, 0.15])
        translate([0, -20, plate_z + wall + 1]) cube([esp_x, esp_y, esp_z], center = true);
    color("silver")
        translate([0, -9, plate_z + wall + 3]) cube([12, 3, 1], center = true);
    label3d("ESP32", [0, -21, plate_z + case_z + 0.1], 3.2);
}

module imu_board() {
    // Centered near palm: neutral axes when hand is held palm-down.
    color([0.10, 0.25, 0.75])
        translate([0, 10, plate_z + 1]) cube([imu_x, imu_y, imu_z], center = true);
    color("white")
        translate([0, 10, plate_z + 4.1]) cylinder(h = 0.4, r = 2.5);
    label3d("IMU", [0, 10, plate_z + 4.5], 2.6);
}

module battery_pack() {
    // Battery held against underside to preserve a low, central mass.
    color([0.15, 0.15, 0.15])
        translate([0, -2, -battery_z]) rounded_box(battery_x, battery_y, battery_z, 2);
    color("red") translate([-12, -12, -4]) cube([8, 2, 2], center = true);
    color("black") translate([ -4, -12, -4]) cube([8, 2, 2], center = true);
    label3d("1S 500mAh", [0, -2, -battery_z - 0.1], 2.6);
}

module flex_sensor(pos, angle, name) {
    // Flexible-resistive sensor strip; maintain a generous bend radius at plate exit.
    color([0.95, 0.45, 0.06])
        translate(pos)
            rotate([0, 0, angle])
                translate([0, flex_l/2, plate_z + 0.5])
                    cube([flex_w, flex_l, flex_t], center = true);
    label3d(name, [pos[0], pos[1] + 38, plate_z + 1.3], 2.3);
}

module glove_reference() {
    // Visual-only hand silhouette reference; not a printable component.
    if (show_glove_reference) {
        color([0.95, 0.75, 0.55, 0.18]) {
            translate([0, 15, -0.6]) rounded_box(62, 110, 0.5, 18);
            translate([-34, 26, -0.6]) rotate([0, 0, -38]) rounded_box(16, 55, 0.5, 7);
            translate([-18, 84, -0.6]) rounded_box(12, 52, 0.5, 6);
            translate([0, 89, -0.6]) rounded_box(12, 60, 0.5, 6);
            translate([17, 85, -0.6]) rounded_box(11, 54, 0.5, 5.5);
            translate([32, 76, -0.6]) rounded_box(10, 43, 0.5, 5);
        }
    }
}

module wearable_assembly() {
    glove_reference();

    // TPU or PETG base plate, strap slots at each end.
    color([0.18, 0.18, 0.22])
    difference() {
        rounded_box(plate_x, plate_y, plate_z, plate_radius);
        slot(0, -27, plate_z/2);
        slot(0, 27, plate_z/2);
        // Ventilation / wire-routing holes
        for (x = [-13, 13])
            for (y = [-4, 18]) translate([x, y, -1]) cylinder(h = 6, r = 1.5);
    }

    // Hook-and-loop straps
    color([0.08, 0.08, 0.08]) {
        translate([0, -29, plate_z/2]) cube([75, strap_width, 1.5], center = true);
        translate([0, 29, plate_z/2]) cube([75, strap_width, 1.5], center = true);
    }

    controller_case();
    imu_board();
    battery_pack();

    // Sensor locations correspond to thumb, index and middle fingers of LEFT hand.
    flex_sensor([-30, 18, 0], -38, "THUMB");
    flex_sensor([-9, 31, 0], 0, "INDEX");
    flex_sensor([8, 31, 0], 0, "MIDDLE");

    // Antenna keep-out indicator — orientation and no-metal zone only.
    color([0.9, 0.1, 0.1, 0.45])
        translate([0, -5.5, plate_z + 8]) cube([28, 6, 0.6], center = true);
    label3d("ANTENNA KEEP-OUT", [0, -5.5, plate_z + 8.7], 2.3);
}

wearable_assembly();

// Optional isolated-print exports:
// translate([75, 0, 0]) difference() { rounded_box(plate_x, plate_y, plate_z, plate_radius); }
// translate([125, 0, 0]) controller_case();

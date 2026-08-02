// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// OpenSCAD 3D Enclosure Model for Caravel Direct-RF Development Board

$fn = 100;

// Enclosure Dimensions
wall_thickness = 2.0;
board_width = 85.0;
board_length = 55.0;
board_height = 15.0;

module base_enclosure() {
    difference() {
        // Outer Shell
        cube([board_width + 2*wall_thickness, board_length + 2*wall_thickness, board_height + wall_thickness]);
        
        // Inner Cavity
        translate([wall_thickness, wall_thickness, wall_thickness])
            cube([board_width, board_length, board_height + 1.0]);
            
        // SMA Connector Port Cutouts for RF I/Q Signals
        translate([-1.0, 15.0, 8.0])
            rotate([0, 90, 0])
                cylinder(r=3.5, h=wall_thickness + 2.0);
                
        translate([-1.0, 35.0, 8.0])
            rotate([0, 90, 0])
                cylinder(r=3.5, h=wall_thickness + 2.0);
                
        // USB-C Power/Telemetry Port Cutout
        translate([board_width/2, -1.0, 6.0])
            cube([12.0, wall_thickness + 2.0, 6.0]);
    }
}

base_enclosure();

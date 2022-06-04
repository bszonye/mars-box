echo("\n\n====== TERRAFORMING MARS ORGANIZER ======\n\n");

// naming conventions
// A  angle
// V  vector  [W, H] or [W, D, H] or [x, y, z]
// W  width
// D  depth, diameter, thickness
// H  height
// R  radius
// N  number

Qdraft = 15;  // 24 segments per circle (aligns with axes)
Qfinal = 5;  // 72 segments per circle
$fa = Qdraft;
$fs = 0.1;

inch = 25.4;
phi = (1+sqrt(5))/2;

// filament dimensions
Hlayer = 0.2;
extrusion_width = 0.45;
extrusion_overlap = Hlayer * (1 - PI/4);
extrusion_spacing = extrusion_width - extrusion_overlap;

// minimum sizes and rounding
epsilon = 0.01;
function eround(x, e=epsilon) = e * round(x/e);
function eceil(x, e=epsilon) = e * ceil(x/e);
function efloor(x, e=epsilon) = e * floor(x/e);
function tround(x) = eround(x, e=0.05);  // twentieths of a millimeter
function tceil(x) = eceil(x, e=0.05);  // twentieths of a millimeter
function tfloor(x) = efloor(x, e=0.05);  // twentieths of a millimeter

// tidy measurements
function vround(v) = [for (x=v) tround(x)];
function vceil(v) = [for (x=v) tceil(x)];
function vfloor(v) = [for (x=v) tfloor(x)];

// fit checker for assertions
// * vspec: desired volume specification
// * vxmin: exact minimum size from calculations or measurements
// * vsmin: soft minimum = vround(vxmin)
// true if vspec is larger than either minimum, in all dimensions.
// logs its parameters if vtrace is true or the comparison fails.
vtrace = true;
function vfit(vspec, vxmin, title="vfit") = let (vsmin = vround(vxmin))
    (vtrace && vtrace(title, vxmin, vsmin, vspec)) ||
    (vxmin.x <= vspec.x || vsmin.x <= vspec.x) &&
    (vxmin.y <= vspec.y || vsmin.y <= vspec.y) &&
    (vxmin.z <= vspec.z || vsmin.z <= vspec.z) ||
    (!vtrace && vtrace(title, vxmin, vsmin, vspec));
function vtrace(title, vxmin, vsmin, vspec) =  // returns undef
    echo(title) echo(vspec=vspec) echo(vsmin=vsmin) echo(vxmin=vxmin)
    echo(inch=[for (i=vspec) eround(i/inch)]);

function sum(v) = v ? [for(p=v) 1]*v : 0;

// basic metrics
Hfloor = 1.6;
Dwall = 1.2;
Dcut = eround(2/3*Dwall);  // cutting margin for negative spaces
Dgap = 0.1;  // gap between close-fitting parts
Rint = Dwall/2;  // internal corner radius
Rext = Rint + Dwall;  // external corner radius
echo(Hfloor=Hfloor, Dwall=Dwall, Dgap=Dgap, Dcut=Dcut, Rint=Rint, Rext=Rext);

// component metrics
// all cube dimensions require ±0.1mm tolerance
Dgold = 10.4;
Dsilver = 8.3;
Dcopper = 7.5;
Dcube = 8.0;  // player color cubes
Vcolony = [101.2, 58.1];  // area of colony board
Rcolony = [27, 25];  // radial axes of colony board corners
Hcolony = 1.9;  // thickness of colony board

// utility modules
module raise(z=Hfloor+epsilon) {
    translate([0, 0, z]) children();
}
module prism(h, shape=undef, r=undef, r1=undef, r2=undef,
             scale=1, center=false) {
    module curve() {
        ri = !is_undef(r1) ? r1 : !is_undef(r) ? r : 0;  // inside turns
        ro = !is_undef(r2) ? r2 : !is_undef(r) ? r : 0;  // outside turns
        if (ri || ro) offset(r=ro) offset(r=-ro-ri) offset(r=ri) children();
        else children();
    }
    linear_extrude(height=h, scale=scale, center=center) curve()
    if (is_undef(shape)) children();
    else if (is_list(shape) && is_list(shape[0])) polygon(shape);
    else square(shape, center=true);
}

module colony_outline(dr=0) {
    r = Rcolony + [dr, dr];
    v = Vcolony - 2*Rcolony;
    echo(r=r, v=v);
    offset(r=dr) hull() {
        //square([v.x + 2*Rcolony.x, v.y], center=true);
        //square([v.x, v.y + 2*Rcolony.y], center=true);
        for (i=[-1,+1]) for (j=[-1,+1])
            translate([i*v.x, j*v.y]/2) scale(Rcolony) circle();
    }
}
module colony_board() {
    prism(Hcolony) colony_outline();
}
module colony_frame(origin=[0,0], color=undef) {
    h = Hfloor + Hcolony;
    dx = 10;
    v1 = [7*dx + Dwall, dx + Dwall];
    o0 = [0, -13.45];
    o1 = [o0.x - origin.x, o0.y + origin.y];
    echo(o1=o1);
    color(color) difference() {
        prism(h) colony_outline(Dwall);
        raise(Hfloor) prism(h) colony_outline();
        raise(-Dcut) {
            // colony track
            prism(h, r2=Rint) difference() {
                colony_outline(-Dwall);
                translate(o1) {
                    offset(r=Rext) offset(r=-Rext) square(v1, center=true);
                    square([Vcolony.x, Dwall], center=true);
                }
            }
            // cube slots
            translate(o1) {
                for (i=[-3:1:+3]) translate([dx*i, 0])
                prism(h, dx - Dwall, r2=Rint);
            }
        }
    }
}

// scale adjustments:
// to counteract shrinkage, scale X & Y by 100.5% in slicer

print_quality = Qfinal;  // or Qdraft

*colony_frame($fa=print_quality/2);
// Europa
*colony_frame(origin=[-Dwall/2, Dwall], $fa=print_quality/2);
// Titan
*colony_frame(origin=[0, Dwall], $fa=print_quality/2);
// Callisto, Triton
*colony_frame(origin=[0, Dwall/2], $fa=print_quality/2);
// Enceladus, Pluto
*colony_frame(origin=[-Dwall, 0], $fa=print_quality/2);
// Ceres, Io, Luna (median position)
colony_frame(origin=[-Dwall/2, 0], $fa=print_quality/2);
// Ganymede, Miranda
*colony_frame(origin=[0, -Dwall], $fa=print_quality/2);

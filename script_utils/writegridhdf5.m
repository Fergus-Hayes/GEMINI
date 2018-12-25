function writegridhdf5(xg, outdir)

validateattributes(xg, {'struct'}, {'scalar'})
validateattributes(outdir, {'char'}, {'vector'})
%% STORE all GRID DATA 
% INCLUDING STUFF NOT NEEDED BY FORTRAN CODE, BUT POSSIBLY USEFUL FOR PLOTTING
outdir = resolvepath(outdir);

mkdir(outdir)
fn = [outdir,filesep,'simgrid.h5'];
delete(fn)
disp(['writing ',fn])

h5w(fn,'lx',xg.lx)
h5w(fn,'x1',xg.x1);    %coordinate values
h5w(fn,'x1i', xg.x1i)
h5w(fn,'dx1b',xg.dx1b)
h5w(fn,'dx1h',xg.dx1h)

h5w(fn,'x2',xg.x2)
h5w(fn,'x2i',xg.x2i)
h5w(fn,'dx2b',xg.dx2b)
h5w(fn,'dx2h',xg.dx2h)

h5w(fn,'x3',xg.x3)
h5w(fn,'x3i',xg.x3i)
h5w(fn,'dx3b',xg.dx3b)
h5w(fn,'dx3h',xg.dx3h)

h5w(fn,'h1',xg.h1)   %cell-centered metric coefficients
h5w(fn,'h2',xg.h2)
h5w(fn,'h3',xg.h3)

h5w(fn,'h1x1i',xg.h1x1i)    %interface metric coefficients
h5w(fn,'h2xli',xg.h2x1i)
h5w(fn,'h3xli',xg.h3x1i)

h5w(fn,'h1x2i',xg.h1x2i)
h5w(fn,'h2x2i',xg.h2x2i)
h5w(fn,'h3x2i',xg.h3x2i)

h5w(fn,'h1x3i',xg.h1x3i)
h5w(fn,'h2x3i',xg.h2x3i)
h5w(fn,'h3x3i',xg.h3x3i)

%gravity, geographic coordinates, magnetic field strength? unit vectors?
h5w(fn,'gx1',xg.gx1)    %gravitational field components
h5w(fn,'gx2',xg.gx2)
h5w(fn,'gx3',xg.gx3)

h5w(fn,'alt',xg.alt)    %geographic coordinates
h5w(fn,'glat',xg.glat)
h5w(fn,'glon',xg.glon)

h5w(fn,'Bmag',xg.Bmag)    %magnetic field strength

h5w(fn,'I',xg.I)    %magnetic field inclination

h5w(fn,'nullpts',xg.nullpts)    %points not to be solved


%NOT ALL OF THE REMAIN INFO IS USED IN THE FORTRAN CODE, BUT IT INCLUDED FOR COMPLETENESS
h5w(fn,'e1',xg.e1)   %4D unit vectors (in cartesian components)
h5w(fn,'e2',xg.e2)
h5w(fn,'e3',xg.e3)

h5w(fn,'er',xg.er)    %spherical unit vectors
h5w(fn,'etheta',xg.etheta)
h5w(fn,'ephi',xg.ephi)

h5w(fn,'r',xg.r)    %spherical coordinates
h5w(fn,'theta',xg.theta)
h5w(fn,'phi',xg.phi)

h5w(fn,'x',xg.x)     %cartesian coordinates
h5w(fn,'y',xg.y)
h5w(fn,'z',xg.z)  

end

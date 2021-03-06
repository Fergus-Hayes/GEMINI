function writegrid(xg, outdir, file_format)
%% write grid to raw binary files
% INCLUDes STUFF NOT NEEDED BY FORTRAN CODE BUT POSSIBLY USEFUL FOR PLOTTING

narginchk(3,3)
validateattributes(xg, {'struct'}, {'scalar'}, mfilename, 'grid parameters', 1)
validateattributes(outdir, {'char'}, {'vector'}, mfilename,'output directory',2)
validateattributes(file_format, {'char'}, {'vector'}, mfilename,'raw or hdf5',3)

%% MAKE THE OUTPUT DIRECTORY IF IT DOESN'T EXIST AND NOTIFY USER
outdir = absolute_path(outdir);
if ~is_folder(outdir)
  mkdir(outdir);
  disp(['Created: ', outdir])
end
% malformed paths can be "created" but are not accessible. Bug in Matlab mkdir().
assert(is_folder(outdir), [outdir, ' does not exist'])

switch file_format
  case 'raw', write_raw(outdir, xg)
  case 'hdf5', write_hdf5(outdir, xg)
  otherwise, error(['unknown file format ',file_format])
end

end % function


function write_hdf5(dir_out, xg)

fn = [dir_out, '/simsize.h5'];
disp(['write ',fn])
if isfile(fn), delete(fn), end
h5save(fn, '/lx1', int32(xg.lx(1)))
h5save(fn, '/lx2', int32(xg.lx(2)))
h5save(fn, '/lx3', int32(xg.lx(3)))

fn = [dir_out, '/simgrid.h5'];
disp(['write ',fn])
if isfile(fn), delete(fn), end
h5save(fn, '/x1', xg.x1)
h5save(fn, '/x1i', xg.x1i)
h5save(fn, '/dx1b', xg.dx1b)
h5save(fn, '/dx1h', xg.dx1h)

h5save(fn, '/x2', xg.x2)
h5save(fn, '/x2i', xg.x2i)
h5save(fn, '/dx2b', xg.dx2b)
h5save(fn, '/dx2h', xg.dx2h)

h5save(fn, '/x3', xg.x3)
h5save(fn, '/x3i', xg.x3i)
h5save(fn, '/dx3b', xg.dx3b)
h5save(fn, '/dx3h', xg.dx3h)

h5save(fn, '/h1', xg.h1)
h5save(fn, '/h2', xg.h2)
h5save(fn, '/h3', xg.h3)

h5save(fn, '/h1x1i', xg.h1x1i)
h5save(fn, '/h2x1i', xg.h2x1i)
h5save(fn, '/h3x1i', xg.h3x1i)

h5save(fn, '/h1x2i', xg.h1x2i)
h5save(fn, '/h2x2i', xg.h2x2i)
h5save(fn, '/h3x2i', xg.h3x2i)

h5save(fn, '/h1x3i', xg.h1x3i)
h5save(fn, '/h2x3i', xg.h2x3i)
h5save(fn, '/h3x3i', xg.h3x3i)

h5save(fn, '/gx1', xg.gx1)
h5save(fn, '/gx2', xg.gx2)
h5save(fn, '/gx3', xg.gx3)

h5save(fn, '/alt', xg.alt)
h5save(fn, '/glat', xg.glat)
h5save(fn, '/glon', xg.glon)

h5save(fn, '/Bmag', xg.Bmag)
h5save(fn, '/I', xg.I)
h5save(fn, '/nullpts', xg.nullpts)

h5save(fn, '/e1', xg.e1)
h5save(fn, '/e2', xg.e2)
h5save(fn, '/e3', xg.e3)

h5save(fn, '/er', xg.er)
h5save(fn, '/etheta', xg.etheta)
h5save(fn, '/ephi', xg.ephi)

h5save(fn, '/r', xg.r)
h5save(fn, '/theta', xg.theta)
h5save(fn, '/phi', xg.phi)

h5save(fn, '/x', xg.x)
h5save(fn, '/y', xg.y)
h5save(fn, '/z', xg.z)
end % function


function write_raw(outdir, xg)
freal = 'float64';

filename = [outdir, '/simsize.dat'];
disp(['write ',filename])
fid = fopen(filename, 'w');
fwrite(fid, xg.lx, 'integer*4');
fclose(fid);

fid = fopen([outdir, '/simgrid.dat'], 'w');

fwrite(fid,xg.x1, freal);    %coordinate values
fwrite(fid,xg.x1i, freal);
fwrite(fid,xg.dx1b, freal);
fwrite(fid,xg.dx1h, freal);

fwrite(fid,xg.x2, freal);
fwrite(fid,xg.x2i, freal);
fwrite(fid,xg.dx2b, freal);
fwrite(fid,xg.dx2h, freal);

fwrite(fid,xg.x3, freal);
fwrite(fid,xg.x3i, freal);
fwrite(fid,xg.dx3b, freal);
fwrite(fid,xg.dx3h, freal);

fwrite(fid,xg.h1, freal);   %cell-centered metric coefficients
fwrite(fid,xg.h2, freal);
fwrite(fid,xg.h3, freal);

fwrite(fid,xg.h1x1i, freal);    %interface metric coefficients
fwrite(fid,xg.h2x1i, freal);
fwrite(fid,xg.h3x1i, freal);

fwrite(fid,xg.h1x2i, freal);
fwrite(fid,xg.h2x2i, freal);
fwrite(fid,xg.h3x2i, freal);

fwrite(fid,xg.h1x3i, freal);
fwrite(fid,xg.h2x3i, freal);
fwrite(fid,xg.h3x3i, freal);

%gravity, geographic coordinates, magnetic field strength? unit vectors?
fwrite(fid,xg.gx1, freal);    %gravitational field components
fwrite(fid,xg.gx2, freal);
fwrite(fid,xg.gx3, freal);

fwrite(fid,xg.alt, freal);    %geographic coordinates
fwrite(fid,xg.glat, freal);
fwrite(fid,xg.glon, freal);

fwrite(fid,xg.Bmag, freal);    %magnetic field strength

fwrite(fid,xg.I, freal);    %magnetic field inclination

fwrite(fid,xg.nullpts, freal);    %points not to be solved


%NOT ALL OF THE REMAIN INFO IS USED IN THE FORTRAN CODE, BUT IT INCLUDED FOR COMPLETENESS
fwrite(fid,xg.e1, freal);   %4D unit vectors (in cartesian components)
fwrite(fid,xg.e2, freal);
fwrite(fid,xg.e3, freal);

fwrite(fid,xg.er, freal);    %spherical unit vectors
fwrite(fid,xg.etheta, freal);
fwrite(fid,xg.ephi, freal);

fwrite(fid,xg.r, freal);    %spherical coordinates
fwrite(fid,xg.theta, freal);
fwrite(fid,xg.phi, freal);

fwrite(fid,xg.x, freal);     %cartesian coordinates
fwrite(fid,xg.y, freal);
fwrite(fid,xg.z, freal);

fclose(fid);

end

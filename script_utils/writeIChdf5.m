function writeIChdf5(dmy,time,ns,vsx1,Ts,outdir,outID)
%% WRITE STATE VARIABLE DATA TO BE USED AS INITIAL CONDITIONS FOR SIMULATION.  
% NOTE: WE DO NOT OUTPUT ANY ELECTRODYNAMIC VARIABLES,
% SINCE THEY ARE NOT NEEDED TO STARTUP THE FORTRAN CODE.
%
% INPUT ARRAYS SHOULD BE TRIMMED TO THE CORRECT SIZE
% (I.E. THEY SHOULD *NOT INCLUDE GHOST CELLS*
outdir = resolvepath(outdir);
if ~exist(outdir,'dir')
  mkdir(outdir)
end
fn = [outdir,filesep,outID,'_ICs.h5'];
if exist(fn,'file')
  delete(fn)
end
disp(['writing ',fn])

h5w(fn, '/dmy', dmy)
h5w(fn, '/time',time)
h5w(fn, '/nsall', ns)
h5w(fn, '/vs1all',vsx1)
h5w(fn, '/Tsall',Ts)

end % function

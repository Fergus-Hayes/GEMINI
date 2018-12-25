function writeIChdf5(dmy,time,ns,vsx1,Ts,outdir,outID)
%% WRITE STATE VARIABLE DATA TO BE USED AS INITIAL CONDITIONS FOR SIMULATION.  
% NOTE: WE DO NOT OUTPUT ANY ELECTRODYNAMIC VARIABLES,
% SINCE THEY ARE NOT NEEDED TO STARTUP THE FORTRAN CODE.
%
% INPUT ARRAYS SHOULD BE TRIMMED TO THE CORRECT SIZE
% (I.E. THEY SHOULD *NOT INCLUDE GHOST CELLS*
outdir = resolvepath(outdir);
mkdir(outdir)
fn = [outdir,filesep,outID,'_ICs.h5'];
delete(fn)
disp(['writing ',fn])

h5w(fn, '/dmy', dmy)
h5w(fn, '/time',time)
h5w(fn, '/ns', ns)
h5w(fn, '/vsx1',vsx1)
h5w(fn, '/Ts',Ts)

end % function

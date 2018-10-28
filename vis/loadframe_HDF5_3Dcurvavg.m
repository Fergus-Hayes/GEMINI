function [ne,v1,Ti,Te,J1,v2,v3,J2,J3,Phitop] = loadframe_HDF5_3Dcurvavg(direc, filename)

%% SIMULATION SIZE
fn = [direc,filesep,'inputs/simsize.dat'];
assert(exist(fn,'file')==2, [fn,' does not exist '])

fid=fopen(fn,'r');
lxs=fread(fid,3,'integer*4');
lxs=lxs(:)';
fclose(fid);


%% SIMULATION GRID FILE 
% (NOTE THAT THIS IS NOT THE ENTIRE THING - THAT NEEDS TO BE DONE WITH READGRID.M.  WE NEED THIS HERE TO DO MESHGRIDS
lsp=7;
fn = [direc,filesep,'inputs/simgrid.dat'];
assert(exist(fn,'file')==2, [fn,' does not exist '])

fid=fopen(fn,'r');
x1=fread(fid,lxs(1),'real*8');
x1=x1(:)';
x2=fread(fid,lxs(2),'real*8');
x2=x2(:)';
x3=fread(fid,lxs(3),'real*8');
x3=x3(:)';
fclose(fid);

%% SIMULATIONS RESULTS
fn = [direc,filesep,filename];
assert(exist(fn,'file')==2, [fn,' does not exist '])

simdate=zeros(1,6);    %datevec-style array

if isoctave
  D = load(fn);
  simdate(1:3) = D.time.ymd;
  simdate(4) = D.time.UThour;
  ne = D.neall;
  v1 = D.v1avgall;
  Ti = D.Tavgall;
  Te = D.TEall;
  J1 = D.J1all;
  J2 = D.J2all;
  J3 = D.J3all;
  v2 = D.v2avgall;
  v3 = D.v3avgall;
  Phitop = D.Phiall;
else
  simdate(1:3) = h5read(fn, '/time/ymd');
  simdate(4) = h5read(fn, '/time/UThour');
  %% Number densities
  ne = h5read(fn, '/neall');
  %% Parallel Velocities
  v1 = h5read(fn, '/v1avgall');
  %% Temperatures
  Ti = h5read(fn, '/Tavgall');
  Te = h5read(fn, '/TEall');
  %% Current densities
  J1 = h5read(fn, '/J1all');
  J2 = h5read(fn, '/J2all');
  J3 = h5read(fn, '/J3all');
  %% Perpendicular drifts
  v2 = h5read(fn, '/v2avgall');
  v3 = h5read(fn, '/v3avgall');
  %% Topside potential
  Phitop = h5read(fn, '/Phiall');
end
%% REORGANIZE ACCORDING TO MATLABS CONCEPT OF A 2D or 3D DATA SET
if lxs(2) == 1    %a 2D simulations was done in x1 and x3
 % disp('Detected a 2D simulation (x1,x3) and organizing data accordingly.')
  Jpar=squeeze(J1);
  Jperp2=squeeze(J3);
%  ne=squeeze(ns(:,:,:,lsp));
%  p=ns(:,:,:,1)./ns(:,:,:,lsp);
%  p=squeeze(p);
  vi=squeeze(v1);
  vi2=squeeze(v2);
%  vi3=permute(v3,[3,2,1]);
%  Ti=sum(ns(:,:,:,1:6).*Ts(:,:,:,1:6),4)./ns(:,:,:,lsp);
  Ti=squeeze(Ti);
%  Te=squeeze(Ts(:,:,:,lsp));
  Te=squeeze(Te);

  [X3,X1]=meshgrid(x3,x1);
elseif lxs(3)==1   %a 2D simuluation was done in x1,x2 with internal permutign of arrays by fortran code
 % disp('Detected a 2D simulation (x1,x2) and organizing data accordingly.')
  Jpar=squeeze(J1);
  Jperp2=squeeze(J3);
  vi=squeeze(v1);
  vi2=squeeze(v2);
  Ti=squeeze(Ti);
  Te=squeeze(Te);

  [X2,X1]=meshgrid(x2,x1);
else    %full 3D run 
 % disp('Detected a 3D simulation and organizing data accordingly.')
  Jpar=permute(J1(:,:,:),[3,2,1]);
  Jperp2=permute(J2(:,:,:),[3,2,1]);
  Jperp3=permute(J3(:,:,:),[3,2,1]);
%  ne=permute(ns(:,:,:,lsp),[3,2,1]);
%  p=ns(:,:,:,1)./ns(:,:,:,lsp);
%  p=permute(p,[3,2,1]);
  vi=permute(v1,[3,2,1]);
  vi2=permute(v2,[3,2,1]);
  vi3=permute(v3,[3,2,1]);
%  Ti=sum(ns(:,:,:,1:6).*Ts(:,:,:,1:6),4)./ns(:,:,:,lsp);
%  Ti=permute(Ti,[3,2,1]);
%  Te=permute(Ts(:,:,:,lsp),[3,2,1]);
%  Te=permute(Te,[3,2,1]);

  [X2,X3,X1]=meshgrid(x2,x3,x1);
end % if

end % function

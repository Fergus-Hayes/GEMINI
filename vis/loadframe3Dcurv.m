function [ne,v1,Ti,Te,J1,v2,v3,J2,J3,ns,vs1,Ts,Phitop] = loadframe3Dcurv(direc, filename)

validateattributes(direc, {'char'}, {'vector'}, mfilename, 'data directory', 1)
validateattributes(direc, {'char'}, {'vector'}, mfilename, 'data filename', 2)
%% SIMULATION SIZE
lsp=7;
lxs = simsize(direc);
disp(['sim grid dimensions: ',num2str(lxs)])
%% SIMULATION RESULTS
fsimres = [direc,filesep,filename];
assert(exist(fsimres,'file')==2, [fsimres,' does not exist'])

fid=fopen(fsimres,'r');
simdt(fid);
%% load densities
ns = read4D(fid, lsp, lxs);
%% load Vparallel
vs1 = read4D(fid, lsp, lxs);
v1=sum(ns(:,:,:,1:6).*vs1(:,:,:,1:6),4)./ns(:,:,:,lsp);
%% load temperatures
Ts = read4D(fid, lsp, lxs);
%% load current densities
J1 = read3D(fid, lxs);
J2 = read3D(fid, lxs);
J3 = read3D(fid, lxs);
%% load Vperp
v2 = read3D(fid, lxs);
v3 = read3D(fid, lxs);
%% load topside potential
Phitop = read2D(fid, lxs);

fclose(fid);

%{
fid=fopen('neuinfo.dat','r');
ln=6;
nn=fscanf(fid,'%f',prod(lxs)*ln);
nn=reshape(nn,[lxs(1),lxs(2),lxs(3),ln]);
fclose(fid);
%}


%% REORGANIZE ACCORDING TO MATLABS CONCEPT OF A 2D or 3D DATA SET
if (lxs(2) == 1)    %a 2D simulations was done
  %Jpar=squeeze(J1);
 % Jperp2=squeeze(J3);
  ne=squeeze(ns(:,:,:,lsp));
  %p=ns(:,:,:,1)./ns(:,:,:,lsp);
  %p=squeeze(p);
  %vi=squeeze(v1);
  %vi2=squeeze(v2);
%  vi3=permute(v3,[3,2,1]);
  Ti=sum(ns(:,:,:,1:6).*Ts(:,:,:,1:6),4)./ns(:,:,:,lsp);
  Ti=squeeze(Ti);
  Te=squeeze(Ts(:,:,:,lsp));

%  [X3,X1]=meshgrid(x3,x1);
else    %full 3D run 
%  Jpar=permute(J1(:,:,:),[3,2,1]);
%  Jperp2=permute(J2(:,:,:),[3,2,1]);
%  Jperp3=permute(J3(:,:,:),[3,2,1]);
%  ne=permute(ns(:,:,:,lsp),[3,2,1]);
%  p=ns(:,:,:,1)./ns(:,:,:,lsp);
%  p=permute(p,[3,2,1]);
%  vi=permute(v1,[3,2,1]);
%  vi2=permute(v2,[3,2,1]);
%  vi3=permute(v3,[3,2,1]);
%  Ti=sum(ns(:,:,:,1:6).*Ts(:,:,:,1:6),4)./ns(:,:,:,lsp);
%  Ti=permute(Ti,[3,2,1]);
%  Te=permute(Ts(:,:,:,lsp),[3,2,1]);
%
%  [X2,X3,X1]=meshgrid(x2,x3,x1);

  %Jpar=J1(:,:,:);
  %Jperp2=J2(:,:,:);
  %Jperp3=J3(:,:,:);
  ne=ns(:,:,:,lsp);
  %p=ns(:,:,:,1)./ns(:,:,:,lsp);
  %p=p;
  %vi=v1;
  %vi2=v2;
  %vi3=v3;
  Ti=sum(ns(:,:,:,1:6).*Ts(:,:,:,1:6),4)./ns(:,:,:,lsp);
  Te=Ts(:,:,:,lsp);
end

end % function

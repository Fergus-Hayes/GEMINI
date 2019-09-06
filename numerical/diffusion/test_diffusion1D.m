%LOAD AND PLOT NUMERICAL SOLUTION
function test_diffusion1D(fn)

cwd = fileparts(mfilename('fullpath'));
addpath([cwd,filesep,'../../tests'])
addpath([cwd,filesep,'../../script_utils'])

if exist(fn, 'file') ~= 2, fprintf(2, [fn, ' not found\n']), exit(77), end

fid=fopen(fn);
data=fscanf(fid,'%f',2);
lt=data(1);
lx1=data(2);
x1=fscanf(fid,'%f',lx1+4)';

%M=fscanf(fid,'%f',lx1*5)';
%M=reshape(M,[lx1 5])';
%b=fscanf(fid,'%f',lx1)';

Ts=zeros(lx1,lt);
t=zeros(lt,1);
for it=1:lt
  t(it)=fscanf(fid,'%f',1);
  TsEuler(:,it)=fscanf(fid,'%f',lx1)';
  TsBDF2(:,it)=fscanf(fid,'%f',lx1)';  
  Tstrue(:,it)=fscanf(fid,'%f',lx1)';
end % for

% reltol = 1e-5 for real32
%assert_allclose(Ts(13,end), 0.2757552094055,1e-5,[],'1-D diffusion accuracy')

if ~isinteractive, return, end
%% plots

figure
subplot(131);
imagesc(t,x1(3:end-2),TsEuler)
colorbar
xlabel('time (sec)')
ylabel('distance (m)')
title('1D diffusion (backward Euler)')

subplot(132);
imagesc(t,x1(3:end-2),TsBDF2)
colorbar
xlabel('time (sec)')
ylabel('distance (m)')
title('1D diffusion (TRBDF2)')

subplot(133);
imagesc(t,x1(3:end-2),Tstrue)
colorbar
xlabel('time (sec)')
ylabel('distance (m)')
title('1D diffusion (analytical)')


end % function


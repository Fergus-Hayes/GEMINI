function Efield_BCs(simpath)

validateattributes(simpath, {'char'}, {'vector'})

usehdf = true;
%% Generate Electric Field boundary conditions to initialize simulation
%
% simpath: path to particular simulation e.g. ~/simulations/isinglas

assert(exist(simpath,'directory'), [simpath,' does not exist'])

cwd = fileparts(mfilename('fullpath'));
addpath([cwd,filesep','..',filesep,'..',filesep,'script_utils'])

%% REFERENCE GRID TO USE
dirconfig = '.';
dirgrid = [simpath,filesep,'inputs'];
%% OUTPUT FILE LOCATION
outdir = [simpath,filesep,'inputs',filesep,'Efield_inputs'];
mkdir(outdir)

%% READ IN THE SIMULATION INFORMATION 
% WE NEED TO CREATE THIS FOR THE SIMULATION
[ymd0, UTsec0]=readconfig([dirconfig,filesep,'config.ini']);


%% RELOAD THE GRID (SO THIS ALREADY NEEDS TO BE MADE, AS WELL)
xg = readgrid(dirgrid);
lx1=xg.lx(1); lx2=xg.lx(2); lx3=xg.lx(3);


%% CREATE ELECTRIC FIELD INFO
llon=100;
llat=100;
if (xg.lx(2)==1)    %this is cartesian-specific code
  llon=1;
elseif (xg.lx(3)==1)
  llat=1;
end
thetamin=min(xg.theta(:));
thetamax=max(xg.theta(:));
mlatmin=90-thetamax*180/pi;
mlatmax=90-thetamin*180/pi;
mlonmin=min(xg.phi(:))*180/pi;
mlonmax=max(xg.phi(:))*180/pi;
latbuf=1/100*(mlatmax-mlatmin);
lonbuf=1/100*(mlonmax-mlonmin);
mlat=linspace(mlatmin-latbuf,mlatmax+latbuf,llat);
mlon=linspace(mlonmin-lonbuf,mlonmax+lonbuf,llon);
[MLON,MLAT]=ndgrid(mlon,mlat);
mlonmean=mean(mlon);
mlatmean=mean(mlat);

%% WIDTH OF THE DISTURBANCE
fracwidth=1/7;
mlatsig=fracwidth*(mlatmax-mlatmin);
mlonsig=fracwidth*(mlonmax-mlonmin);
sigx2=fracwidth*(max(xg.x2)-min(xg.x2));

%% TIME VARIABLE (SECONDS FROM SIMULATION BEGINNING)
tmin=0;
tmax=300;
lt=301;
time=linspace(tmin,tmax,lt)';

%% SETUP TIME VARIABLES
ymd=ymd0;
UTsec=UTsec0+time;     %time given in file is the seconds from beginning of hour
UThrs=UTsec/3600;
expdate=cat(2,repmat(ymd,[lt,1]),UThrs,zeros(lt,1),zeros(lt,1));
t=datenum(expdate);

%% CREATE DATA FOR BACKGROUND ELECTRIC FIELDS
Exit=zeros(llon,llat,lt);
Eyit=zeros(llon,llat,lt);
for it=1:lt
  Exit(:,:,it)=zeros(llon,llat);   %V/m
  Eyit(:,:,it)=zeros(llon,llat);
end

%% CREATE DATA FOR BOUNDARY CONDITIONS FOR POTENTIAL SOLUTION
flagdirich=1;   %if 0 data is interpreted as FAC, else we interpret it as potential
Vminx1it=zeros(llon,llat,lt);
Vmaxx1it=zeros(llon,llat,lt);
Vminx2ist=zeros(llat,lt);
Vmaxx2ist=zeros(llat,lt);
Vminx3ist=zeros(llon,lt);
Vmaxx3ist=zeros(llon,lt);
Etarg=50e-3;            % target E value in V/m
pk=Etarg*sigx2.*xg.h2(lx1,floor(lx2/2),1).*sqrt(pi)./2;
x2ctr=1/2*(xg.x2(lx2)+xg.x2(1));
for it=1:lt
    Vminx1it(:,:,it)=zeros(llon,llat);
    Vmaxx1it(:,:,it)=pk.*erf((MLON-mlonmean)/mlonsig);%.*erf((MLAT-mlatmean)/mlatsig);
     Vminx2ist(:,it)=zeros(llat,1);     %these are just slices
     Vmaxx2ist(:,it)=zeros(llat,1);
     Vminx3ist(:,it)=zeros(llon,1);
     Vmaxx3ist(:,it)=zeros(llon,1);
end

%% SAVE DATA
% LEAVE THE SPATIAL AND TEMPORAL INTERPOLATION TO THE
% FORTRAN CODE IN CASE DIFFERENT GRIDS NEED TO BE TRIED.  THE EFIELD DATA DO
% NOT TYPICALLY NEED TO BE SMOOTHED.

if usehdf, error('TODO: HDF5 output'), end

filename=[outdir,filesep,'simsize.dat'];
fid=fopen(filename,'w');
fwrite(fid,llon,'integer*4');
fwrite(fid,llat,'integer*4');
fclose(fid);

filename=[outdir,filesep,'simgrid.dat'];
fid=fopen(filename,'w');
fwrite(fid,mlon,'real*8');
fwrite(fid,mlat,'real*8');
fclose(fid);
for it=1:lt
    UTsec=expdate(it,4)*3600+expdate(it,5)*60+expdate(it,6);
    ymd=expdate(it,1:3);
    filename=datelab(ymd,UTsec);
    filename=[outdir,filename,'.dat']; %#ok<AGROW>
    fid=fopen(filename,'w');
    
    %FOR EACH FRAME WRITE A BC TYPE AND THEN OUTPUT BACKGROUND AND BCs
    fwrite(fid,flagdirich,'real*8');
    fwrite(fid,Exit(:,:,it),'real*8');
    fwrite(fid,Eyit(:,:,it),'real*8');
    fwrite(fid,Vminx1it(:,:,it),'real*8');
    fwrite(fid,Vmaxx1it(:,:,it),'real*8');  
    fwrite(fid,Vminx2ist(:,it),'real*8');
    fwrite(fid,Vmaxx2ist(:,it),'real*8'); 
    fwrite(fid,Vminx3ist(:,it),'real*8');
    fwrite(fid,Vmaxx3ist(:,it),'real*8');     
   
    fclose(fid);
end

end % function
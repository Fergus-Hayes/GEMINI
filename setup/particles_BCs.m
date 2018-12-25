function particles_BCs(simpath, fracwidth)

validateattributes(simpath, {'char'}, {'vector'})
validateattributes(fracwidth, {'numeric'}, {'scalar','positive'})
%% Generate particles state to initialize simulation
%
% simpath: path to particular simulation e.g. ~/simulations/isinglas

assert(exist(simpath,'directory'), [simpath,' does not exist'])

cwd = fileparts(mfilename('fullpath'));
addpath([cwd,filesep','..',filesep,'..',filesep,'script_utils'])

%REFERENCE GRID TO USE
dirconfig = '.';
dirgrid = [simpath,filesep,'inputs'];

%% OUTPUT FILE LOCATION
outdir = [simpath,filesep,'inputs',filesep,'prec_inputs'];
mkdir(outdir)


%% READ IN THE SIMULATION INFORMATION (MEANS WE NEED TO CREATE THIS FOR THE SIMULATION WE WANT TO DO)
[ymd0,UTsec0,tdur]=readconfig([dirconfig,'/config.ini']);

%% RELOAD THE GRID (SO THIS ALREADY NEEDS TO BE MADE, AS WELL)
xg = readgrid(dirgrid);

%% CREATE PRECIPITATION CHARACTERISTICS
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
%mlat=linspace(mlatmin,mlatmax,llat);
%mlon=linspace(mlonmin,mlonmax,llon);
latbuf=1/100*(mlatmax-mlatmin);
lonbuf=1/100*(mlonmax-mlonmin);
mlat=linspace(mlatmin-latbuf,mlatmax+latbuf,llat);
mlon=linspace(mlonmin-lonbuf,mlonmax+lonbuf,llon);
[MLON,MLAT]=ndgrid(mlon,mlat);
mlonmean=mean(mlon);
mlatmean=mean(mlat);

%% WIDTH OF THE DISTURBANCE
mlatsig=fracwidth*(mlatmax-mlatmin);
mlatsig=max(mlatsig,0.01);    %can't let this go to zero...
mlonsig=fracwidth*(mlonmax-mlonmin);

%% TIME VARIABLE (SECONDS FROM SIMULATION BEGINNING)
tmin=0;
tmax=tdur;
%lt=tdur+1;
%time=linspace(tmin,tmax,lt)';
time=tmin:5:tmax;
lt=numel(time);

%% SET UP TIME VARIABLES
ymd=ymd0;
UTsec=UTsec0+time;     %time given in file is the seconds from beginning of hour
UThrs=UTsec/3600;
expdate=cat(2,repmat(ymd,[lt,1]),UThrs(:),zeros(lt,1),zeros(lt,1));
t=datenum(expdate);

%% CREATE THE PRECIPITATION INPUT DATA
Qit=zeros(llon,llat,lt);
E0it=zeros(llon,llat,lt);
for it=1:lt
   Qit(:,:,it)=10*exp(-(MLON-mlonmean).^2/(2*mlonsig^2)).*exp(-(MLAT-mlatmean).^2/(2*mlatsig^2));         %mW/m^2
%  Qit(:,:,it)=5;
  E0it(:,:,it)=5e3;%*ones(llon,llat);     %eV
end


%% SAVE THIS DATA TO APPROPRIATE FILES - LEAVE THE SPATIAL AND TEMPORAL INTERPOLATION TO THE
% FORTRAN CODE IN CASE DIFFERENT GRIDS NEED TO BE TRIED.  THE EFIELD DATA DO NOT NEED TO BE SMOOTHED.
filename=[outdir,'simsize.dat'];
fid=fopen(filename,'w');
fwrite(fid,llon,'integer*4');
fwrite(fid,llat,'integer*4');
fclose(fid);
filename=[outdir,'simgrid.dat'];
fid=fopen(filename,'w');
fwrite(fid,mlon,'real*8');
fwrite(fid,mlat,'real*8');
fclose(fid);
for it=1:lt
    UTsec=expdate(it,4)*3600+expdate(it,5)*60+expdate(it,6);
    ymd=expdate(it,1:3);
    filename=datelab(ymd,UTsec);
    filename=[outdir,filename,'.dat']
    fid=fopen(filename,'w');
    fwrite(fid,Qit(:,:,it),'real*8');
    fwrite(fid,E0it(:,:,it),'real*8');
    fclose(fid);
end


end % function
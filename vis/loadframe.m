function [ne,mlatsrc,mlonsrc,xg,v1,Ti,Te,J1,v2,v3,J2,J3,filename,Phitop,ns,vs1,Ts] = loadframe(direc,ymd,UTsec,ymd0,UTsec0,tdur,dtout,flagoutput,mloc,xg)

cwd = fileparts(mfilename('fullpath'));
addpath([cwd,'/../script_utils'])

narginchk(3,10)
validateattr(direc, {'char'}, {'vector'}, mfilename, 'data directory', 1)
validateattr(ymd, {'numeric'}, {'vector', 'numel', 3}, mfilename, 'year month day', 2)
validateattr(UTsec, {'numeric'}, {'vector'}, mfilename, 'UTC second', 3)

if nargin>=4
  validateattr(ymd0, {'numeric'}, {'vector', 'numel', 3}, mfilename, 'year month day', 4)
end
if nargin>=5
  validateattr(UTsec0, {'numeric'}, {'scalar'}, mfilename, 'UTC second', 5)
end

if nargin>=6 && ~isempty(tdur)
  validateattr(tdur,{'numeric'},{'scalar'},mfilename,'simulation duration',6)
end
if nargin>=7 && ~isempty(dtout)
  validateattr(dtout,{'numeric'},{'scalar'},mfilename,'output time step',7)
end

if nargin>=8 && ~isempty(flagoutput)
  validateattr(flagoutput,{'numeric'},{'scalar'},mfilename,'output flag',8)
end
if nargin>=9 && ~isempty(mloc)
  validateattr(mloc, {'numeric'}, {'vector', 'numel', 2}, mfilename, 'magnetic coordinates', 9)
end
if nargin>=10 && ~isempty(xg)
  validateattr(xg, {'struct'}, {'scalar'}, mfilename, 'grid structure', 10)
end


% READ IN THE SIMULATION INFORMATION IF IT HAS NOT ALREADY BEEN PROVIDED
if (~exist('UTsec0','var') || ~exist('ymd0','var') || ~exist('mloc','var') || ~exist('tdur','var') ...
     || ~exist('dtout','var') || ~exist('flagoutput','var') || ~exist('mloc','var') )
  [ymd0,UTsec0,tdur,dtout,flagoutput,mloc]=readconfig([direc,'/inputs/config.ini']);
end


% CHECK WHETHER WE NEED TO RELOAD THE GRID (WHICH CAN BE TIME CONSUMING)
if nargout >= 4 && ~exist('xg','var')
  xg = readgrid([direc,'/inputs/']);
end


%% SET MAGNETIC LATITUDE AND LONGITUDE OF THE SOURCE
if nargout >= 2 && ~isempty(mloc)
  mlatsrc=mloc(1);
  mlonsrc=mloc(2);
else
  mlatsrc=[];
  mlonsrc=[];
end


%% LOAD DIST. FILE
filestr=datelab(ymd,UTsec);
if ymd(1)==ymd0(1) && ymd(2)==ymd0(2) && ymd(3)==ymd0(3) && UTsec==UTsec0    %tack on the decimal part
  filestr(end)='1';
end
ext = '.dat';
filename=[filestr,ext];

if ~exist([direc,filesep,filename], 'file')
  ext = '.h5';
  filename = [filename(1:end-4), ext];
end

switch flagoutput
  case 1
    [ne,v1,Ti,Te,J1,v2,v3,J2,J3,ns,vs1,Ts,Phitop] = loadframe3Dcurv(direc,filename);
  case 2
    if strcmp(ext, '.dat')
      [ne,v1,Ti,Te,J1,v2,v3,J2,J3,Phitop] = loadframe3Dcurvavg(direc,filename);
    else
      [ne,v1,Ti,Te,J1,v2,v3,J2,J3,Phitop] = loadframe_HDF5_3Dcurvavg(direc,filename);
    end
    ns=[]; vs1=[]; Ts=[];
  otherwise
    ne=loadframe3Dcurvne(direc,filename);
    v1=[]; Ti=[]; Te=[]; J1=[]; v2=[]; v3=[]; J2=[]; J3=[];
    ns=[]; vs1=[]; Ts=[]; Phitop=[];
end

end % function

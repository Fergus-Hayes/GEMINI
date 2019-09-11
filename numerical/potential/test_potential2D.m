%% LOAD DATA
clear,clc;
fid=fopen('test_potential2D.dat');
data=fscanf(fid,'%f',1);
lx2=data(1);
x2=fscanf(fid,'%f',lx2);
data=fscanf(fid,'%f',1);
lx3=data(1);
x3=fscanf(fid,'%f',lx3);
Phi=fscanf(fid,'%f',lx2*lx3);
Phi=reshape(Phi,[lx2,lx3]);
Phi2=fscanf(fid,'%f',lx2*lx3);
Phi2=reshape(Phi2,[lx2,lx3]);
Phitrue=fscanf(fid,'%f',lx2*lx3);
Phitrue=reshape(Phitrue,[lx2,lx3]);
fclose(fid);


%% Plot data
figure(1);

subplot(1,3,1)
imagesc(x2,x3,Phi);
colorbar;
axis xy;
xlabel('distance (m)')
ylabel('distance (m)')
title('2D potential (polarization)')

subplot(1,3,2)
imagesc(x2,x3,Phi2);
colorbar;
axis xy;
xlabel('distance (m)')
ylabel('distance (m)')
title('2D potential (static)')

subplot(1,3,3)
imagesc(x2,x3,Phitrue);
colorbar;
axis xy;
xlabel('distance (m)')
ylabel('distance (m)')
title('2D potential (analytical)')


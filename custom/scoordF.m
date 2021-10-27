function f = scoordF(h,d,sigma,unit,dmin,dmax,cinter)

% sigma = 20;
% h = waf_pr{1, 1}{1, 1}{1, 3}(:,3)'; % elevation
% d = waf_pr{1, 1}{1, 4}{1, 3};       % data to plot
% unit=0.1;                           % index to km
plt_line = 0;                       % if plot sigma layer
% dmin = -1;                        % color min value
% dmax = 5;                           % color max value
% cinter = 1;                       % contour line interval

%{
% export python matplotlib colormap, spectral.                  
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from matplotlib.colors import ListedColormap, LinearSegmentedColormap
Spectral = cm.get_cmap('Spectral',256)
spectral_map=Spectral(np.linspace(0,1,256))
np.savetxt('./spectral_color_map.txt',spectral_map)
%}

% sigma layer line
slay = repmat([0:1/(sigma-1):1]',1,length(h));
slayz = repmat(h,sigma,1) .* slay;

% load extra color map
temp=importdata('spectral_color_map.txt');
spectral=temp(:,1:3);
clear temp

% figure
%clf;
f = figure;

% smooth contour
hf = fspecial('gaussian');
hf = fspecial('average');
dc = conv2(d, hf, 'same');

% data
id = [0:length(h)-1];
x = repmat(id*unit,sigma,1);
s = pcolor(x,slayz,d);
s.FaceColor = 'interp';
s.EdgeColor = 'interp';
colormap(flipud(spectral));
% colormap(spectral);
caxis([dmin dmax]);
colorbar();
hold on;

% topography
zmin = min(h);
zmax = max(h);
xmin = min(id);
xmax = max(id);
hs=[zmin h zmin];
xs=[xmin id xmax]*unit;

% sigma layer line
if plt_line
    for i=1:sigma
        plot(id*unit,slayz(i,:),...
            'Color',[0.86 0.86 0.86]);
        hold on;
    end
end

% topography
fill(xs,hs,[0.6 0.7 0.6]);
ylim([zmin,0]);
xlim([min(xs),max(xs)]);
hold on;

% contour
[C,hh] = contour(x,slayz,dc,'ShowText','on');
hh.LevelList = [floor(dmin):cinter:ceil(dmax)];
hh.LineColor = 'black';
hh.LineStyle = ':';
hold on;

% Create ylabel
ylabel('Elevation (m)');
% Create xlabel
xlabel('Distance (km)');
% Font
set(gca,'FontSize',16);
hold off;


function plot_TIDE_surface(Num, YData1, XData1, CData1, zdata2, Name)
%CREATEFIGURE(ZData1, YData1, XData1, CData1, zdata2, zdata3, zdata4)
%  ZDATA1:  surface zdata
%  YDATA1:  surface ydata
%  XDATA1:  surface xdata
%  CDATA1:  surface cdata
%  ZDATA2:  contour z
%  ZDATA3:  contour z
%  ZDATA4:  contour z

%  Auto-generated by MATLAB on 30-May-2019 12:15:15

% Create figure
figure1 = figure(Num);
clf

% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');

% Create surface
% surface('Parent',axes1,'ZData',ZData1,'YData',YData1,'XData',XData1,...
%     'AlignVertexCenters','on',...
%     'EdgeColor','none',...
%     'CData',CData1);
pcolor(XData1,YData1,CData1); 
shading flat;
caxis([0,1]);

% Create contour
[c1,h1] = contour(XData1,YData1,zdata2,'LineWidth',1,'LineColor',[0 0 0],...
    'LevelList',[-pi:pi/120:pi]);
clabel(c1,h1);

% Create contour
[c2,h2] = contour(XData1,YData1,zdata2,'LineWidth',2,'LineStyle','--',...
    'LineColor',[0 0 0],...
    'LevelList',[-pi/2 pi/2]);
clabel(c2,h2);

% Create contour
contour(XData1,YData1,zdata2,'LineWidth',2,'LineColor',[0 0 0],...
    'LevelList',[pi/2]);

% Create ylabel
ylabel('Latitude (degrees)');

% Create xlabel
xlabel('Longtitude (degrees)');

% Create title
title([Name,' tide: co-phase (rad) and co-amplitude (m) distribution']);

% Uncomment the following line to preserve the X-limits of the axes
% xlim(axes1,[139.1 140.4]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(axes1,[34.65 35.75]);

box(axes1,'on');
grid(axes1,'on');
% Set the remaining axes properties
set(axes1,'DataAspectRatio',[1 1 1],'PlotBoxAspectRatio',...
    [1 1.00000005085774 1.71428573366612]);
% Create colorbar
colorbar(axes1);
set(gcf,'position',[Num*10,Num*10,800,600])

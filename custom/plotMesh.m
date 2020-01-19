function plotMesh(Num, Nod, Tri, Dep, varargin)
%CREATEFIGURE(Num, Loc, Tri, Dep, varargin)
%  NUM: figure number
%  Nod: Location matrix, [x,y] or [lon,lat]
%  Tri: Tri matrix
%  Dep: Water depth
%  Example:
% plot_MESH(01, [Mobj.lon, Mobj.lat], Mobj.tri, Mobj.h,...
%     'obc',[x(nodeList), y(nodeList)]);

%  Generated by Yulong on 23-May-2019 15:01:43

if (nargin < 4 || nargin > 5) && isempty(varargin)
    error('Incorrect number of arguments')
elseif nargin == 5
    pass;
end

% Font size
fs = 12;
% Axis size
as = 10;

obc = false;
riv = false;
for i=1:2:length(varargin)-1
	keyword  = lower(varargin{i});	
	switch(keyword(1:3))
        case 'obc'
            obc_xy = varargin{i+1};
            obc_x = obc_xy(:,1);
            obc_y = obc_xy(:,2);
            obc = true;
        case 'riv'
            riv_xy = varargin{i+1};
            riv_x = riv_xy(:,1);
            riv_y = riv_xy(:,2);
            riv = true;
        otherwise
            error(['Can''t understand property:' char(varargin{i+1})]);
    end
end

% Create figure
figure1 = figure(Num);
clf

% Create axes
ax = axes('Parent',figure1);
hold(ax,'on');

% Create patch
patch('Parent',ax,'Vertices',Nod,'Faces',Tri,...
    'FaceColor','interp',...
    'CData',Dep);

if obc
    % Create open boundary plot
    plot(obc_x,obc_y,'Marker','o','LineStyle','none','Color',[1 0 0]);
end

if riv
    % Create river boundary plot
    plot(riv_x,riv_y,'Marker','o','LineStyle','none','Color',[0 1 0]);
end

% Create label
ylabel('Latitude (degree)','FontSize',fs);
xlabel('Longtitude (degree)','FontSize',fs);
title('Mesh and water depth (m)','FontSize',fs);

x = Nod(:,1);
y = Nod(:,2);

% Uncomment the following line to preserve the X-limits of the axes
xlim(ax,[min(x)-(max(x)-min(x))*0.2 max(x)+(max(x)-min(x))*0.2]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(ax,[min(y)-(max(y)-min(y))*0.1 max(y)+(max(y)-min(y))*0.1]);
box(ax,'on');

% Set the remaining axes properties
set(ax,'DataAspectRatio',[1.2 1 1],'PlotBoxAspectRatio',...
    [1 1 1],'FontSize',fs);
set(gcf,'position',[Num*10,Num*10,800,600])
% Create colorbar
hcb = colorbar('peer',ax);
set(get(hcb,'label'),'string','Water depth (m)','FontSize',fs);

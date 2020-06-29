function plotPtra(Num, Nod, Tri, Vec, varargin)
%CREATEFIGURE(Num, Loc, Tri, Dep, varargin)
%  Num: figure number
%  Nod: Location matrix, [x,y] or [lon,lat]
%  Tri: Tri matrix
%  Vec: Location of particles [lon,lat]
%  Example:
%  plotVect(01, [Mobj.lon, Mobj.lat], Mobj.tri, [u, v],...
%      'obc',[x(nodeList), y(nodeList)]);

%  Generated by Yulong on 23-May-2019 15:01:43
%  Color:https://jp.mathworks.com/help/matlab/ref/plot.html?lang=zh#btzitot-LineSpec

x = Nod(:,1);
y = Nod(:,2);
tr = triangulation(Tri,Nod);
edge = freeBoundary(tr)';
lon = Vec(:,1);
lat = Vec(:,2);

if (nargin < 4 || nargin > 5) && isempty(varargin)
    error('Incorrect number of arguments')
elseif nargin == 5
    pass;
end

% Font size
fs = 12;

obc = false;
riv = false;
hdtitle = false;
cbtitle = false;
showtime = false;
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
        case 'tit'
            title_hd = varargin{i+1};
            hdtitle = true;
        case 'cbt'
            title_cb = varargin{i+1};
            cbtitle = true;
        case 'tim'
            time_str = varargin{i+1};
            showtime = true;
        case 'sca'
            scl = varargin{i+1};
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

% Create mesh with boundary
triplot(tr,'Color','w');
hold on;
plot(Nod(edge,1),Nod(edge,2),'-k','LineWidth',1);
hold on;

if obc
    % Create open boundary plot
    plot(obc_x,obc_y,'Marker','o','LineStyle','none','Color',[0.9290 0.6940 0.1250]);
    hold on;
end

if riv
    % Create river boundary plot
    plot(riv_x,riv_y,'Marker','o','LineStyle','none','Color',[0.4660 0.6740 0.1880]);
    hold on;
end

% Create scatter
ss = scatter(lat(:,1),lon(:,1));
set(ss,'LineWidth', 0.6)
set(ss,'MarkerEdgeColor', 'b');
set(ss,'MarkerFaceColor', [0 0.5 0.5]);

axis equal;

% Create label
ylabel('Latitude (degree)','FontSize',fs);
xlabel('Longtitude (degree)','FontSize',fs);
if hdtitle
    title([title_hd],'FontSize',fs);
end

% Uncomment the following line to preserve the X-limits of the axes
xlim(ax,[min(x)-(max(x)-min(x))*0.2 max(x)+(max(x)-min(x))*0.2]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(ax,[min(y)-(max(y)-min(y))*0.1 max(y)+(max(y)-min(y))*0.1]);
box(ax,'on');

% Set the remaining axes properties
set(ax,'DataAspectRatio',[1.2 1 1],'PlotBoxAspectRatio',...
    [1 1 1],'FontSize',fs);
set(gcf,'position',[Num*10,Num*10,800,600]);

if cbtitle
    % Create colorbar
    hcb = colorbar('peer',ax);
    set(get(hcb,'label'),'string',title_cb,'FontSize',fs);
end

if showtime
    % Create time str
    text(min(x)-(max(x)-min(x))*0.10,min(y)-(max(y)-min(y))*0.05,time_str,'FontSize',fs);
end

if obc
    % Create open boundary nodes legend
    legend_obc = 'OBC Nodes';
    legobc_x = min(x)-(max(x)-min(x))*0.10;
    legobc_y = max(y)+(max(y)-min(y))*0.05;
    plot(legobc_x,legobc_y,'Marker','o','LineStyle','none','Color',[0.9290 0.6940 0.1250]);
    hold on;
    text(legobc_x+0.05,legobc_y,legend_obc,'FontSize',fs);
    if riv
        % Create riv boundary nodes legend
        legend_riv = 'RIV Nodes';
        legriv_x = min(x)-(max(x)-min(x))*0.10;
        legriv_y = max(y)+(max(y)-min(y))*0.025;
        plot(legriv_x,legriv_y,'Marker','o','LineStyle','none','Color',[0.4660 0.6740 0.1880]);
        hold on;
        text(legriv_x+0.05,legriv_y,legend_riv,'FontSize',fs);
    end
end
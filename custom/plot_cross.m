function plot_cross(Num, YData1, XData1, CData1, NAME_ITEM, NAME_LOCATION, Min, Max, DateString)
%CREATEFIGURE(YData1, XData1, CData1)
%  Num?    figure number
%  YData1:  water depth arrary of nodes, dimension = [4 * n], anti-clock from left bottom of the square.
%  XDATA1:  number label arrary of nodes, dimension = [4 * n]
%  CDATA1:  value, it can be temperature or salinity, dimension = [n * 1] 

%  Auto-generated by MATLAB on 24-May-2019 11:53:17

% Create figure
figure1 = figure(Num);
clf

set(gcf,'position',[Num*10,Num*10,800,600]);

% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');

% Create patch
patch('Parent',axes1,'YData',YData1,'XData',XData1,'FaceColor','flat',...
    'EdgeColor','none',...
    'CData',CData1);

% Create ylabel
ylabel('Elevation (m)','FontSize',16,'FontName','Times');

% Create xlabel
% xlabel('Node','FontSize',16,'FontName','Times');

if strcmpi(NAME_ITEM, 'temperature')
    item = '(^{\circ}C)';
elseif strcmpi(NAME_ITEM, 'salinity')
    item = '(PSU)';
elseif strcmpi(NAME_ITEM, 'age')   
    item = '(day)';
elseif strcmpi(NAME_ITEM, 'DYE')
    item = '(-)';
elseif (NAME_ITEM(1:3) == 'age')
    item = '(day)';
end

% Create title
% title(['Water ',NAME_ITEM, ' of ', NAME_LOCATION, ' ', item],'FontSize',16,'FontName','Times');

% Uncomment the following line to preserve the X-limits of the axes
xlim(axes1,[min(min(XData1)) max(max(XData1))]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(axes1,[-2752 0]);
box(axes1,'on');
% Set the remaining axes properties
if strcmpi(NAME_ITEM, 'age')
    set(axes1,'XDir','normal','CLim',[0 180]);
elseif (NAME_ITEM(1:5) == 'age00')
    set(axes1,'XDir','normal','CLim',[Min Max]);
elseif (NAME_ITEM(1:3) == 'age')
    set(axes1,'XDir','normal','CLim',[0 120]);
else
    set(axes1,'XDir','normal','CLim',[Min Max]);
end

% Create colorbar
colorbar('peer',axes1);
try
    annotation(figure1,'textbox',...
        [0.168857142857143 0.126190476190476 0.473142857142857 0.0571428571428571],...
        'String',{[DateString(1:10),' ',DateString(12:19)]},...
        'LineStyle','none',...
        'FitBoxToText','off');
catch
    if strcmpi(DateString, '0000-00')
        DateString = '';
        annotation(figure1,'textbox',...
            [0.168857142857143 0.126190476190476 0.473142857142857 0.0571428571428571],...
            'String',{DateString},...
            'LineStyle','none',...
            'FitBoxToText','off');
    else
        annotation(figure1,'textbox',...
            [0.168857142857143 0.126190476190476 0.473142857142857 0.0571428571428571],...
            'String',{DateString(1:7)},...
            'LineStyle','none',...
            'FitBoxToText','off');
    end
end

set(gca,'xticklabel',[])
% set(gca,'yticklabel',[])
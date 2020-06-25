function quickMesh(ncfile, varargin)
% Quik show the mesh of FVCOM output file.
% quickMesh(ncfile)

% filename
% ncfile = 'long_box_0001.nc';

% read file
for i=1:2:length(varargin)-1
	keyword  = lower(varargin{i});	
	switch(keyword(1:3))
        case 'car'
            car = varargin{i+1};
        otherwise
            error(['Can''t understand property:' char(varargin{i+1})]);
    end
end
if car
    x = ncread(ncfile,'x');
    y = ncread(ncfile,'y');
else
    x = ncread(ncfile,'lon');
    y = ncread(ncfile,'lat');
end

nv = ncread(ncfile,'nv');

% make matrix
xy = [x, y];
nv = double(nv);
xy = double(xy);

% make trianglua mesh
tr = triangulation(nv,xy);
boundaryedges = freeBoundary(tr)';

% plot
figure;
clf;
triplot(tr);
hold on 
plot(xy(boundaryedges,1),xy(boundaryedges,2),'-r','LineWidth',2)
hold off
axis equal;
xlim([min(x)-(max(x)-min(x))*0.2 max(x)+(max(x)-min(x))*0.2]);
ylim([min(y)-(max(y)-min(y))*0.1 max(y)+(max(y)-min(y))*0.1]);

if car
    xlabel('Meter')
    ylabel('Meter')
else
    xlabel('Lon')
    ylabel('Lat')
end

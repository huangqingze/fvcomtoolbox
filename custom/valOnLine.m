function [valx,valy,valz,l] = valOnLine(csv_resol,data_temp,shp_path)

llen = 0; % subline length
langx = 0;langy = 0;
valx = []; valy = []; valz = [];

% shp_path='/Users/yulong/GitHub/study_case1_plus/gis_files/lines/crs_ns.shp'
% data_temp = data_topo;
s = shaperead(shp_path);
for l = 2:length(s.X)-1
    llen(l-1) = sqrt((s.X(l-1)-s.X(l))^2+(s.Y(l-1)-s.Y(l))^2);
    langx(l-1) = (s.X(l)-s.X(l-1))/llen(l-1);
    langy(l-1) = (s.Y(l)-s.Y(l-1))/llen(l-1);
    valx = [valx,s.X(l-1):(csv_resol*langx(l-1)/111000):s.X(l)];
    valy = [valy,s.Y(l-1):(csv_resol*langy(l-1)/111000):s.Y(l)];
    lon = (s.X(l-1):(csv_resol*langx(l-1)/111000):s.X(l))';
    lat = (s.Y(l-1):(csv_resol*langy(l-1)/111000):s.Y(l))';
    ageint = data_temp.intp({lon,lat});
    valz = [valz,diag(ageint)'];
end
    
% linelength = sqrt((s.X(1)-s.X(2))^2+(s.Y(1)-s.Y(2))^2);
% line_angx = (s.X(2)-s.X(1))/linelength;
% line_angy = (s.Y(2)-s.Y(1))/linelength;
% val1 = s.X(1):(csv_resol*line_angx/111000):s.X(2);
% val2 = s.Y(1):(csv_resol*line_angy/111000):s.Y(2);
% lonint = (s.X(1):(csv_resol*line_angx/111000):s.X(2))';
% latint = (s.Y(1):(csv_resol*line_angy/111000):s.Y(2))';
% ageint = data_temp.intp({lonint,latint});
% val3 = diag(ageint)';

function [val1,val2,val3] = valOnLine(csv_resol,data_temp,shp_path)

s = shaperead(shp_path);
linelength = sqrt((s.X(1)-s.X(2))^2+(s.Y(1)-s.Y(2))^2);
line_angx = (s.X(2)-s.X(1))/linelength;
line_angy = (s.Y(2)-s.Y(1))/linelength;
val1 = s.X(1):(csv_resol*line_angx/111000):s.X(2);
val2 = s.Y(1):(csv_resol*line_angy/111000):s.Y(2);
lonint = (s.X(1):(csv_resol*line_angx/111000):s.X(2))';
latint = (s.Y(1):(csv_resol*line_angy/111000):s.Y(2))';
ageint = data_temp.intp({lonint,latint});
val3 = diag(ageint)';

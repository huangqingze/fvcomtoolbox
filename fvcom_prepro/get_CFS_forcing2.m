function data = get_CFS_forcing(Mobj, modelTime, timeStep, varargin)
% Get the required parameters from CFSv2 reanalysis products to force
% FVCOM.
%
% data = get_CFS_forcing(Mobj, modelTime)
%
% DESCRIPTION:
%   Using the NOAA OPeNDAP server, extract the necessary parameters to
%   create an FVCOM forcing file. Data are available for 1979-2009
%   inclusive.
%
% INPUT:
%   Mobj - MATLAB mesh object. Must contain fields:
%       lon, lat    - array of longitude and latitudes.
%       have_lonlat - boolean to signify whether coordinates are spherical
%                   or cartesian.
%   modelTime - Modified Julian Date start and end times
%   timeStep - time interval (Unit: day)
%   varargin - optional parameter/value pairs:
%       - list of variables to extract:
%           'varlist', {'tmp2m', 'uwnd', 'vwnd'}
%
% OUTPUT:
%   data - struct of the data necessary to force FVCOM. These can be
%   interpolated onto an unstructured grid in Mobj using grid2fvcom.m.
%   Contains vectors of the longitude and latitude data (lon, lat).
%
% The parameters which can be obtained from the NCEP data are:
%     - Net shortwave radiation (nswsfc = uswsfc - dswsfc) [surface] [W/m^2]
%     - Downward longwave radiation (dlwrf) [surface] [W/m^2]
%     - Pressure (pressfc) [surface] [Pa]
%     - u wind component (uwnd) [10m] [m/s]
%     - v wind component (vwnd) [10m] [m/s]
%     - Air temperature (tmp2m) [2m] [celsius]
%     - Precipitation rate (prate) [surface] [m/s]
%     - Specific humidity (q2m) [2m] [%]
%     - Relative humidity (rhum) [2m] [%] - calculated from q2m.
%     - Latent heat flux (lhtfl) [surface] [m/s]
%     - Evaporation rate (Et) [surface] [m/s]
%
% Relative humidity is calculated from specific humidity with the QAIR2RH
% function (see fvcom-toolbox/utilities). Precipitation is converted from
% kg/m^2/s to m/s. Evaporation (Et) is calculated from the mean daily
% latent heat net flux (lhtfl) at the surface. Precipitation-evaporation is
% also created (P_E).
%
% EXAMPLE USAGE:
%   To download the default set of data (see list above):
%
%       forcing = get_CFS_forcing(Mobj, [51345, 51376], 1/24);
%
%   To only download wind data:
%
%       forcing = get_CFS_forcing(Mobj, [51345, 51376], 'varlist', {'uwnd', 'vwnd'});
%
% Author(s)
%   Pierre Cazenave (Plymouth Marine Laboratory)
%   Ricardo Torres (Plymouth Marine Laboratory)
%   Rory O'Hara Murray (Marine Scotland Science)
%
% Revision history:
%   2019-05-10 Add time interpolation option by Yulong Wang.
%   2015-05-19 First version loosely based on get_NCEP_forcing.m.
%
%==========================================================================

subname = 'get_CFS_forcing';

global ftbverbose;
if ftbverbose
    fprintf('\nbegin : %s\n', subname)
end

% Parse the input arguments
varlist = [];
if nargin > 3
    for a = 1:2:nargin - 3
        switch varargin{a}
            case 'varlist'
                varlist = varargin{a + 1};
        end
    end
end
if ftbverbose
    fprintf('Extracting CFSv2 data.\n')
end

% Get the extent of the model domain (in spherical)
if ~Mobj.have_lonlat
    error('Need spherical coordinates to extract the forcing data')
else
    % Add a buffer of one grid cell in latitude and two in longitude to
    % make sure the model domain is fully covered by the extracted data.
    [dx, dy] = deal(0.5, 0.5); % approximate CFSv2 resolution in degrees
    extents = [min(Mobj.lon(:)) - (2 * dx), ...
        max(Mobj.lon(:)) + (2 * dx), ...
        min(Mobj.lat(:)) - dy, ...
        max(Mobj.lat(:)) + dy];
end

% Create year and month arrays for the period we've been given.
[yyyy, mm, dd, HH, MM, SS] = mjulian2greg(modelTime);
assert(min(yyyy) >= 2011, 'CFSv2 data not available prior to 2011, try the git_CFS_forcing')
assert(max(yyyy) <= 2019, 'CFSv2 data not available after 2019')
dates = datenum([yyyy; mm; dd; HH; MM; SS]');
serial = dates(1):dates(2);
[years, months, ~, ~, ~, ~] = datevec(serial);
[months, idx] = unique(months, 'stable');
years = years(idx);
nt = length(months);

for t = 1:nt
    month = months(t);
    year = years(t);
    if ftbverbose
        fprintf('Downloading for %04d/%02d\n', year, month)
    end

    % Set up a struct of the remote locations in which we're
    % interested.
    % https://nomads.ncdc.noaa.gov/modeldata/cfsv2_analysis_timeseries/
    url = '/home/usr0/n70110d/data/cfsv2/';
    ncep.dlwsfc  = [url, ...
        sprintf('%04d%02d/dlwsfc.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
    ncep.dswsfc  = [url, ...
        sprintf('%04d%02d/dswsfc.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
    ncep.lhtfl   = [url, ...
        sprintf('%04d%02d/lhtfl.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
    ncep.prate   = [url, ...
        sprintf('%04d%02d/prate.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
    ncep.pressfc = [url, ...
        sprintf('%04d%02d/pressfc.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
%     ncep.q2m     = [url, ...
%         sprintf('%04d%02d/q2m.gdas.%04d%02d.grb2', year, month, ...
%         year, month)];
    ncep.tmp2m   = [url, ...
        sprintf('%04d%02d/tmp2m.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
    ncep.uswsfc  = [url, ...
        sprintf('%04d%02d/uswsfc.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
    ncep.uwnd    = [url, ...
        sprintf('%04d%02d/wnd10m.gdas.%04d%02d.grb2', year, month, ...
        year, month)];
    ncep.vwnd    = [url, ...
        sprintf('%04d%02d/wnd10m.gdas.%04d%02d.grb2', year, month, ...
        year, month)];

    % We need variable names too since we can't store them as the keys in
    % ncep due to characters which MATLAB won't allow in fields (mainly -).
    names.dlwsfc = 'Downward_Long-Wave_Rad_Flux';
    names.dswsfc = 'Downward_Short-Wave_Rad_Flux';
    names.lhtfl = 'Latent_heat_net_flux';
    names.prate = 'Precipitation_rate';
    names.pressfc = 'Pressure';
%     names.q2m = 'Specific_humidity';
    names.tmp2m = 'Temperature';
    names.uswsfc = 'Upward_Short-Wave_Rad_Flux';
    names.uwnd = 'U-component_of_wind';
    names.vwnd = 'V-component_of_wind';

    fields = fieldnames(ncep);

    for aa = 1:length(fields)
        % We've been given a list of variables to do, so skip those that
        % aren't in the list.
        if ~isempty(varlist) && max(strcmp(fields{aa}, varlist)) ~= 1
            continue
        end

        if ftbverbose
            fprintf('getting ''%s'' data... ', fields{aa})
        end

        % These are needed when catting the arrays together.
        if t == 1
            data.(fields{aa}).data = [];
            data.(fields{aa}).time = [];
            data.(fields{aa}).lat = [];
            data.(fields{aa}).lon = [];
            data.time = [];
        end
        scratch.(fields{aa}).data = [];
        scratch.(fields{aa}).time = [];
        scratch.(fields{aa}).lat = [];
        scratch.(fields{aa}).lon = [];

        % ncid_info = ncinfo(ncep.(fields{aa}));
        ncid = netcdf.open(ncep.(fields{aa}));

        % If you don't know what it contains, start by using the
        % 'netcdf.inq' operation:
        % [numdims, numvars, numglobalatts, unlimdimid] = netcdf.inq(ncid);
        % Time is in hours since the start of the month. We want
        % sensible times, so we'll have to offset at some point.
        varid = netcdf.inqVarID(ncid, 'time');
        data_time = netcdf.getVar(ncid, varid, 'double');
        if max(data_time) == 6
            % Precipitation data has times as 0-6 repeated for n days.
            % We need a sensible set of hours since the start of the
            % month for subsequent subsampling in time.
            data_time = 0:length(data_time) - 1;
        end

        varid = netcdf.inqVarID(ncid,'lon');
        data_lon.lon = netcdf.getVar(ncid,varid,'double');
        varid = netcdf.inqVarID(ncid,'lat');
        data_lat.lat = netcdf.getVar(ncid,varid,'double');
        % Some of the NCEP Reanalysis 2 data are 4D, but with a single
        % vertical level (e.g. uwnd, vwnd, air, rhum).
        data_level_idx = [];
        try % not all data have a 'level', so fail gracefully here.
            varid = netcdf.inqVarID(ncid, 'level');
            data_level.level = netcdf.getVar(ncid, varid, 'double');
            if length(data_level.level) > 1
                % Assume we've got rhum and we want humidity at the sea
                % surface (1013 millibars (or hPa)). As such, ZQQ must be
                % 0.0 in the FVCOM model namelist. Find the closest level
                % to pressure at 1 standard atmosphere.
                [~, data_level_idx] = min(abs(data_level.level - 1013));
            end
        catch
            true;
        end
        if isempty(data_level_idx) % default to the first
            data_level_idx = 1;
        end

        % Time is in hours relative to the start of the month for CFSv2.
        timevec = datevec((data_time * timeStep) + datenum(year, month, 1, 0, 0, 0));

        % Get the data time and convert to Modified Julian Day.
        scratch.time = greg2mjulian(...
            timevec(:, 1), ...
            timevec(:, 2), ...
            timevec(:, 3), ...
            timevec(:, 4), ...
            timevec(:, 5), ...
            timevec(:, 6));
        % Clip the time to the given range. Because of some oddness with
        % some variables giving data beyond the end of the month whilst
        % others don't, set the limits in time for each month to be the
        % first/last day of the month or the modelTime start/end, whichever
        % is larger/smaller.
        startTime = max([modelTime(1), ...
            greg2mjulian(year, month, 1, 0, 0, 0)]);
        % Offset end by one day to capture the right number of days
        % (midnight falls at the beginning of the specified day).
        endTime = min([modelTime(end), ...
            greg2mjulian(year, month, eomday(year, month), 0, 0, 0) + 1]);
        data_time_mask = scratch.time >= startTime & scratch.time < endTime;
        data_time_idx = 1:size(scratch.time, 1);
        data_time_idx = data_time_idx(data_time_mask);
        if ~isempty(data_time_idx)
            scratch.time = scratch.time(data_time_mask);
        else
            % Reset the index to its original size. This is for data
            % with only a single time stamp which falls outside the
            % model time.
            if length(scratch.time) == 1
                data_time_idx = 1:size(scratch.time, 1);
            end
        end

        % Check the times.
        [y, m, d, hh, mm, ss] = mjulian2greg(scratch.time);
        fprintf('(%s - %s) \n', ...
            datestr([y(1),m(1),d(1),hh(1),mm(1),ss(1)], ...
                'yyyy-mm-dd HH:MM:SS'), ...
            datestr([y(end),m(end),d(end),hh(end),mm(end),ss(end)], ...
                'yyyy-mm-dd HH:MM:SS'))
        clearvars y m d hh mm ss oftv

        % Get the data in two goes, once for the end of the grid (west of
        % Greenwich), once for the beginning (east of Greenwich), and then
        % stick the two bits together.
        clear index_lon index_lat
        if extents(1) < 0 && extents(2) < 0
            % This is OK, we can just shunt the values by 360.
            extents(1) = extents(1) + 360;
            extents(2) = extents(2) + 360;
            index_lon = find(data_lon.lon > extents(1) & ...
                data_lon.lon < extents(2));
        elseif extents(1) < 0 && extents(2) > 0
            % This is the tricky one. We'll do two passes to extract the
            % western chunk first (extents(1) + 360 to 360), then the
            % eastern chunk (0 - extents(2)).
            index_lon{1} = find(data_lon.lon >= extents(1) + 360);
            index_lon{2} = find(data_lon.lon <= extents(2));
        else
            % Dead easy, we're in the eastern hemisphere, so nothing too
            % strenuous here.
            index_lon = find(data_lon.lon > extents(1) & ...
                data_lon.lon < extents(2));
        end

        % Latitude is much more straightforward
        index_lat = find(data_lat.lat > extents(3) & data_lat.lat < extents(4));
        scratch.(fields{aa}).lat = data_lat.lat(index_lat);

        % Get the data
        if iscell(index_lon)
            scratch.(fields{aa}).lon = data_lon.lon(cat(1, index_lon{:}));

            varid = netcdf.inqVarID(ncid, names.(fields{aa}));

            [~, ~, dimids, ~] = netcdf.inqVar(ncid,varid);
            if length(dimids) == 4
                start = [...
                    min(index_lon{1}), ...
                    min(index_lat), ...
                    data_level_idx, ...
                    min(data_time_idx)] - 1;
                count = [...
                    length(index_lon{1}), ...
                    length(index_lat), ...
                    length(data_level_idx), ...
                    length(data_time_idx)];
            elseif length(dimids) == 3
                start = [...
                    min(index_lon{1}), ...
                    min(index_lat), ...
                    min(data_time_idx)] - 1;
                count = [...
                    length(index_lon{1}), ...
                    length(index_lat), ...
                    length(data_time_idx)];
            end

            data_west.(fields{aa}).(fields{aa}) = ...
                netcdf.getVar(ncid, varid, start, count, 'double');

            if length(dimids) == 4
                start = [...
                    min(index_lon{2}), ...
                    min(index_lat), ...
                    data_level_idx, ...
                    min(data_time_idx)] - 1;
                count = [...
                    length(index_lon{2}), ...
                    length(index_lat), ...
                    length(data_level_idx), ...
                    length(data_time_idx)];
            elseif length(dimids) == 3
                start = [...
                    min(index_lon{2}), ...
                    min(index_lat), ...
                    min(data_time_idx)] - 1;
                count = [...
                    length(index_lon{2}), ...
                    length(index_lat), ...
                    length(data_time_idx)];
            end
            data_east.(fields{aa}).(fields{aa}) = ...
                netcdf.getVar(ncid, varid, start, count, 'double');

            scratch.(fields{aa}).(fields{aa}).(fields{aa}) = ...
                cat(1, ...
                data_west.(fields{aa}).(fields{aa}), ...
                data_east.(fields{aa}).(fields{aa}));

            % Merge the two sets of data together
            structfields = fieldnames(data_west.(fields{aa}));
            for ii = 1:length(structfields)
                switch structfields{ii}
                    case 'lon'
                        % Only the longitude and the actual data need
                        % sticking together, but each must be done
                        % along a different axis (lon is a vector, the
                        % data is an array).
                        scratch.(fields{aa}).(structfields{ii}) = ...
                            [data_west.(fields{aa}).(structfields{ii}); ...
                            data_east.(fields{aa}).(structfields{ii})];
                    case fields{aa}
                        % This is the actual data.
                        scratch.(fields{aa}).(structfields{ii}) = ...
                            [data_west.(fields{aa}).(structfields{ii}); ...
                            data_east.(fields{aa}).(structfields{ii})];
                    otherwise
                        % Assume the data are the same in both arrays.
                        % A simple check of the range of values in the
                        % difference between the two arrays should show
                        % whether they're the same or not. If they are,
                        % use the western values, otherwise, warn about
                        % the differences. It might be the data are
                        % relatively unimportant anyway (i.e. not used
                        % later on).
                        try
                            tdata = ...
                                data_west.(fields{aa}).(structfields{ii}) - ...
                                data_east.(fields{aa}).(structfields{ii});
                            if range(tdata(:)) == 0
                                % They're the same data
                                scratch.(fields{aa}).(structfields{ii}) = ...
                                    data_west.(fields{aa}).(structfields{ii});
                            else
                                warning(['Unexpected data field and the', ...
                                    ' west and east halves don''t match.', ...
                                    ' Skipping.'])
                            end
                        catch
                            warning(['Unexpected data field and the', ...
                                ' west and east halves don''t match.', ...
                                ' Skipping.'])
                        end
                        clearvars tdata
                end
            end
            clearvars data_west data_east
        else
            % We have a straightforward data extraction
            scratch.(fields{aa}).lon = data_lon.lon(index_lon);

            varid = netcdf.inqVarID(ncid, names.(fields{aa}));
            % [varname,xtype,dimids,natts] = netcdf.inqVar(ncid,varid);
            % [~, length1] = netcdf.inqDim(ncid, dimids(1))
            % [~, length2] = netcdf.inqDim(ncid, dimids(2))
            % [~, length3] = netcdf.inqDim(ncid, dimids(3))
            start = [...
                min(index_lon), ...
                min(index_lat), ...
                min(data_time_idx)] - 1;
            count = [...
                length(index_lon), ...
                length(index_lat), ...
                length(data_time_idx)];
            % The air data (NCEP version of this script) was failing
            % with a three long start and count array, so try first
            % without (to retain original behaviour for other
            % potentially unaffected variables) but fall back to
            % getting the data_level_idx one instead (should be the first
            % level).
            try
                scratch.(fields{aa}).(fields{aa}).(fields{aa}) = ...
                    netcdf.getVar(ncid,varid,start,count,'double');
            catch
                start = [...
                    min(index_lon), ...
                    min(index_lat), ...
                    data_level_idx, ...
                    min(data_time_idx)] - 1;
                count = [...
                    length(index_lon), ...
                    length(index_lat), ...
                    1, ...
                    length(data_time_idx)];
                scratch.(fields{aa}).(fields{aa}) = ...
                    netcdf.getVar(ncid, varid, start, count, 'double');
            end

        end
        clearvars data_time* data_level_idx

        scratch.(fields{aa}).lon(scratch.(fields{aa}).lon > 180) = ...
            scratch.(fields{aa}).lon(scratch.(fields{aa}).lon > 180) - 360;

        datatmp = squeeze(scratch.(fields{aa}).(fields{aa}));

        % data.(fields{aa}).data = datatmp;
        data.(fields{aa}).data = cat(3, data.(fields{aa}).data, datatmp);
        % data.(fields{aa}).time = data.time;
        data.(fields{aa}).time = cat(1, data.(fields{aa}).time, scratch.time);
        % data.(fields{aa}).time = cat(1, data.(fields{aa}).time, ...
        %     squeeze(scratch.(fields{aa}).(fields{aa}).time));
        data.(fields{aa}).lat = scratch.(fields{aa}).lat;
        data.(fields{aa}).lon = scratch.(fields{aa}).lon;

        % Save the time to the main data struct. This is just the time from
        % the first variable. Since they should all be the same, this isn't
        % a particular problem. Famous last words...
        if aa == 1
            data.time = data.(fields{aa}).time;
        else
            clearvars scratch
        end

        if ftbverbose
            if isfield(data, fields{aa})
                fprintf('done.\n')
            else
                fprintf('error!\n')
            end
        end
    end
end

% Add code to tidy the result structure which is total mess.
fields = fieldnames(data);
for f = 1:length(fields)
    switch fields{f}
        case 'time'
            data.time = data.dlwsfc.time;
        otherwise
            try
                data.(fields{f}).data = data.(fields{f}).data.(fields{f});
            catch
                continue;
            end
    end
end
        
% Now we have the data, we need to fix the averaging to be hourly instead
% of n-hourly, where n varies from 0 to 6. See
% http://rda.ucar.edu/datasets/ds094.1/#docs/FAQs_hrly_timeseries.html with
% the question "How can the individual one-hour averages be computed?".
fields = fieldnames(data);
for f = 1:length(fields)
    if isfield(data.(fields{f}), 'data')
        % Some fields are instantaneous, so don't de-average them. See:
        % http://nomads.ncdc.noaa.gov/docs/CFSR-Hourly-Timeseries.pdf for
        % details.
        if any(strcmpi(fields{f}, {'pressfc', 'tmp2m', 'uwnd', 'vwnd'}))
            continue
        end
        [~, ~, nt] = size(data.(fields{f}).data);
        fixed = data.(fields{f}).data;
        if ftbverbose
            fprintf('De-averaging the n-hourly %s data to hourly... ', ....
                fields{f})
        end

        for t = 1:6:nt
            % Fix the next 5 hours of data. Assume 0th hour is just the
            % original data - since the formula multiplies by the n-1 hour,
            % if we want the first hour's worth of data, then the second
            % term in the formula with multiply by zero, so the formula is
            % essentially only using the first term, which is just the data
            % at n = 0.
            for n = 1:5
                if t + n <= nt
                    fixed(:, :, t + n) = ...
                        (n * data.(fields{f}).data(:, :, t + n)) - ...
                        ((n - 1) * data.(fields{f}).data(:, :, t + n - 1));
                end
            end
        end
        data.(fields{f}).data = fixed;
        clearvars fixed
        if ftbverbose; fprintf('done.\n'); end
    end
end

% Calculate the net long and shortwave radiation fluxes.
if isfield(data, 'uswsfc') && isfield(data, 'dswsfc')
    data.nswsfc.data = data.dswsfc.data - data.uswsfc.data;
    data.nswsfc.time = data.uswsfc.time;
    data.nswsfc.lon = data.uswsfc.lon;
    data.nswsfc.lat = data.uswsfc.lat;
end

% Convert precipitation from kg/m^2/s to m/s (required by FVCOM) by
% dividing by freshwater density (kg/m^3).
if isfield(data, 'prate')
    data.prate.data = data.prate.data / 1000;
end

% Evaporation can be approximated by:
%
%   E(m/s) = lhtfl/Llv/rho
%
% where:
%
%   lhtfl   = "Mean daily latent heat net flux at the surface"
%   Llv     = Latent heat of vaporization (approx to 2.5*10^6 J kg^-1)
%   rho     = 1025 kg/m^3
%
if isfield(data, 'prate') && isfield(data, 'lhtfl')
    Llv = 2.5 * 10^6;
    rho = 1025; % using a typical value for seawater.
    Et = data.lhtfl.data / Llv / rho;
    data.P_E.data = data.prate.data - Et;
    % Evaporation and precipitation need to have the same sign for FVCOM
    % (ocean losing water is negative in both instances). So, flip the
    % evaporation here.
    data.Et.data = -Et;
end

% Get the fields we need for the subsequent interpolation. Find the
% position of a sensibly sized array (i.e. not 'topo', 'rhum' or 'pres').
for vv = 1:length(fields)
    if ~isempty(varlist) && max(strcmp(fields{vv}, varlist)) ~= 1
        continue
    end

    switch fields{vv}
        % Set ii in each instance in case we've been told to only use one
        % of the three (four including pres and press) alternatively
        % gridded data.
        case {'topo', 'rhum', 'pres', 'press'}
            ii = vv;
            continue
        otherwise
            % We've got one, so stop looking.
            ii = vv;
            break
    end
end
data.lon = data.(fields{ii}).lon;
data.lon(data.lon > 180) = data.lon(data.lon > 180) - 360;
data.lat = data.(fields{ii}).lat;

% Convert temperature to degrees Celsius (from Kelvin)
if isfield(data, 'tmp2m')
    data.tmp2m.data = data.tmp2m.data - 273.15;
end

% Convert specific humidity to relative humidity.
% if isfield(data, 'q2m') && isfield(data, 'tmp2m') && isfield(data, 'pressfc')
%     % Convert pressure from Pascals to millibars. Save relative humidity as
%     % percentage. Convert specific humidity to percent too.
%     data.rhum.data = 100 * qair2rh(data.q2m.data, data.tmp2m.data, data.pressfc.data / 100);
% end
% if isfield(data, 'q2m')
%     data.q2m.data = 100 * data.q2m.data;
% end

% Make sure all the data we have downloaded are the same shape as the
% longitude and latitude arrays.
for aa = 1:length(fields)
    if (~isempty(varlist) && max(strcmp(fields{aa}, varlist)) ~= 1) || strcmpi(fields{aa}, 'time')
        % We've been given a list of variables to extract, so skip those
        % that aren't in that list
        continue
    else
        if isfield(data, fields{aa})
            [px, py] = deal(length(data.(fields{aa}).lon), ...
                length(data.(fields{aa}).lat));
            [ncx, ncy, ~] = size(data.(fields{aa}).data);
            if ncx ~= px || ncy ~= py
                data.(fields{aa}).data = ...
                    permute(data.(fields{aa}).data, [2, 1, 3]);

                % Check everything's OK now.
                [ncx, ncy, ~] = size(data.(fields{aa}).data);
                if ncx ~= px || ncy ~= py
                    error(['Unable to resize data arrays to match ', ...
                        'position data orientation. Are these on a ', ...
                        'different horizontal grid?'])
                end
            end
        else
            warning('Variable %s requested but not downloaded.', fields{aa})
        end
    end
end

% Have a look at some data(in the final created 'forcing' file).
% [X, Y] = meshgrid(forcing.lon(1,:), forcing.lat(:,1));
% for i = 1:size(forcing.uwnd.data, 3)
%     figure(1)
%     clf
%     uv = sqrt(forcing.uwnd.data(:, :, i).^2 + forcing.vwnd.data(:, :, i).^2);
%     pcolor(X, Y, uv')
%     shading flat
%     axis('equal','tight')
%     pause(0.2)
% end

if ftbverbose
    fprintf('end   : %s\n', subname)
end


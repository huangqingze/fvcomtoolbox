function example_FVCOM_river()
% example file for dumping an FVCOM river file and adding sediment concentration
%
% function example_FVCOM_river()
%
% DESCRIPTION:
%    Setup a sample FVCOM river file
%
% INPUT
%
% OUTPUT:
%    FVCOM RiverFile with flux,temp,salt,sediment
%
% Author(s):
%    Geoff Cowles (University of Massachusetts Dartmouth)
%    Pierre Cazenave (Plymouth Marine Laboratory)
%
% Revision history
%    2016-02-18 TODO: This function uses add_var_FVCOM_river which in turn
%    uses the old netCDF toolbox for MATLAB. That function needs to be
%    updated to use the built in netCDF routines in MATLAB.
%    2017-03-31 add_var_FVCOM_river now uses the native MATLAB netCDF
%    routines, so this script should work fine.
%
%==============================================================================

t1 = greg2mjulian(2007,1,1,0,0,0);
t2 = greg2mjulian(2007,2,1,0,0,0);
time = t1:1:t2;
nTimes = length(time);

% setup an event using Gaussian function
tmid = mean(time);
c    = .1*(tmid-time(1));
flux = 400+300*exp(-(time-tmid).^2/(2.*c^2))';
figure
plot(time,flux);
ylabel('flux m^3/s')
xlabel('time')
title('river flux')
sedload = .030*(flux.^1.40)/1000.; %sed conc in g/l

temp = 20*ones(nTimes,1);
salt = zeros(nTimes,1);
RiverFile = 'tst_riv.nc';
RiverInfo1 = 'idealized estuary river';
RiverInfo2 = 'event profile';
RiverName = {'tstRiver'};


write_FVCOM_river(RiverFile,RiverName,time,flux,temp,salt,RiverInfo1,RiverInfo2)

% add sediment to the file
VarName = 'fine_sand';
VarLongName = 'concentration of fine sand';
VarUnits = 'kgm^-3';
VarData = .333*sedload;
add_var_FVCOM_river(RiverFile,VarName,VarLongName,VarUnits,VarData)

VarName = 'coarse_silt';
VarLongName = 'concentration of coarse silt';
VarUnits = 'kgm^-3';
VarData = .333*sedload;
add_var_FVCOM_river(RiverFile,VarName,VarLongName,VarUnits,VarData)

VarName = 'fine_silt';
VarLongName = 'concentration of fine silt';
VarUnits = 'kgm^-3';
VarData = .333*sedload;
add_var_FVCOM_river(RiverFile,VarName,VarLongName,VarUnits,VarData)

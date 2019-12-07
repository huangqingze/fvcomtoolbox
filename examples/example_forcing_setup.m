% example demonstrating reading in a 2DM file and constructing a model
%
% function example_forcing_setup
%
% DESCRIPTION:
%    Read in an SMS .2dm Mesh and .dat bathymetry file
%    Dump river file, open boundary forcing file, time series wind forcing
%    file, grid file, open boundary node list file, bathymetry file, bedflag 
%    file, roughness file
%
% INPUT
%
% OUTPUT:
%    A bunch of FVCOM forcing files
%
% EXAMPLE USAGE
%    example_forcing_setup
%
% Author(s):
%    Geoff Cowles (University of Massachusetts Dartmouth)
%    Pierre Cazenave (Plymouth Marine Laboratory)
%
% Revision history
%    2016-02-18 Update the code to work with the changes to the toolbox.
%
%=============================================================================

clear 
close all

global ftbverbose
ftbverbose = true; % print information to screen [true/false]

% read the Mesh from an SMS file
Mobj = read_sms_mesh('2dm','./samples/tst.2dm','bath','./samples/tst.dep');

% reverse the topography so that it is positive down (e.g. bathymetry)
if(mean(Mobj.h) < 0.0)
    Mobj.h = -Mobj.h;
end

% calculate the Corolis
Mobj = add_coriolis(Mobj,'constant',31.0);

% check the time step and plot
Mobj = estimate_ts(Mobj, 3, 11);
plot_field(Mobj,Mobj.ts,'title','timestep (s)')
fprintf('estimated max external mode time step in seconds %f\n',min(Mobj.ts));

% smooth bathymetry with 4 iterations of explicit smoother
plot_field(Mobj,Mobj.h,'title','original bathymetry')
Mobj = setup_metrics(Mobj);
Mobj.h = smoothfield(Mobj.h,Mobj,0.5,4);
plot_field(Mobj,Mobj.h,'title','smoothed bathymetry');

% setup spatially variable bottom roughness and dump to file
hc = nodes2elems(Mobj.h,Mobj);
z0 = .008*ones(Mobj.nElems,1);
deep = find(hc > 5.);
z0(deep) = .004;
clear hc
write_FVCOM_z0(z0,'tst_z0.nc','z0 test 1')
plot_field(Mobj,elems2nodes(z0,Mobj),'title','bottom roughness')

% add a river to the domain 
%[Mobj] = add_river_nodes_graphic(Mobj,'tstRiver');
Mobj = add_river_nodes_list(Mobj,[838,844,845],'tstRiver');

% add an open boundary to the Mesh
Mobj = add_obc_nodes_list(Mobj,[1:25],'OpenOcean',1);
% [Mobj] = add_obc_nodes_graphic(Mobj,'OpenOcean2',1);

% add two sponge layers to the Mesh
% [Mobj] = add_sponge_nodes(Mobj,'Sponge1',10000,.0001);
% [Mobj] = add_sponge_nodes(Mobj,'Sponge2',5000,.0004);

% plot everything
plot_field(Mobj,Mobj.h,'title','domain','withextra',true,'showgrid',true);



%-----------------------------------------------------------------------------
% dump input files for FVCOM 3.x and greater
%-----------------------------------------------------------------------------

% add river forcing 
example_FVCOM_river()

% add harmonic forcing to open boundary
Mobj.Components = {'M2', 'S2'};
Mobj.period_obc = [44714.16, 43200];
Mobj.beta_love = [0, 0];
Mobj.equilibrium_amp = [0.1, 0.01];
Mobj.amp_obc = {repmat([3, 1], 1, Mobj.nObcNodes)};
Mobj.phase_obc = {repmat([3, 1], 1, Mobj.nObcNodes)};
set_spectide(Mobj, 2, 'tst_spectide.nc', 'Spectral tidal forcing')

% wind time series wind forcing example here
example_FVCOM_wind_ts_speed

% dump mesh and connectivity
write_FVCOM_grid(Mobj,'tst_grd.dat')

% dump bathymetry
write_FVCOM_bath(Mobj,'tst_dep.dat')

% % dump open boundary node list
write_FVCOM_obc(Mobj,'tst_obc.dat')

% dump a Temp/Salinity open boundary forcing file for 10 days at hourly 
% resolution for a 10 layer model.
example_FVCOM_tsobc('tst', 50000:1/24:50010, 10)

% dump sponge layer file
write_FVCOM_sponge(Mobj,'tst_spg.dat');

% do not allow for bed processes (erosion/deposition) east of the inlet
pts = find(Mobj.x > 2.85e5);
bedflag = ones(Mobj.nVerts,1); 
bedflag(pts) = 0;
write_FVCOM_bedflag(bedflag,'tst_bedflag.nc','no bed processes east of inlet')
plot_field(Mobj,bedflag); title('bedflag');

% dump Coriolis file
write_FVCOM_cor(Mobj,'tst_cor.dat')

function write_admesh_mesh(Mobj,varargin)
% writes admesh mesh files from a Mobj matlab structure variable
%
% function write_admesh_mesh(Mobj)
%
% DESCRIPTION:
%    writes admesh 14 file.
%
% INPUT
%   Mobj                   = needs bathymetry, nodes and triangulation
%   table. read_sms_mesh provides everything it needs.
%   [optional] output_directory       = directory to write mesh.14 file
%   [optional] filename       = filename to use instead of default mesh(.14). Don't provide extension 
%   [optional] native_coord = cartesian or spherical. Assumes cartesian if
%   omitted.
%
% OUTPUT:
%    ADMESH compatible .14 file.
%
% EXAMPLE USAGE
%    write_admesh_mesh(Mobj)
%
% Author(s):
%    Ricardo Torres (Plymouth Marine Laboratory) based on read_gmsh_mesh
%
% Revision history
%
%   2016-06-22 First version.
%   2017-06-06 Removed returned Mobj as it is in no way changed during this
%   function. Also set default coordinate type to cartesian unless
%   overridden with 'native_coord'.
%
%==============================================================================

[~, subname] = fileparts(mfilename('fullpath'));
global ftbverbose
if ftbverbose
    fprintf('\nbegin : %s \n', subname)
end

%--------------------------------------------------------------------------
% Parse input arguments
%--------------------------------------------------------------------------

assert(mod(length(varargin), 2) == 0, 'incorrect usage of write_admesh_mesh, use keyword pairs')

% Assume we have nothing sensible.
out_dir = pwd; % default is to write file to current directory
native_coord = 'cartesian';
have_xy = true;
have_lonlat = false;
filename = 'mesh'
for i = 1:2:length(varargin) - 1
    keyword = lower(varargin{i});
    
    assert(ischar(keyword), 'incorrect usage of write_admesh_mesh')
    
    switch keyword
        case 'output_directory'
            out_dir = varargin{i + 1};
        case 'filename'
            filename = varargin{i + 1};
        case 'native_coord'
            coord = varargin{i + 1};
            if strcmpi(coord, 'spherical')
                native_coord = 'spherical';
                have_lonlat = true;
                have_xy = false;
            elseif strcmpi(coord, 'cartesian')
                native_coord = 'cartesian';
                have_xy = true;
                have_lonlat = false;
            else
                warning('Unrecognised coordinate system (%s). Valid values are ''spherical'' and ''cartesian''.', native_coord)
            end
        otherwise
            error('Can''t understand property: %s', varargin{i + 1});
            
    end
end

%--------------------------------------------------------------------------
% Open the output file
%--------------------------------------------------------------------------
gmsh_msh = fullfile(out_dir,[filename '.14']);
fid = fopen(gmsh_msh, 'wt');
assert(fid >= 0, sprintf('file: %s could not be created\n',  gmsh_msh));

% Count number of elements and vertices
if ftbverbose
    fprintf('Writing to: %s\n', gmsh_msh)
end

% Read mesh type, written from srcatch:
%
% http://www.geuz.org/pipermail/gmsh/attachments/20071002/642cb6c3/attachment.m
%
title_str = 'Test admesh mesh starting from an sms mesh';

% first line is title of mesh
fprintf(fid,'%s\n',title_str);
% next line is mesh dimensions
fprintf(fid,'%u %u\n',Mobj.nElems,Mobj.nVerts);

% Write the node positions and depths.
if have_lonlat
    fprintf('Writing Spherical: %s\n', gmsh_msh)
    
    for nn=1:Mobj.nVerts
        fprintf(fid, '%d %f %f %f\n',nn,Mobj.lon(nn),Mobj.lat(nn),Mobj.h(nn));
    end
elseif have_xy
    fprintf('Writing Cartesian: %s\n', gmsh_msh)
    
    for nn=1:Mobj.nVerts
        fprintf(fid, '%d %f %f %f\n',nn,Mobj.x(nn),Mobj.y(nn),Mobj.h(nn));
    end
else
    error('Unsupported coordinate type. Give ''spherical'' or ''cartesian''')
end

% Now we should be at the end of the nodes and about to write the elements.

% write the element triangulation table. Format is:
%   ID, dim, n1, n2, n3
for nn=1:Mobj.nElems
    fprintf(fid, '%5d %5d %7d %7d %7d\n',nn,3,Mobj.tri(nn,1),Mobj.tri(nn,2),Mobj.tri(nn,3));
end
%--------------------------------------------------------------------------
% Write the nodestrings assuming for now that there is at least one
%--------------------------------------------------------------------------
fprintf(fid, '%d  = Number of open boundaries \n',length(Mobj.read_obc_nodes));

% Mobj.read_obc_nodes would be different if read from admesh or sms mesh
% files
try
    TotOBCN = length(cat(1,Mobj.read_obc_nodes{:}));
catch
    TotOBCN = length([Mobj.read_obc_nodes{:}]);
end

fprintf(fid, '%d  = Total number of open boundary nodes \n',TotOBCN);

% read number of open boundary nodes for each boundary
for nn=1:length(Mobj.read_obc_nodes)
    fprintf(fid, '%d  = Number of nodes for open boundary  %d \n',length(Mobj.read_obc_nodes{nn}),nn);
    for rr=1:length(Mobj.read_obc_nodes{nn})
        
        fprintf(fid, '%d \n',Mobj.read_obc_nodes{nn}(rr));
    end
end
fclose(fid);

if ftbverbose
    fprintf('end   : %s\n', subname)
end

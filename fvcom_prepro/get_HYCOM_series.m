function Mobj = get_HYCOM_series(Mobj, timestep)

obs_time = Mobj.ts_times;
% fix coninuity problem of the time
for i = 1:length(obs_time)-1
    obs_time(i+1) = obs_time(1) + (obs_time(2)-obs_time(1)) * i;
end
obs_temp = Mobj.temperature;
obs_salt = Mobj.salt;

% timestep = 1/24;
ratio = (obs_time(2)-obs_time(1))/timestep;
dims_old = length(obs_time);
dims_new = (dims_old-1)*ratio+1;

% Time
for i = 1:ratio-1
    obs_time(:,i+1) = obs_time(:,1) + 1/24 * i;
end
obs_time = reshape(obs_time',[],1);
obs_time = obs_time(1:dims_new,1);

Mobj.ts_times = obs_time;
Mobj.temperature = data2interpdata(obs_temp, timestep);
Mobj.salt = data2interpdata(obs_salt, timestep);

end


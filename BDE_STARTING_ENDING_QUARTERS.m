
start_time  = datetime(start_time, 'InputFormat','dd-MM-yyyy HH:mm:ss'); % no harm to do this!
end_time  = datetime(end_time, 'InputFormat','dd-MM-yyyy HH:mm:ss'); % no harm to do this!

% statring quarter
minute_s    = minute(start_time);
hour_s      = hour(start_time); 

if minute_s < 15
    q = 1;
elseif (15 <= minute_s) && (minute_s < 30)
    q = 2;
elseif (30 <= minute_s) && (minute_s < 45)
    q = 3;
elseif (45 <= minute_s)
    q = 4;
end
qs = q+1;
q_strt = hour_s * 4 + qs; % starting quarter

% ending quarter
minute_e    = minute(end_time);
hour_e      = hour(end_time);

if minute_e < 15
    qe = 1;
elseif (15 <= minute_e) && (minute_e < 30)
    qe = 2;
elseif (30 <= minute_e) && (minute_e < 45)
    qe = 3;
elseif (45 <= minute_e)
    qe = 4;
end
q_end = hour_e * 4 + (qe+1); % ending quarter

   
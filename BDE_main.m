% Italy Pooling: Dispatching Optimization Algorithm
% Version 1.0
% Farzaneh Abbaspourtorbati (Energy AI, Alpiq DTI)
% Stefan Richter (RichterOptimization)
% =========================

function [out] = BDE_main(varargin)

dbstop if error
% ============================================
% output
out = {};
err = {};
wrnng = {};
% ============================================
% input parameters
start_time      = varargin{1};
end_time        = varargin{2}; 
status          = varargin{3};
TFIN            = varargin{4};
Units           = varargin{5};

UnitNames       = fieldnames(Units);
N               = numel(UnitNames); % Number of units

for i = 1:N
    val         = getfield(Units, UnitNames{i});
    PV(:,i)     = cell2mat(val.PV); % MW
    Pmax(:,i)   = cell2mat(val.Pmax);
    Pmin(:,i)   = cell2mat(val.Pmin);    
    dmax(:,i)   = val.dmax;%cell2mat(value.dmax);
    dmin(:,i)   = val.dmin;%cell2mat(value.dmin);    
    c_up(:,i)   = val.c_up;%cell2mat(value.c_up);
    c_dn(:,i)   = val.c_dn;%cell2mat(value.c_dn);    
    
    PVM_1(:,i) = cell2mat(val.PVM_1); % previous PMV @ t-1
    PVM_2(:,i) = cell2mat(val.PVM_2); % previous PVM @ t-2
    
    avai_flag(i,:) = val.Availability; % logical    
end

% ============================================
% converting hourly values to quarterly values
HH      = length(Pmax); % number of hours, 23, 24, and 25
[Pmax]  = hour2quarter(Pmax, N, HH); % Pmax is MW per hour
[Pmin]  = hour2quarter(Pmin, N, HH);
[PV]    = hour2quarter(PV, N, HH);
% power schedule of the pool
p_bar_pool  = sum(PV,2);

% ============================================
% check if the number of quarters in PV of units and Pmin/Pmax
if size(Pmax,1) ~= size(Pmin,1)
    err = 'Inconsistancy of size of Pmax and Pmin of units '; 
elseif size(Pmax,1) ~= size(PV,1)
    err = 'Inconsistancy of size of Pmax of units and PV of units'; 
end
% ============================================
if isempty(err)

Tq  = 4*HH; % Number of quarters

dmax    = repmat(dmax,Tq,1);
dmin    = repmat(dmin,Tq,1);
c_up    = repmat(c_up,Tq,1);
c_dn    = repmat(c_dn,Tq,1);

%% Availability checks:
% if Pmax < Pmin, this unit is not available, and cannot be activated.
% we set Pmax equal to Pmin equal to PV to ensure this unit cannot move.
avail_check = Pmax-Pmin;
if any(avail_check(:) < 0 )
    Pmax(avail_check < 0) = PV(avail_check< 0) + 1e-4;
    Pmin(avail_check < 0) = PV(avail_check< 0) - 1e-4;
    wrnng       = 'Unit Unavailability due to Pmax Pmin';
end
if any(avai_flag == 0)
    Pmax(:,avai_flag == 0) = PV(:,avai_flag == 0) + 1e-4;
    Pmin(:,avai_flag == 0) = PV(:,avai_flag == 0) - 1e-4;
    if isempty(wrnng) == 1
        % we have to do it in this way due to transfer to python
        wrnng = 'Unit Unavailability Flag';
    else
        wrnng = {wrnng;'Unit Unavailability Flag'};
    end
end
%% starting quarter & ending quarter
BDE_STARTING_ENDING_QUARTERS;

%% Initial State
if q_strt == 1
     p0 = PV(1,:); % start of the day
elseif  any(PVM_1 ~= 0) 
    p0 = PVM_1(q_strt-1,:); % already a BDE optimization
elseif (any(PVM_1 == 0)) 
    p0 = PV(q_strt-1,:); % no previous BDE optimization
end
p_pool_0  = sum(p0); % initial values of the pool

T = Tq - q_strt + 1;

%% Flags  
flag_genLim = logical(zeros(T,1)); % we need this later for setting the flags
flag_rampLim= logical(zeros(T,1));

% ============================
%% Activation based on status:
if strcmp(status,'rc') ||  strcmp(status,'RC')  
    
    PVM_2        = PVM_2(q_strt:end,:); % ex- ex- PVM 
    if any(PVM_2 ~= 0) %
        % revoking the last available pvm
        p_opt_fair    = PVM_2;
    elseif any(PVM_2 == 0)
        % revoking the last available pvm
        p_opt_fair    = PV(q_strt:end,:);
    end    
    Prob.problem  = 0; % no optimization is done for RC
    diagn.problem = 0;
    % ============ Flags  ============
    %flag_Incmp = zeros(T,2);
else
    % cutting input parameters before q_strt (we need only those from q_strt to Tq)
    [p_bar, p_hat, c_up, c_dn, Pmax, Pmin, dmax, dmin, dmax_pool, dmin_pool, Pmax_pool, Pmin_pool] = ...
    BDE_dataPreparation( PV, p_bar_pool, TFIN, c_up, c_dn, Pmax, Pmin, dmax, dmin,  q_strt, Tq);

    if strcmp(status,'s') ||  strcmp(status,'S')        
        p_hat = p_hat(1)*ones(T,1); % data preparation for status "STAY"
    end
 
    if abs(TFIN) ~= 0 
        % Optimization
        BDE_optimization;
        BDE_optimality_flag_check;        
    elseif TFIN == 0
        p_opt_fair    = p_bar; % PV 
        Prob.problem  = 0;
        diagn.problem = 0;                
    end

end

else
    p_opt_fair       = zeros(T,N);
    Prob.problem     = -100;
    diagn.problem    = -100;
    wrnng            = 'Err Incompatible Input Parameters';
end

%% output

for i = 1:N
    out.('UnitPVM').(UnitNames{i})= p_opt_fair(:,i);
end

out.('flag_genLim')     = flag_genLim;
out.('flag_rampLim')    = flag_rampLim;
out.('err')             = err;
out.('wrnng')           = wrnng;
out.('BDEoptStatus')    = [Prob.problem , diagn.problem];
out.('startingQuarter').('hour')    = hour_s;
out.('startingQuarter').('quarter') = qs;

end





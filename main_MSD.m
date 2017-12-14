% Italy Pooling: Dispatching Optimization Algorithm
% Version 1.0
% Farzaneh Abbaspourtorbati (Energy AI, Alpiq DTI)
% Stefan Richter (RichterOptimization)
% =========================

function [out] = main_MSD_optimization(varargin)
dbstop if error
% output
out     = {};
err     = {};
wrnng   = {};
% ============================================
% input parameters

MSD     = varargin{1};
Units   = varargin{2}; 

HourNames       = fieldnames(MSD.AggResult);
HH              = numel(HourNames);
T               = 4* HH; % Number of quarters: at time change, HH could be 23 or 25, otherwise 24 hours

[ PV_MSD_pool ] = Reading_MSD_aggregatedResult(MSD.AggResult, HourNames, HH);
[PV, Pmax, Pmin, dmax, dmin, c_up, c_dn, avai_flag, N, UnitNames ] = Reading_UnitParams(Units, T);
% ============================================
% check if the number of quarters are consistant between PV of units and requets of TERNA
if size(Pmax,1) ~= T
    err = 'Inconsistancy between number of quarters in Pmax of units and MDS aggregated result'; 
elseif size(Pmax,1) ~= size(Pmin,1)
    err = 'Inconsistancy of size of Pmax and Pmin of units '; 
elseif size(Pmax,1) ~= size(PV,1)
    err = 'Inconsistancy of size of Pmax of units and PV of units'; 
end
% ============================================
%  Pool
dmax_pool = min(dmax,[],2); % gradient is equal to that of the slowest unit
dmin_pool = max(dmin,[],2);
Pmax_pool = sum(Pmax,2);
Pmin_pool = sum(Pmin,2);

p_hat = PV_MSD_pool; 
p_bar = PV;

%% Initial State
% since there is only one MSD aggregated result for each hour,
% initial state is always PV at the start hour of the correspoding
% time slot.

p0          = PV(1,:); % always starting quarter of the day as we do the optimization for the whole 24 hour %PV(q_strt,:); 
p_pool_0    = sum(p0); % initial values of the pool
flag_genLim = logical(zeros(T,1)); % we need this later for setting the flags
flag_rampLim= logical(zeros(T,1));
%% Optimization problem:

if isempty(err)
    % ============================================
    % Availability checks:
    % if Pmax < Pmin, this unit is not available, and cannot be activated.
    % we set Pmax equal to Pmin equal to PV to ensure this unit cannot move.
    avail_check = Pmax-Pmin;    
    if any(avail_check(:) < 0 )
        Pmax(avail_check < 0) = PV(avail_check< 0)+ 1e-4;
        Pmin(avail_check < 0) = PV(avail_check< 0)- 1e-4;
        wrnng       = 'Unit Unavailability due to Pmax Pmin';
    end
    if any(avai_flag == 0)
        Pmax(:,avai_flag == 0) = PV(:,avai_flag == 0)+ 1e-4;
        Pmin(:,avai_flag == 0) = PV(:,avai_flag == 0)- 1e-4;        
        if isempty(wrnng) == 1
            % we have to do it in this way due to transfer to python
            wrnng = 'Unit Unavailability Flag';
        else
            wrnng = {wrnng;'Unit Unavailability Flag'};
        end
    end   
    % ============================================
    % Optimization
    MSD_optimization;
    % ============================================
    % cheking the optimality flag of yalmip
    if (diagn.problem == 0)||(diagn.problem == 3)
        if (Prob.problem == 0)||(Prob.problem == 3)            
            FLAG_MSD;            
        else
            err         = 'There is a problem with cost minimization'; 
            wrnng       = 'no check was done';
            p_opt_fair  = zeros(T,N);
        end
    else
        if (Prob.problem == 0)||(Prob.problem == 3)
            err = 'There is a problem with allocation optimiztaion, but not cost minimization';            
        else
            err = 'There is a problem with cost minimization and allocation optimiztaion';
            p_opt_fair       = zeros(T,N);
        end
        
        if isempty(wrnng) == 1 
            % we have to do it in this way due to transfer to python
            wrnng = 'Err problem with solver feasibility flags'; 
        else
            wrnng = {wrnng;'Err problem with solver feasibility flags'};
        end  
    end
   % ============================================
else
   p_opt_fair       = zeros(T,N);
   Prob.problem     = -100;
   diagn.problem    = -100;
   wrnng            = 'Err Incompatible MSD Input Parameters';
end

%% output
for i = 1:N
    out.('UnitPVmsd').(UnitNames{i}) = p_opt_fair(:,i);
end

out.('flag_genLim')     = flag_genLim;
out.('flag_rampLim')    = flag_rampLim;
out.('MSDoptStatus')    = [Prob.problem , diagn.problem];
out.('wrnng')           = wrnng ;
out.('err')             = err;

end


function [p_bar, p_hat, c_up, c_dn, Pmax, Pmin, dmax, dmin, dmax_pool, dmin_pool, Pmax_pool, Pmin_pool] = BDE_dataPreparation( PV, p_bar_pool, TFIN, c_up, c_dn, Pmax, Pmin, dmax, dmin, q_strt,T_cut)
%% data preparation

% cutting input parameters 
p_bar       = PV(q_strt:T_cut,:);
p_hat       = p_bar_pool(q_strt:T_cut)+ TFIN ;
c_up        = c_up(q_strt:T_cut,:);
c_dn        = c_dn(q_strt:T_cut,:);
Pmax        = Pmax(q_strt:T_cut,:);
Pmin        = Pmin(q_strt:T_cut,:);
dmax        = dmax(q_strt:T_cut,:);
dmin        = dmin(q_strt:T_cut,:);
% PVM1        = PVM1(q_strt:T_cut,:);
% PVM2        = PVM2(q_strt:T_cut,:);
%  data preparation: Pool
dmax_pool = min(dmax,[],2); % gradient is equal to that of the slowest unit
dmin_pool = max(dmin,[],2);
Pmax_pool = sum(Pmax,2);
Pmin_pool = sum(Pmin,2);

end


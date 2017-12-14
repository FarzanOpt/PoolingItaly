%% Optimization Model
yalmip('clear')

%% Tunning parameters
sigma       = 0.001;
rho         = 1e-3;
%% Cost Minimization
% decision variables
d       = sdpvar(T,N, 'full');    % d_i,t
p       = sdpvar(T,N, 'full');    % p_i,t
p_pool  = sum(p,2);               % pool

% constraints
Constraints = [];
for t = 1:T
    if t == 1
        Constraints = Constraints + (p(t,:) == p0 + d(t,:)) ;
        Constraints = Constraints + (dmin_pool(t) <= p_pool(t)-p_pool_0 <= dmax_pool(t));
    else
        Constraints = Constraints + (p(t,:) == p(t-1,:) + d(t,:));
        Constraints = Constraints + (dmin_pool(t) <= p_pool(t)-p_pool(t-1) <= dmax_pool(t));
    end
end

Constraints = [Constraints, Pmin <= p <= Pmax, dmin <= d <= dmax];
% obj function (numerical)
obj     =  sum( abs(p_pool-p_hat)+ sigma* sum( max ( c_up.*(p-p_bar) , -c_dn.*(p-p_bar) ),2) ) ;
Prob    = optimize(Constraints,obj);
p_opt   = value(p); 
f_star  = value(obj);

%% fair allocation (convex version)
G_up = createGroup(c_up);
G_dn = createGroup(c_dn);

% set up the optimization problem
Constraints = [Constraints, obj <= f_star];
obj_fair = 0;
for t = 1:T
    aux_t = 0;
    for I_t_up = G_up{t}
        aux_t = aux_t + ...
            sum(Pmax(t,I_t_up{:}) - Pmin(t,I_t_up{:})) * ...
            max(max(0, p(t,I_t_up{:})-p_bar(t,I_t_up{:})) ./ ...
            (Pmax(t,I_t_up{:}) - Pmin(t,I_t_up{:})));
    end
    for I_t_dn = G_dn{t}
        aux_t = aux_t + ...
            sum(Pmax(t,I_t_dn{:}) - Pmin(t,I_t_dn{:})) * ...
            max(max(0, p_bar(t,I_t_dn{:})-p(t,I_t_dn{:})) ./ ...
            (Pmax(t,I_t_dn{:}) - Pmin(t,I_t_dn{:})));
    end
    obj_fair = obj_fair + aux_t;
end
obj_fair = obj_fair + rho * sum(sum(d.^2));

% solve the problem
diagn      = optimize(Constraints,obj_fair,sdpsettings('solver', 'quadprog'));
p_opt_fair = value(p);



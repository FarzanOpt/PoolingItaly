
% cheking the optimality flag of yalmip
if (diagn.problem == 0)||(diagn.problem == 3)
    if (Prob.problem == 0)||(Prob.problem == 3)
        FlagBDE;
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
    wrnng = 'Err problem with solver feasibility flags';
end
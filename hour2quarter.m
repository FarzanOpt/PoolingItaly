% This m file changes the hourly values to quarterly values
function [out] = hour2quarter(in, N, T_h)


% Note that matrix "in" is Power [MW], and not Enegry [MWh]

for i = 1:N
    bin    = [];
    for h = 1:T_h
        bin = [bin ; in(h,i)* ones(4,1)];
    end
    out(:,i) = bin;
end


end



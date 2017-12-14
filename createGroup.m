% ======= function groups units with equal cost =========
function G = createGroup(costs)
% Creates a group (which is a set of sets) according to the pdf 'Fair
% Allocation in IT Pooling'

T = size(costs,1);
G = cell(T,1);

for t = 1:T
    costs_t_unique = unique(costs(t,:));
    n_unique = numel(costs_t_unique);
    G_t = cell(1, n_unique);
    for j=1:n_unique
        G_t{j} = find(costs(t,:) == costs_t_unique(j));
    end
    G{t} = G_t;
end

end
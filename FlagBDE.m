if any( abs(p_hat - p_pool_opt) > 1e-6)
% Pool pmax and pmin
    if (TFIN > 0) % upward activation    
        flag_genLim(:,1) = (p_hat-Pmax_pool > 0).*ones(T,1);
        flag_genLim(flag_genLim(:,1) ==1) =logical(1);
        
        if sum(sum(flag_genLim)) ~= 0
            if isempty(wrnng) == 1
                % we have to do it in this way due to transfer to python
                wrnng = 'violation of Pmax in BDE optimization';
            else
                wrnng = {wrnng;'violation of Pmax in BDE optimization'};
            end
        end       
    elseif (TFIN < 0) % downward activation
        flag_genLim(:,1) = (p_hat-Pmin_pool < 0).*ones(T,1);
        flag_genLim(flag_genLim(:,1) ==1) = logical(1);
        if sum(sum(flag_genLim)) ~= 0           
            if isempty(wrnng) == 1 
                % we have to do it in this way due to transfer to python
                wrnng = 'violation of Pmin in BDE optimization'; 
            else
                wrnng = {wrnng;'violation of Pmin in BDE optimization'};
            end
        end 
    end
    % Pool gradient
    for t = 1:T
        if t == 1
            ramp(t)= p_hat(t) - p_pool_0;
        else
            ramp(t)= p_hat(t) - p_hat(t-1);
        end
        if (dmin_pool(t) <= ramp(t)) && ( ramp(t) <= dmax_pool(t))
            flag_rampLim(t) = logical(0);
        elseif (dmax_pool< ramp(t))
            flag_rampLim(t) = logical(1);            
            
            if isempty(wrnng) == 1
                wrnng = ['violation of dmax in BDE optimization at q',num2str(t)];
            else
                wrnng = {wrnng; ['violation of dmax in BDE optimization at q',num2str(t)]};
            end
            
        elseif (ramp(t) < dmin_pool(t))
            flag_rampLim(t) = logical(1);
            if isempty(wrnng) == 1
                wrnng = ['violation of dmin in BDE optimization at q',num2str(t)];
            else
                wrnng = {wrnng; ['violation of dmin in BDE optimization at q',num2str(t)]};
            end
        end
    end
end





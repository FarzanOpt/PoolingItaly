%% Flags
if any(abs(p_hat - value(p_pool)) > 1e-6) % check if demand is not fully met
    % check if requested schedule p_hat is larger than Pmax 
    if any(Pmax_pool < p_hat)
        flag_genLim(:,1) = (p_hat-Pmax_pool > 0).*ones(T,1);        
        flag_genLim(flag_genLim(:,1) == 1) = logical(1);
        if sum(sum(flag_genLim)) ~= 0        
            if isempty(wrnng) == 1 
                % we have to do it in this way due to transfer to python
                wrnng = 'violation of Pmax in MSD optimization'; 
            else
                wrnng = {wrnng;'violation of Pmax in MSD optimization'};
            end             
        end
    end
    % check if requested schedule is smaller than Pmin 
    if any(Pmin_pool > p_hat)
        flag_genLim(:,1) = (p_hat-Pmin_pool < 0).*ones(T,1);
        flag_genLim(flag_genLim(:,1) == 1) = logical(1);
        
        if sum(sum(flag_genLim)) ~= 0
            if isempty(wrnng) == 1 
                % we have to do it in this way due to transfer to python
                wrnng = 'violation of Pmin in MSD optimization'; 
            else
                wrnng = {wrnng;'violation of Pmin in MSD optimization'};
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
            flag_rampLim(t) = logical(0); % no problem
           
        elseif (dmax_pool< ramp(t))
            flag_rampLim(t) = logical(1);
            
            if isempty(wrnng) == 1
                wrnng = ['violation of dmax in MSD optimization at q',num2str(t)];
            else
                wrnng = {wrnng; ['violation of dmax in MSD optimization at q',num2str(t)]};
            end
             
        elseif (ramp(t) < dmin_pool(t))
            flag_rampLim(t) = logical(1);
            
            if isempty(wrnng) == 1
                wrnng = ['violation of dmin in MSD optimization at q',num2str(t)];
            else
                wrnng = {wrnng; ['violation of dmin in MSD optimization at q',num2str(t)]};
            end
            
        end
    end
    
end

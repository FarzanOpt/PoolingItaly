function [ PV_pool ] = Reading_MSD_aggregatedResult(IN, HourNames, HH)
% reading MSD aggregated result

for i = 1:HH
    val = getfield(IN, HourNames{i});
    hourname = HourNames{i};
    hh  = str2num(hourname(5:end)); % !! This is only valid if the first 4 letters are "hour"!!
    
    indx(i) = hh ;
    bin{i} = cell2mat(val) ;
end

[~, inx]    = sort(indx); % sorting based on hours
PV_pool     = bin(inx);
PV_pool     = cell2mat(PV_pool)';

% HourNames       = fieldnames(IN);
% HH              = numel(HourNames);
% if HH == 24
%     for i = 1:HH
%         val = getfield(IN, HourNames{i});
%         hourname = HourNames{i};
%         hh  = str2num(hourname(5:end)); % !! This is only valid if the first 4 letters are "hour"!!
%         
%         indx(i) = hh ;
%         bin{i} = cell2mat(val) ;
%     end
%     
%     [~, inx]    = sort(indx); % sorting based on hours
%     PV_pool     = bin(inx);
%     PV_pool     = cell2mat(PV_pool)';
%     err = {};
% else
%     err = 'T is smaller than 24 hours for MSD';
%     PV_pool = [];
% end
end










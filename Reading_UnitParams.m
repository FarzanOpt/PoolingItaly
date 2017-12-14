function [ PV, Pmax, Pmin, dmax, dmin, c_up, c_dn, avai_flag, N, UnitNames ] = Reading_UnitParams( Units, Tq )

UnitNames   = fieldnames(Units);
N           = numel(UnitNames); % Number of units

PV      = [];
Pmax    = [];
Pmin    = [];

for i = 1:N
    val         = getfield(Units, UnitNames{i});
    PV(i,:)     = cell2mat(val.PV);
    Pmax(i,:)   = cell2mat(val.Pmax);
    Pmin(i,:)   = cell2mat(val.Pmin);
    dmax(i,:)   = val.dmax;%cell2mat(value.dmax);
    dmin(i,:)   = val.dmin;%cell2mat(value.dmin);
    c_up(i,:)   = val.c_up;%cell2mat(value.c_up);
    c_dn(i,:)   = val.c_dn;%cell2mat(value.c_dn);
    avai_flag(i,:)   = val.availability;
end

[PV]    = hour2quarter(PV', N, 24); % converting hourly resolution to quarterly 
[Pmax]  = hour2quarter(Pmax', N, 24);
[Pmin]  = hour2quarter(Pmin', N, 24);

p_bar_pool  = sum(PV,2); % pool schedule

dmax    = repmat(dmax',Tq,1);
dmin    = repmat(dmin',Tq,1);
c_up    = repmat(c_up',Tq,1);
c_dn    = repmat(c_dn',Tq,1);

end


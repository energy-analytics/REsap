function [m_spec_el, m_spec_th] = chp_co2_allocation(m_spec_fuel,W_fuel, eta_el, W_el, eta_th, W_th, method)

% Wirkungsgradmethode:
if (strcomp(method, 'wirk'))
A_Br_el = eta_th ./ (eta_el + eta_th);
A_Br_th = eta_el ./ (eta_el + eta_th);

CO2_el=m_spec_fuel .* W_fuel .* A_Br_el;
CO2_th=m_spec_fuel .* W_fuel .* A_Br_th;
elseif (strcomp(method, 'IEA'))
A_Br_el = eta_el ./ (eta_el + eta_th);
A_Br_th = eta_th ./ (eta_el + eta_th);

CO2_el=m_spec_fuel .* W_fuel .* A_Br_el;
CO2_th=m_spec_fuel .* W_fuel .* A_Br_th;
end
    

% same for all methods:
m_spec_el=CO2_el./W_el
m_spec_th=CO2_th./W_th;
end
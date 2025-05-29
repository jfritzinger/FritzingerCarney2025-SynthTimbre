function rates_sm = smooth_rates(rates,rates_min,rates_max, CF)
% Compute the smoothest curve that falls between rates_min and rates_max.
% The criterion for smoothness is to minimize the sum of the second
% derivative.

if ~isempty(CF) && CF < 760 % Smooth less for neurons with very low CFs
	fun = @(x) sum(diff(diff(x)).^2) + 0.7*sum((x - rates).^2);
elseif ~isempty(CF) && CF < 3000
	fun = @(x) sum(diff(diff(x)).^2) + 0.4*sum((x - rates).^2);
else
	fun = @(x) sum(diff(diff(x)).^2) + 0.1*sum((x - rates).^2);
end
opt = optimset('fmincon');
opt.Algorithm = 'active-set';
opt.Display = 'off';
rates_sm = fmincon(fun,rates,[],[],[],[],rates_min,rates_max,[],opt);

end
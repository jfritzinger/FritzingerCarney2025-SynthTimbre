function [m,s,v, min_x,max_x] = accumstats(indices,x,full_size)
% Similar to accumarray except that instead of returning the sum it returns
% the mean and standard deviation.

if nargin < 3
    full_size = [];
end
m = accumarray(indices,x,full_size,@mean);
s = accumarray(indices,x,full_size,@std);
v = accumarray(indices,x,full_size,@var);
if nargout > 2
    min_x = accumarray(indices,x,full_size,@min);
end
if nargout > 3
    max_x = accumarray(indices,x,full_size,@max);
end
end
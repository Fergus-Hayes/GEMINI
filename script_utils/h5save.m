function h5save(filename, varname, A, sizeA)

narginchk(3, 4)

if nargin < 4
  if isvector(A)
    sizeA = length(A);
  else
    sizeA = size(A);
  end
end

varnames = {};
if isfile(filename)
  varnames = extractfield(h5info(filename).Datasets, 'Name');
end

stem = varname;
if stem(1) == '/'; stem = stem(2:end); end

if any(strcmp(stem, varnames))
  h5write(filename, varname, A, 1, length(A))
else % new variable
  h5create(filename, varname, sizeA, 'Datatype', class(A))
  h5write(filename, varname, A)
end

end % function

function h5w(fn, name, value)
%% writes single variable to HDF5 file, creating file if needed
% This function could be adapted to GNU Octave as well.

validateattributes(fn, {'char'}, {'vector'})
validateattributes(name, {'char'}, {'vector'})
validateattributes(value, {'numeric'}, {'nonsparse'})

if ~strncmp(name, '/', 1)
  name = ['/',name]; 
end

h5create(fn, name, size(value))
h5write(fn, name, value)
end
function rpath = resolvepath(filename)
%% cleanup relative paths to absolute paths
% 
% examples:
%
% resolvepath('../../blah') => ~/code/blah
%
% resolvepath('~/hello/a/../../data') => ~/data

rpath = char(java.io.File(filename).getCanonicalPath());
end
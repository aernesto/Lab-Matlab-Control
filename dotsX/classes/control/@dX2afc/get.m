function val_ = get(af_, propertyName)
%get method for class dX2afc: query property values
%   val_ = get(af_, propertyName)
%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% gets named property of a 2afc object.
%----------Special comments-----------------------------------------------
%
%   See also get dX2afc

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

val_ = af_(1).(propertyName);

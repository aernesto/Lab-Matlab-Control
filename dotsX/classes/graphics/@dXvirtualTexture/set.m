function vt_ = set(vt_, varargin)
%set method for class dXvirtualTexture: specify property values and recompute dependencies
%   vt_ = set(vt_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overloaded set method for class dXvirtualTexture
%-%
%-% Assigns properties to 'dXvirtualTexture' object(s)
%-% and returns the updated object(s)
%-%
%----------Special comments-----------------------------------------------
%
%   See also set dXvirtualTexture

% Copyright 2008 by Benjamin Heasly
%   University of Pennsylvania

% get access to DotsX data and OpenGL constants
global ROOT_STRUCT GL
AssertGLSL

% set the fields, one at a time.. no error checking
if length(vt_) == 1

    % set one object
    for ii = 1:2:nargin-1
        vt_.(varargin{ii}) = varargin{ii+1};
    end
else

    % set many objects  ... a cell means separate
    %   values given for each object; otherwise
    %   the same value is set for all objects
    inds=ones(size(vt_));
    for ii = 1:2:nargin-1

        % change it
        if iscell(varargin{ii+1}) && ~isempty(varargin{ii+1})
            [vt_.(varargin{ii})] = deal(varargin{ii+1}{:});
        else
            [vt_.(varargin{ii})] = deal(varargin{ii+inds});
        end
    end
end

for ti = 1:length(vt_)

    % copy of one instance
    t = vt_(ti);

    % try to detect whether we need to load the texture
    if isempty(t.texture) || ~any(t.texture == Screen('Windows'));

        % locate the GLSL shader code
        shadFile = fullfile(t.dir, t.file);

        % compile the GLSL program
        if exist(shadFile)
            t.GLSLProgram = LoadGLSLProgramFromFiles(shadFile, t.GLSLDebugMode);

            if t.GLSLProgram <= 0
                warning(sprintf('dXtexture/set could not load file: \n%s', shadFile));
            end
        else
            warning(sprintf('dXtexture/set could not find file:\n%s', shadFile));
        end

        % account onscreen real estate
        xPix = t.x*t.pixelsPerDegree;
        yPix = t.y*t.pixelsPerDegree;

        % default to fullscreen width
        if isempty(t.w) || isnan(t.w) || isinf(t.w)
            wPix = t.screenRect(3);
        else
            wPix = ceil(t.w*t.pixelsPerDegree);
        end

        % default to fullscreen height
        if isempty(t.h) || isnan(t.h) || isinf(t.h)
            hPix = t.screenRect(4);
        else
            hPix = ceil(t.h*t.pixelsPerDegree);
        end

        % make a rectangle
        t.drawRect([2,4]) = [yPix, yPix+hPix] + t.screenRect(4)/2 - hPix/2;
        t.drawRect([1,3]) = [xPix, xPix+wPix] + t.screenRect(3)/2 - wPix/2;

        % default source rect is the whole texture
        if isempty(t.sourceRect)
            t.sourceRect = [0,0,wPix,hPix];
        end

        % Create new virtual texture attached to GLSL program
        t.texture = Screen('SetOpenGLTexture', t.windowNumber, [], 0, ...
            GL.TEXTURE_RECTANGLE_EXT, wPix, hPix, 1, t.GLSLProgram);

        % forget any old GLSL variable locations
        t.GLSLLocations = [];
    end

    % run through any GLSL variables that need setting
    if ~isempty(t.GLSLArgs)

        % set each one
        for ii = 1:2:length(t.GLSLArgs)
            t = setGLSLValue(t, t.GLSLArgs{ii}, t.GLSLArgs{ii+1});
        end

        t.GLSLArgs = {};
    end

    % copy back this instance
    vt_(ti) = t;
end                       
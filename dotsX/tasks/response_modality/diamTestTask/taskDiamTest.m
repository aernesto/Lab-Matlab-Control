function index_ = taskDiamTest(varargin)

% name of this task
name = mfilename;

arg_dXdots = { ...
    'x',            0, ...
    'y',            0, ...
    'diameter',     1, ...
    'size',         3, ...
    'speed',        5, ...
    'coherence',    6.4, ...
    'direction',    0, ...
    'density',      25, ...
    'color',        [1,1,1,1]*255};

arg_dXtarget = { ...
    'x',            0, ...
    'y',            0, ...
    'penWidth',     1, ...
    'diameter',     .4, ...
    'color',        [1,0,0,1]*255};

arg_dXfeedback = { ...
    'groupName',        'iti', ...
    'doEndTrial',       'block', ...
    'size',             22, ...
    'bold',             true, ...
    'x',                -16, ...
    'tasksColor',       [1 1 0]*255, ...
    'totalsColor',      [1 1 0]*255, ...
    'displaySecs',      6e2};

dir = {'dXdots', 1, 'direction'};
diam = {'dXdots', 1, 'diameter'};
coh = {'dXdots', 1, 'coherence'};
arg_dXtc = { ...
    'name',     {'dot_dir', 'dot_diam', 'dot_coh'}, ...
    'values',	{[0, 180], linspace(5,15,5), [6.4 12.8]}, ...
    'ptr',      {dir, diam, coh}};

arg_dXlr = { ...
    'ptr',      {{'dXdots', 1, 'direction'}}};

respond = { ...
    'dXkbHID',  {'j', 'right', 'f', 'left'}; ...
    'dXPMDHID', {11, 'right', 9, 'left'}; ...
    'dXasl',    {}};

left = { ...
    'dXkbHID',  {'j', 'both'}; ...
    'dXPMDHID',	{11, 'both'}; ...
    'dXasl',    {}};
right = { ...
    'dXkbHID',  {'f', 'both'}; ...
    'dXPMDHID',	{9, 'both'}; ...
    'dXasl',    {}};

lcon = {'jump', {'dXlr', 1, 'value'}, [0 1], {'correct'; 'incorrect'}};
rcon = {'jump', {'dXlr', 1, 'value'}, [0 1], {'incorrect'; 'correct'}};

SP = @rPlay;
GS = @rGraphicsShow;
VU = @rVarUpdate;

bp = {'dXbeep', 1};
sd = 'dXsound';
ptrs = {'dXtc', 'dXlr'};
fp = {'dXtarget', 1};
dt = {'dXdots', 1, {}, fp{:}};

show = 5000;
hang = 100;

%   name        fun args        jump    wait    repsDrawQuery   cond
arg_dXstate = {{ ...
    'clear',    {}, {},         'next', 0,      0,  5,  0,      {}; ...
    'indicate', GS, fp,         'next', 0,      0,  3,  0,      {}; ...
    'tone1',	SP, bp,         'next', 100,	0,  0,  0,      {}; ...
    'nextStim',	VU, ptrs,       'next', 400,    0,  0,  0,      {}; ...
    'onStim',	GS, dt,         'next', 200,    0,  0,  0,      {}; ...
    'tone2',	SP, bp,         'next', 100,	0,  0,  0,      {}; ...
    'showStim', {}, {},         'error',show,   0,  1,  respond,{}; ...
    ...
    'left',     {}, {},         'error',hang,	0,  5,  left,   lcon; ...
    'right',    {}, {},         'error',hang,	0,  5,  right,  rcon; ...
    'both',     {}, {},         'error',0,      0,  0,  0,      {}; ...
    ...
    'correct',  SP, {sd,1},     'end',  500,	0,  0,  0,      {}; ...
    'incorrect',SP, {sd,2},     'end',  500,	0,  0,  0,      {}; ...
    'error',    SP, {sd,3},     'next', 500,	0,  5,  0,      {}; ...
    'end',      {}, {},         'x',    0,      0,  5,  0,      {}; ...
    }};
sz = size(arg_dXstate{1}, 1);

% get general task settings for modality tasks
arg_dXtask = modality_task_args;

% create this specific task
static = {'root', false, true, false};
index_ = rAdd('dXtask', 1, {'root', false, true, false}, ...
    'name',         name(5:end), ...
    'blockReps',    10, ...
    'timeLimit',    60*60, ...
    'helpers',      { ...
        'gXmodality_hardware',          1,	static, {}; ...
        'dXfeedback',                   1,  static, arg_dXfeedback; ...
        'dXdots',                       1,  static, arg_dXdots; ...
        'dXtarget',                     1,  static, arg_dXtarget; ...
        'dXtc',                         3,  static, arg_dXtc; ...
        'dXlr',                         1,  static, arg_dXlr; ...
        'dXstate',                      sz,	static, arg_dXstate; ...
    }, ...
    arg_dXtask{:}, varargin{:});
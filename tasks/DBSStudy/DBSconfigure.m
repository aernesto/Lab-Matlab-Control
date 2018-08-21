function topNode =  DBSconfigure(varargin)
%% function topNode =  DBSconfigure(varargin)
%
% This function sets up a DBS experiment. We keep this logic separate from
% running and cleaning up an experiment because we may want to decide
% when/how do do those other things on the fly (e.g., add/subtract tasks
% depending on the subject's motivation, etc).
%
% Arguments:
%  varargin  ... optional <property>, <value> pairs for settings variables
%                 note that <property> can be a cell array for nested
%                 property structures in the task object
%
% Returns:
%  mainTreeNode ... the topsTreeNode at the top of the hierarchy
%
% 11/17/18   jig wrote it

%% ---- Parse arguments for configuration settings
%
% Name of the experiment, which determines where data are are stored
name = 'DBSStudy';

% Other defaults
settings = { ...
   'taskSpecs',                  {'VGS' 1 'NN' 1 'Quest' 1 'AN' 1 'SN' 1 'NL' 1 'NR' 1}, ...
   'runGUIname',                 'eyeGUI', ...
   'databaseGUIname',            [], ...
   'remoteDrawing',              true, ...
   'instructionDuration',        1, ...
   'displayIndex',               1, ... % 0=small, 1=main
   'uiList',                     'dotsReadableEyePupilLabs', ...
   'queryDuringCalibration',     false, ...
   'sendTTLs',                   false, ...
   'targetDistance',             8, ...
   'gazeWindowSize',             6, ...
   'gazeWindowDur',              0.15, ...
   'saccadeDirections',          0:90:270, ...
   'dotDirections',              [0 180], ...
   'referenceRT',                500, ... % for speed feedback
   };

% Update from argument list (property/value pairs)
for ii = 1:2:nargin
   settings{find(strcmp(varargin{ii}, settings),1) + 1} = varargin{ii+1};
end

% Standard trialData structure
trialData = struct( ...
   'taskID',                     nan, ...
   'trialIndex',                 nan, ...
   'direction',                  nan, ...
   'coherence',                  nan, ...
   'randSeedBase',               nan, ...
   'choice',                     -3, ...
   'RT',                         nan, ...
   'correct',                    -3, ...
   'time_screen_fixOn',          nan, ...
   'time_screen_targsOn',        nan, ...
   'time_screen_dotsOn',         nan, ...
   'time_screen_targsOff',       nan, ...
   'time_screen_fixOff',         nan, ...
   'time_ui_choice',             nan, ...
   'time_screen_dotsOff',        nan, ...
   'time_screen_fdbkOn',         nan);

%% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode
topNode = topsTreeNodeTopNode(name);

% Add a topsGroupedList as the nodeData, plus other fields, then configure
topNode.nodeData = topsGroupedList.createGroupFromList('Settings', settings);

% Add GUIS
topNode.runGUIname      = topNode.nodeData{'Settings'}{'runGUIname'};
topNode.databaseGUIname = topNode.nodeData{'Settings'}{'databaseGUIname'};
      
% Add the screen and text ensemble
topNode.addDrawables(topNode.nodeData{'Settings'}{'displayIndex'}, ...
   topNode.nodeData{'Settings'}{'remoteDrawing'}, true);

% Add the user interface device(s)
topNode.addReadables(topNode.nodeData{'Settings'}{'uiList'});

% Change eye settings
ui = topNode.sharedProperties.readableList{1};
if isa(ui, 'dotsReadableEye')
   ui.queryDuringCalibration = false;
end

%% ---- Make call lists to show text between tasks
%
% Welcome call list
welcome = topsCallList();
welcome.alwaysRunning = false;
welcome.addCall({@dotsDrawableText.drawEnsemble, topNode.sharedProperties.textEnsemble, { ...
   'Work at your own pace.', ...
   'Each trial starts by fixating the central cross'}, ...
   topNode.nodeData{'Settings'}{'instructionDuration'}, 1}, 'text');

% Countdown call list
countdown = topsCallList();
countdown.alwaysRunning = false;
for ii = 1:10
   countdown.addCall({@dotsDrawableText.drawEnsemble, topNode.sharedProperties.textEnsemble, ...
      {'Well done!', sprintf('Next task starts in: %d', 10-ii+1)}, 1, 0}, ...
      sprintf('c_%d', ii));
end
countdown.addCall({@pause, 1}, 'pause');

%% ---- Loop through the task specs array, making tasks with appropriate arg lists
%
taskSpecs = topNode.nodeData{'Settings'}{'taskSpecs'};
QuestTask = [];
noDots    = true;
for ii = 1:2:length(taskSpecs)
   
   % Make list of properties to send
   args = { ...
      {'settings',  'targetDistance'},    topNode.nodeData{'Settings'}{'targetDistance'}, ...
      {'timing',    'showInstructions'},  topNode.nodeData{'Settings'}{'instructionDuration'}, ...
      'trialData',                        trialData, ...
      'taskID',                           (ii+1)/2, ...
      'taskTypeID',                       find(strcmp(taskSpecs{ii}, {'VGS' 'MGS' 'Quest' 'NN' 'NL' 'NR' ...
      'SN' 'SL' 'SR' 'AN' 'AL' 'AR'}),1)};
   
   switch taskSpecs{ii}
      
      case {'VGS' 'MGS'}
         
         % Make Saccade task with args
         task = topsTreeNodeTaskSaccade.getStandardConfiguration( ...
            taskSpecs{ii}, taskSpecs{ii+1}, ...
            {'direction', {'values', topNode.nodeData{'Settings'}{'saccadeDirections'}}}, ...
            args{:});
         
      otherwise
         
         % If there was a Quest task, use to update coherences in other tasks
         if ~isempty(QuestTask)
            args = cat(2, args, ...
               {{'settings' 'useQuest'},   QuestTask, ...
               {'settings' 'referenceRT'}, QuestTask});
         end
         
         % Make RTDots task with args
         task = topsTreeNodeTaskRTDots.getStandardConfiguration( ...
            taskSpecs{ii}, taskSpecs{ii+1}, ...
            {'direction', {'values', topNode.nodeData{'Settings'}{'dotDirections'}}}, ...
            args{:});
         
         % Add special instructions for first dots task
         if noDots
            task.settings.textStrings = cat(1, ...
               {'When flickering dots appear, decide their overall direction', ...
               'of motion, then look at the target in that direction'}, ...
               task.settings.textStrings);
            noDots = false;
         end
         
         % Special case of quest ... use output as coh/RT refs
         if strcmp(taskSpecs{ii}, 'Quest')
            QuestTask = task;
         end
   end
   
   % set the window size/durations to the defaults
   if isa(topNode.sharedProperties.readableList{1}, 'dotsReadableEye')
      [task.readables.dotsReadableEye.windowSize] = deal(topNode.nodeData{'Settings'}{'gazeWindowSize'});
      [task.readables.dotsReadableEye.windowDur]  = deal(topNode.nodeData{'Settings'}{'gazeWindowDur'});
   end
   
   % Add some fevalables to show instructions/feedback before/after tasks
   if ii == 1
      task.startFevalable = {@run, welcome};
   else
      task.startFevalable = {@run, countdown};
   end
   
   % Add as child to the maintask. Have it loop forever until explicitly
   % aborted by the task logic
   task.iterations = inf;
   topNode.addChild(task);
end
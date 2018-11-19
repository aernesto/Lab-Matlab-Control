classdef topsTreeNodeTaskRTDots < topsTreeNodeTask
   % @class topsTreeNodeTaskRTDots
   %
   % Response-time dots (RTD) task
   %
   % For standard configurations, call:
   %  topsTreeNodeTaskRTDots.getStandardConfiguration
   % 
   % Otherwise:
   %  1. Create an instance directly:
   %        task = topsTreeNodeTaskRTDots();
   %
   %  2. Set properties. These are required:
   %        task.screenEnsemble
   %        task.helpers.readers.theObject
   %     Others can use defaults
   %
   %  3. Add this as a child to another topsTreeNode
   %
   % 5/28/18 created by jig
   
   properties % (SetObservable) % uncomment if adding listeners
      
      % Trial properties. 
      %
      % Set useQuest to a handle to a topsTreeNodeTaskRTDots to use it 
      %     to get coherences
      % Possible values of dotsDuration:
      %     [] (default) ... RT task
      %     [val] ... use given fixed value
      %     [min mean max] ... specify as pick from exponential distribution
      settings = struct( ...
         'minTrialsPerCondition',      10,   ...
         'useQuest',                   [],   ...
         'coherencesFromQuest',        [],   ...
         'directionPriors',            [80 20], ... % For asymmetric priors
         'referenceRT',                [],   ...
         'fixationRTDim',              0.4,  ...
         'targetDistance',             8,    ...
         'textStrings',                '',   ...
         'correctPlayableIndex',       1,    ...
         'errorPlayableIndices',       2);
      
      % Timing properties .. use three-char tags to reference in statelist
      timing = struct( ...
         'showInstructions',          10.0, ...
         'waitAfterInstructions',     0.5, ...
         'fixationTimeout',           5.0, ...
         'holdFixation',              0.5, ...
         'showSmileyFace',            0.5, ...
         'showFeedback',              1.0, ...
         'interTrialInterval',        1.0, ...
         'preTargets',                [0.2 0.5 1.0], ...
         'dotsDuration',              [],   ... 
         'dotsTimeout',               5.0, ...
         'choiceTimeout',             3.0);
      
      % Quest properties
      questSettings = struct( ...
         'stimRange',                 0:100,  	...
         'thresholdRange',            0:50,     ...
         'slopeRange',                2:5,      ...
         'guessRate',                 0.5,      ...
         'lapseRange',                0.00:0.01:0.05);

      % Fields below are optional but if found with the given names
      %  will be used to automatically configure the task
      
      % Array of structures of independent variables, used by makeTrials
      independentVariables = struct( ...
         'name',        {'direction', 'coherence'}, ...
         'values',      {[0 180], [0 3.2 6.4 12.8 25.6 51.2]}, ...
         'priors',      {[], []}, ...
         'minTrials',   {1, []});
      
      % dataFieldNames are used to set up the trialData structure
      trialDataFields = {'RT', 'choice', 'correct', 'direction', 'coherence', ...
         'randSeedBase', 'fixationOn', 'fixationStart', 'targetOn', ...
         'dotsOn', 'dotsOff', 'targetOff', 'fixationOff', 'feedbackOn'};
      
      % Drawables settings
      drawable = struct( ...
         ...
         ...   % Stimulus ensemble and settings
         'stimulusEnsemble',              struct( ...
         ...
         ...   % Fixation drawable settings
         'fixation',                   struct( ...
         'fevalable',                  @dotsDrawableTargets, ...
         'settings',                   struct( ...
         'xCenter',                    0,                ...
         'yCenter',                    0,                ...
         'nSides',                     4,                ...
         'width',                      1.0.*[1.0 0.1],   ...
         'height',                     1.0.*[0.1 1.0],   ...
         'colors',                     [1 1 1])),        ...
         ...
         ...   % Targets drawable settings
         'targets',                    struct( ...
         'fevalable',                  @dotsDrawableTargets, ...
         'settings',                   struct( ...
         'nSides',                     100,              ...
         'width',                      1.5.*[1 1],       ...
         'height',                     1.5.*[1 1])),      ...
         ...
         ...   % Smiley face for feedback
         'smiley',                     struct(  ...
         'fevalable',                  @dotsDrawableImages, ...
         'settings',                   struct( ...
         'fileNames',                  {{'smiley.jpg'}}, ...
         'height',                     2)), ...
         ...
         ...   % Dots drawable settings
         'dots',                       struct( ...
         'fevalable',                  @dotsDrawableDotKinetogram, ...
         'settings',                   struct( ...
         'xCenter',                    0,                ...
         'yCenter',                    0,                ...
         'coherenceSTD',               10,               ...
         'stencilNumber',              1,                ...
         'pixelSize',                  6,                ...
         'diameter',                   10,                ...
         'density',                    180,              ...
         'speed',                      2))));
         
      % Readable settings
      readable = struct( ...
         ...
         ...   % The readable object
         'reader',                    	struct( ...
         ...
         'copySpecs',                  struct( ...
         ...
         ...   % The gaze windows
         'dotsReadableEye',            struct( ...
         'bindingNames',               'stimulusEnsemble', ...
         'prepare',                    {{@updateGazeWindows}}, ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'breakFixation', 'choseLeft', 'choseRight'}, ...
         'ensemble',                   {'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble'}, ... % ensemble object to bind to
         'ensembleIndices',            {[1 1], [1 1], [2 1], [2 2]})}}), ...
         ...
         ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the theObject type
         'dotsReadableHIDKeyboard',    struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',                  {'KeyboardSpacebar', 'KeyboardF', 'KeyboardJ'}, ...
         'isRelease',                  {true, false, false})}}), ...
         ...
         ...   % Gamepad 
         'dotsReadableHIDGamepad',     struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',                  {'Button1', 'Trigger1', 'Trigger2'}, ...
         'isRelease',                  {true, false, false})}}), ...
         ...
         ...   % Ashwin's magic buttons
         'dotsReadableHIDButtons',     struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',                  {'KeyboardSpacebar', 'KeyboardLeftShift', 'KeyboardRightShift'}, ...
         'isRelease',                  {true, false, false})}}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy',          struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation'}, ...
         'component',                  {'auto_1'})}}))));      
   end
   
   properties (SetAccess = protected)

      % The quest object
      quest;
      
      % Boolean flag, whether an RT task or not
      isRT;
      
      % Check for changes in properties that require drawables to be 
      %  recomputed
      targetDistance;
   end
   
   methods
      
      %% Constuctor
      %  Use topsTreeNodeTask method, which can parse the argument list
      %  that can set properties (even those nested in structs)
      function self = topsTreeNodeTaskRTDots(varargin)

         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(varargin{:});
      end

      %% Start task (overloaded)
      % 
      % Put stuff here that you want to do before each time you run this
      % task
      function startTask(self)

         % ---- Set up independent variables if Quest task
         %
         if strcmp(self.name, 'Quest')
            
            % Initialize and save Quest object
            self.quest = qpInitialize(qpParams( ...
               'stimParamsDomainList', { ...
               self.questSettings.stimRange}, ...
               'psiParamsDomainList',  { ...
               self.questSettings.thresholdRange, ...
               self.questSettings.slopeRange, ...
               self.questSettings.guessRate, ...
               self.questSettings.lapseRange}));
            
            % Update independent variable struct using initial value
            self.setIndependentVariableByName('coherence', 'values', ...
               min(100, max(0, qpQuery(self.quest))));
            
         elseif ~isempty(self.settings.useQuest)
            
            % Update independent variable struct using Quest value
            self.setIndependentVariableByName('coherence', 'values', ...
               self.settings.useQuest.getCoherencesFromQuest( ...
               self.settings.coherencesFromQuest));            
         end
                  
         % ---- Initialize the state machine
         %
         self.initializeStateMachine();      
         
         % ---- Show task-specific instructions
         %
         self.helpers.feedback.showText(self.settings.textStrings, true, ...
            'showDuration', self.timing.showInstructions);
         pause(self.timing.waitAfterInstructions);
      end
      
      %% Finish task (overloaded)
      %
      % Put stuff here that you want to do after each time you run this
      % task
      function finishTask(self)         
      end
      
      %% Start trial
      %
      % Put stuff here that you want to do before each time you run a trial
      function startTrial(self)
         
         % ---- Prepare components
         %
         self.prepareDrawables();
         self.prepareStateMachine();
         
         % ---- Show information about the task/trial
         %
         % Task information
         taskString = sprintf('%s (task %d/%d): %d correct, %d error, mean RT=%.2f', ...
            self.name, self.taskID, length(self.caller.children), ...
            sum([self.trialData.correct]==1), sum([self.trialData.correct]==0), ...
            nanmean([self.trialData.RT]));
         
         % Trial information
         trial = self.getTrial();
         sprintf('Trial %d/%d, dir=%d, coh=%d', self.trialCount, ...
            numel(self.trialData)*self.trialIterations, trial.direction, trial.coherence);
         
         % Show the information
         self.statusStrings = {taskString, trialString};
         self.updateStatus(); % just update the second one         
      end
            
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)
         
         % Conditionally update Quest
         if strcmp(self.name, 'Quest')

            % ---- Check for bad trial
            %
            trial = self.getTrial();
            if isempty(trial) || trial.correct < 0
               return
            end
            
            % ---- Update Quest
            %
            % (expects 1=error, 2=correct)
            self.quest = qpUpdate(self.quest, trial.coherence, trial.correct+1);
            
            % Update next guess, bounded between 0 and 100, if there is a next trial
            if self.trialCount < length(self.trialIndices)
               self.trialData(self.trialIndices(self.trialCount+1)).coherence = ...
                  min(100, max(0, qpQuery(self.quest)));
            end
            
            % ---- Set reference coherence to current threshold and set reference RT
            %
            self.settings.coherences  = self.getCoherencesFromQuest(self.settings.coherencesFromQuest);
            self.settings.referenceRT = nanmedian([self.trialData.RT]);
         end
      end
      
      %% Check for choice
      %
      % Save choice/RT information and set up feedback for the dots task
      function nextState = checkForChoice(self, events, eventTag)
         
         % ---- Check for event
         %
         eventName = self.reader.theObject.readEvent(events, self, eventTag);
         
         % Nothing... keep checking
         if isempty(eventName)
            nextState = [];
            return
         end
         
         % ---- Good choice!
         %
         % Override completedTrial flag
         self.completedTrial = true;
         
         % Jump to next state when done
         nextState = 'blank';
         
         % Get current task/trial
         trial = self.getTrial();
         
         % Save the choice
         trial.choice = double(strcmp(eventName, 'choseRight'));
         
         % Mark as correct/error
         trial.correct = double( ...
            (trial.choice==0 && trial.direction==180) || ...
            (trial.choice==1 && trial.direction==0));
         
         % Compute/save RT, wrt dotsOn for RT, dotsOff for non-RT
         if self.isRT
            trial.RT = trial.choice - trial.dotsOn;
         else
            trial.RT = trial.choice - trial.dotsOff;
         end
         
         % ---- Re-save the trial
         %
         self.setTrial(trial);
         
         % ---- Possibly show smiley face
         if trial.correct == 1 && self.timing.showSmileyFace > 0
            self.helpers.stimulusEnsemble.draw({3, [1 2 4]});
         end
      end
      
      %% Show feedback
      %
      function showFeedback(self)
         
         % Get current task/trial
         trial = self.getTrial();

         %  Check for RT feedback
         RTstr = {};
         if self.name(1) == 'S'
            
            % Check current RT relative to the reference value
            if isa(self.settings.referenceRT, 'topsTreeNodeTaskRTDots')
               RTRefValue = self.settings.referenceRT.settings.referenceRT;
            else
               RTRefValue = self.settings.referenceRT;
            end
            
            if isfinite(RTRefValue)
               if trial.RT <= RTRefValue
                  RTstr = {', in time'};
               else
                  RTstr = {', try to decide faster'};
               end
            end
         end
         
         % Set up feedback based on outcome
         if trial.correct == 1
            feedbackArgs = {cat(2, 'Correct', RTstr{:}), ...
               self.settings.correctPlayableIndices, ...
               self.settings.correctImageIndex};
         elseif trial.correct == 0
            feedbackArgs = {cat(2, 'Error', RTstr{:}), ...
               self.settings.errorPlayableIndices, ...
               self.settings.errorImageIndex};
         else
            feedbackArgs = {'No choice'};
         end
         
         % --- Show trial feedback in GUI/text window
         %
         self.statusStrings{2} = ...
            sprintf('Trial %d/%d, dir=%d, coh=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence, feedbackArgs{1}, trial.RT);
         self.updateStatus(2); % just update the second one   
         
         % --- Show trial feedback on the screen
         %
         self.helpers.feedback.showFeedback(feedbackArgs{:});
      end
                
      %% Get Coherences from Quest
      %
      % coherencesFromQuest is list of proportion correct values
      %  if given, find associated coherences from QUEST Weibull
      %  Parameters are: threshold, slope, guess, lapse
      %
      function cohs = getCoherencesFromQuest(self, coherencesFromQuest)
         
         if nargin < 2 || isempty(coherencesFromQuest)
            coherencesFromQuest = [];
            cohs = nan;
         else
            cohs = nans(size(coherencesFromQuest));
         end

         % Find values from PMF
         psiParamsIndex = qpListMaxArg(self.quest.posterior);
         psiParamsQuest = self.quest.psiParamsDomain(psiParamsIndex,:);
         
         if ~isempty(psiParamsQuest)
            
            if isempty(coherencesFromQuest)
               
               % Just return threshold
               cohs = psiParamsQuest(1,1);
            else
               
               cax = (0:0.1:100);
               predictedProportions =100*qpPFWeibull(cax', ...
                  [psiParamsQuest(1,1) psiParamsQuest(1,2) 0.5 0]);
               
               cohs = nans(size(coherencesFromQuest));
               for ii = 1:length(coherencesFromQuest)
                  Lp = predictedProportions(:,2)>=coherencesFromQuest(ii);
                  if any(Lp)
                     cohs(ii) = cax(find(Lp,1));
                  end
               end
            end
         end
      end
   end
   
   methods (Access = protected)
           
      %% Prepare drawables for this trial
      %
      function prepareDrawables(self)
         
         % ---- Get the current trial and the stimulus ensemble
         % 
         trial    = self.getTrial();
         ensemble = self.helpers.stimulusEnsemble.theObject;
         
         
         % ----- Get target locations
         %
         %  Determined relative to fp location
         fpX = ensemble.getObjectProperty('xCenter', 1);
         fpY = ensemble.getObjectProperty('yCenter', 1);
         td  = self.settings.targetDistance;
            
         % ---- Possibly update all stimulusEnsemble objects if settings
         %        changed
         %
         if self.targetDistance ~= self.settings.targetDistance
            
            % Save current value(s)
            self.targetDistance = self.settings.targetDistance;
            
            %  Now set the target x,y (y is same for smiley, so set it)
            ensemble.setObjectProperty('xCenter', [fpX - td, fpX + td], 2);
            ensemble.setObjectProperty('yCenter', [fpY fpY], [2 3]);
         end
                  
         % ---- Set a new seed base for the dots random-number process
         %
         trial.randSeedBase = randi(999);
         self.setTrial(trial);
        
         % ---- Save the randBase, coherence, and direction to the dots object
         %        in the stimulus ensemble
         %
         ensemble.setObjectProperty('randBase',  trial.randSeedBase, 4);
         ensemble.setObjectProperty('coherence', trial.coherence, 4);
         ensemble.setObjectProperty('direction', trial.direction, 4);
         
         % ---- Possibly update smiley face to location of correct target
         %
         if self.timing.showSmileyFace > 0
            
            % Set x
            ensemble.setObjectProperty('x', ...
               fpX + sign(cosd(trial.direction))*td, 3);
         end
         
         % ---- Prepare to draw dots stimulus
         %
         ensemble.callObjectMethod(@prepareToDrawInWindow);
      end
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)

         % ---- Set RT/deadline
         %
         self.isRT = isempty(self.timing.dotsDuration_ddr);
      end

      %% Initialize StateMachine
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         dnow    = {@drawnow};
         blanks  = {@dotsTheScreen.blankScreen};
         chkuif  = {@getNextEvent, self.helpers.reader.theObject, false, {'holdFixation'}};
         chkuib  = {}; % {@getNextEvent, self.readables.theObject, false, {}}; % {'brokeFixation'}
         chkuic  = {@checkForChoice, self, {'choseLeft' 'choseRight'}, 'choice'};
         showfx  = {@draw, self.helpers.stimulusEnsemble, {{'colors', ...
            [1 1 1], 1}, {'isVisible', true, 1}, {'isVisible', false, [2 3 4]}},  self, 'fixationOn'};
         showt   = {@draw, self.helpers.stimulusEnsemble, {2, []}, self, 'targetOn'};
         showfb  = {@showFeedback, self};
         showdRT = {@draw, self.helpers.stimulusEnsemble, {{'colors', ...
            self.settings.fixationRTDim.*[1 1 1], 1}, {'isVisible', true, 4}}, self, 'dotsOn'};
         showdFX = {@draw,self.helpers.stimulusEnsemble, {4, []}, self, 'dotsOn'};
         hided   = {@draw,self.helpers.stimulusEnsemble, {[], [1 4]}, self, 'dotsOff'};
         pdbr    = {@setNextState, self, 'isRT', 'preDots', 'showDotsRT', 'showDotsFX'};

         % drift correction
         hfdc  = {@reset, self.helpers.reader.theObject, true};
         
         % Activate/deactivate readable events
         sea   = @setEventsActiveFlag;
         gwfxw = {sea, self.helpers.reader.theObject, 'holdFixation'};
         gwfxh = {}; 
         gwts  = {sea, self.helpers.reader.theObject, {'choseLeft', 'choseRight'}, 'holdFixation'};
         
         % ---- Timing variables, read directly from the timing property struct
         %
         t = self.timing;
         
         % ---- Make the state machine. These will be added into the 
         %        stateMachine (in topsTreeNode)
         %
         states = {...
            'name'              'entry'  'input'  'timeout'          'exit'     'next'            ; ...
            'showFixation'      showfx   {}       0                     pdbr    'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   t.fixationTimeout     {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   t.holdFixation        hfdc    'showTargets'     ; ...
            'showTargets'       showt    chkuib   t.preTargets          gwts    'preDots'         ; ...
            'preDots'           {}       {}       0                     {}      ''                ; ...
            'showDotsRT'        showdRT  chkuic   t.dotsTimeout         hided   'blank'           ; ...
            'showDotsFX'        showdFX  {}       t.dotsDuration        hided   'waitForChoiceFX' ; ...
            'waitForChoiceFX'   {}       chkuic   t.choiceTimeout       {}      'blank'           ; ...
            'blank'             {}       {}       0.2                   blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       t.showFeedback        blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0                     blanks  'done'            ; ...
            'done'              dnow     {}       t.interTrialInterval  {}      ''                ; ...
            };
                  
         % ---- Set up ensemble activation list. This determines which
         %        states will correspond to automatic, repeated calls to
         %        the given ensemble methods
         %
         % See topsActivateEnsemblesByState for details.
         activeList = {{ ...
            self.helpers.stimulusEnsemble.theObject, 'draw'; ...
            self.helpers.screenEnsemble.theObject, 'flip'}, ...
            {'preDots' 'showDotsRT' 'showDotsFX'}};
         
         % --- List of children to add to the stateMachineComposite
         %        (the state list above is added automatically)
         %
         compositeChildren = { ...
            self.helpers.stimulusEnsemble.theObject, ...
            self.helpers.screenEnsemble.theObject};
         
         % Call utility to set up the state machine
         self.addStateMachine(states, activeList, compositeChildren);
      end      
   end
   
   methods (Static)

      %% ---- Utility for defining standard configurations
      %
      % name is string:
      %  'Quest' for adaptive threshold procedure
      %  or '<SAT><BIAS>' tag, where:
      %     <SAT> is 'N' for neutral, 'S' for speed, 'A' for accuracy
      %     <BIAS> is 'N' for neutral, 'L' for left more likely, 'R' for
      %     right more likely
      function task = getStandardConfiguration(name, minTrialsPerCondition, varargin)
                  
         % ---- Get the task object, with optional property/value pairs
         %
         task = topsTreeNodeTaskRTDots(name, varargin{:});
         
         % ---- Set min trial count
         %
         if  nargin >= 2 && ~isempty(minTrialsPerCondition)
            task.settings.minTrialsPerCondition = minTrialsPerCondition;
         end
         
         % ---- Instruction settings, by column:
         %  1. tag (first character of name)
         %  2. Text string #1
         %  3. RTFeedback flag
         %
         SATsettings = { ...
            'S' 'Be as FAST as possible.'                 task.settings.referenceRT; ...
            'A' 'Be as ACCURATE as possible.'             nan;...
            'N' 'Be as FAST and ACCURATE as possible.'    nan};
         
         dp = task.settings.directionPriors;
         BIASsettings = { ...
            'L' 'Left is more likely.'                    [max(dp) min(dp)]; ...
            'R' 'Right is more likely.'                   [min(dp) max(dp)]; ...
            'N' 'Both directions are equally likely.'     [50 50]};
         
         % For instructions
         if strcmp(name, 'Quest')
            name = 'NN';
         end
         
         % ---- Set strings, priors based on type
         %
         Lsat  = strcmp(name(1), SATsettings(:,1));
         Lbias = strcmp(name(2), BIASsettings(:,1));
         task.settings.textStrings = {SATsettings{Lsat, 2}, BIASsettings{Lbias, 2}};
         task.settings.referenceRT = SATsettings{Lsat, 3};
         task.setIndependentVariableByName('direction', 'priors', BIASsettings{Lbias, 3});
         
         % ---- Have it loop forever until instructed to stop 
         %
         task.iterations = inf;
      end
   end
end

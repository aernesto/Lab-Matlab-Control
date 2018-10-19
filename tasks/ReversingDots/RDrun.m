% Script to run reversing dots task
function RDrun

DIPSLAY_INDEX = 1;
USE_REMOTE = false;
UI = 'dotsReadableHIDKeyboard';


% Make the top Node
topNode = topsTreeNodeTopNode('dotsReversal');
      
% Use the GUI Error here. Syntax issue?
% topNode.runGUIname = 'eyeGUI';

% Turn off file saving
%I had to add the dataFiles inbetween topNode and
% Filename and create the folders. Not sure what the proper set up is. I'm
% assuming another syntax/argument error on my part
topNode.dataFiles.filename = '/Users/lab/GoldLabPsychophysics/Downloaded/Lab-Matlab-Control-eyeDev/tasks/ReversingDots/Data/Subject1';

% Add the screen and text ensemble
topNode.addDrawables(DIPSLAY_INDEX, USE_REMOTE, false);


% Add the user interface device(s)
topNode.addReadables(UI);

% Get the dots Reveral Task
task = topsTreeNodeTaskReversingDots.getStandardConfiguration('SpecificConfigName', 10);

% Add as child to the maintask. 
topNode.addChild(task);

% Run it!
topNode.run();
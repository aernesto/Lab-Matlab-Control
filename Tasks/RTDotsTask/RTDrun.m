%% RTDrun
%
% RTD = Response-Time Dots
%
% This script is a wrapper than will execute the function that runs the
% moving dots task. Once the task has finished, this script will attempt to
% transfer the data files to a single place
%
% 10/3/17   xd  wrote it

%% ---- Need to clear everything because globals can exist
clear all
clear classes

%% ---- Arguments to RTDconfigure
arguments = { ...
   'taskSpecs',            {'Quest' 40 'SN' 20 'AN' 20}, ...
   'sendTTLs',             false, ...
   'useEyeTracking',       true, ...
   'displayIndex',         1, ... % 0=small, 1=main
   'useRemote',            true, ...
   };

%% ---- Configure experiment
[datatub, maintask] = RTDconfigure(arguments{:});

%% ---- RUN IT
% Moved open/close screen here because we also want to check whether or not
% to calibrate the eye tracker, which requires the screen

% Get the screen ensemble
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};

% Open the screen
screenEnsemble.callObjectMethod(@open);

% Check to calibrate pupil-lab device
ui = datatub{'Control'}{'ui'};
if isa(ui, 'dotsReadableEyePupilLabs')
    
    % Get remote screen rect info
    pl.windowRect = screenEnsemble.getObjectProperty('windowRect');
    
    % This does both internal calibration and mapping to snow-dots
    ui.calibrate();
    
    % Set device time to zero
    ui.setDeviceTime();
end

% Run the task
maintask.run();

% Close the screen
screenEnsemble.callObjectMethod(@close);

%% ---- Save the data
topsDataLog.writeDataFile();


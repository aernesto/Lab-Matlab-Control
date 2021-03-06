function feedback = randomFeedback(dXp)
% generate a string which previews the upcoming task
%
%   This is a hack.  dXtasks probably should hold these strings.  Whatever.
%
%   feedback = randomFeedback(dXp)

% copyright 2006 Benjamin Heasly
%   University of Pennsylvania

global ROOT_STRUCT

if dXp.repeatAllTasks < 0

    feedback = 'All done.';

else

    switch rGet('dXtask', dXp.taski, 'name')

        % discrete random numbers
        case 'RandomNumbers'

            feedback = 'Welcome to Number Zone!';

        case {'RandomContinuous', 'Random_pupil'}

            feedback = 'Grab Your Number Paddle!';

        otherwise

            feedback = 'Get Excited!';
    end
end  
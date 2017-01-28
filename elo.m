function elo(game, players, score, varargin)

% Use this function to log a game. 
%
% It will propmt you to confirm that the entered game is correct when 
% displaying the resulting rating changes, which is convenient if you'd like to 
% check what the rating changes would be of a hypothetical game score.
%
% game       - The type of game played. Allowed options are 'single', 'master'
%              and 'double'
% players    - A cell array of the players in the game. In a master game,
%              write the person not starting at the board last. In a double game, 
%              write team players next to each other.
% score      - A vector of the players score. In a double game, there is only 2
%              scores.
% (optional) - You can add a string describing the date and time of the
%              game, otherwise the current date and time will be logged.


if exist('elo2.mat','file') == 2
    load('elo2.mat')
else
    edata = elostruct();
end


% Create time of game
dt = datestr(datetime('now'));

if (~isempty(varargin))
    dt = varargin{1};
end


edata.enterGame(game, players, score, dt);

save('elo2.mat','edata');









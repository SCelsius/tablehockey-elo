function statlog(game, players, score, varargin)

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


if exist('stats.mat','file') == 2
    load('stats.mat')
else
    stat_system = StatSystem();
end


stat_system.enterGame(game, players, score, varargin{:});
stat_system.writeTxtFile('log.txt')

save('stats.mat','stat_system');









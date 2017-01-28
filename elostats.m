function elostats(stat, varargin)

% This function calculates various statistics from the game log.
% 
% stat - String of the type of statistics wanted.
% varargin - accepts some key-value pairs that can filter the stats.
%
% Available statistics:
%
%   'wins'    - Nr. of wins, win ratio and latest victory.
%   'scoring' - Nr. of points, point ratio and scoring ratio variance.
%   'rating'  - Rating change (inc. avg.), maximum and minumum changes.
%   'records' - Maximum and minimum rating acheived, and winning and losing
%               streaks.
%   'list'    - Display a list of the games.
%
% Available key-value pairs (all combinations are valid):
%
%   'players'  - Only display statistics of these players. Value can be a single
%                string, or a cell array of strings.
%   'gameType' - Only draw statistics from games of a certain type. Value
%                can be a single string or a cell array of strings.
%   'vs'       - Only draw statistics from games where at least one of
%                these players played. Or if the value of 'vsand' is set to
%                true, only games where all these players played are
%                included. Value can be a single string, or a
%                cell array of strings.
%   'vsand'    - Controls how the 'vs' argument is interpreted. Value
%                should be boolean, default is false.
%   'since'    - Only consider games played since the value, which has to
%                be a valid datestr.
%   'until'    - Only consider games played until the value, which has to
%                be a valid datestr.
%   'latest'   - After all other filters have applied, only consider at
%                most the latest n games, where n is the value given.
%
%  
% Examples:
%   See all-time records:
%   >> elostats('records');
%
%   Print scoring statistics of Bob's 5 latest single games against Alice:
%   >> elostats('scoring','gameType','single','latest',5,'players','Bob','vs','Alice')
%
%   List all master games since 1980:
%   >> elostats('list','gameType','master','since','1980-01-01')

if exist('elo2.mat','file') == 2
    load('elo2.mat')
else
    edata = elostruct();
end

edata.stats(stat, varargin{:});
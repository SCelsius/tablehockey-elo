function eloplot(varargin)

% This function can be used to visualize elo ratings.
%
% The function takes any number of string arguments and outputs one figure
% for each argument that denotes a figure type. No argument shows 'bar'.
% Available figure types are:
% 
% 'bar'   - Shows a bar plot of the current elo rating of all players.
% 'game'  - Shows a history of ratings, plotted against games.
% 'time'  - Shows a history of ratings, plotted against time.
% 'norm'  - Requires a player name to follow the figure type. Plots a
%           history of what score players are expected to get in a single
%           game vs. the named player, when the named player reaches 3
%           goals. This is plotted againts game.
% 'normt' - Requires a player name to follow the figure type. Plots a
%           history of what score players are expected to get in a single
%           game vs. the named player, when the named player reaches 3
%           goals. This is plotted againts time.
% 'mast'  - Requires three player names to follow the figure type. Plots a
%           history of the expected outcome of a master game between
%           the players. The last player is assumed to start away from the
%           table. This is plotted against game.
% 'mastt' - Requires three player names to follow the figure type. Plots a
%           history of the expected outcome of a master game between
%           the players. The last player is assumed to start away from the
%           table. This is plotted against time.


if isempty(varargin)
    varargin = {'bar'};
end

if ~iscell(varargin)
    varargin = {varargin};
end

if exist('elo2.mat','file') == 2
    load('elo2.mat')
else
    edata = elostruct();
end

% Find if arguments 'since', 'until' and 'latest' are given
si = find(strcmp(varargin, 'since'),1,'last');
ui = find(strcmp(varargin, 'until'),1,'last');
li = find(strcmp(varargin, 'latest'),1,'last');

optargs = {};
lo = 1;

if ~isempty(si)
    optargs{lo} = 'since';
    optargs{lo+1} = varargin{si+1};
    lo=lo+2;
end
if ~isempty(ui)
    optargs{lo} = 'until';
    optargs{lo+1} = varargin{ui+1};
    lo=lo+2;
end
if ~isempty(li)
    optargs{lo} = 'latest';
    optargs{lo+1} = varargin{li+1};
end



ind = 1;
fig = 1;

while ind <= length(varargin)
    
    switch(varargin{ind})
        
        case 'bar'
            edata.plot('bar', 'fig', fig, optargs{:});
            ind = ind+1;
            fig = fig+1;
            
        case 'game'
            edata.plot('history', 'fig', fig, 'xaxis', 'game', optargs{:});
            ind = ind+1;
            fig = fig+1;
            
        case 'time'
            edata.plot('history', 'fig', fig, 'xaxis', 'time', optargs{:});
            ind = ind+1;
            fig = fig+1;
            
        case 'norm'
            if length(varargin) < ind+1
                error('Plot ''norm'' requires a player name to follow!');
            end
            edata.plot('norm', 'fig', fig, 'player', varargin{ind+1}, 'xaxis', 'game', optargs{:});
            ind = ind+2;
            fig = fig+1;
            
        case 'normt'
            if length(varargin) < ind+1
                error('Plot ''normt'' requires a player name to follow!');
            end
            edata.plot('norm', 'fig', fig, 'player', varargin{ind+1}, 'xaxis', 'time', optargs{:});
            ind = ind+2;
            fig = fig+1;
            
        case 'mast'
            if length(varargin) < ind+3
                error('Plot ''mast'' requires three player names to follow!');
            end
            edata.plot('master', 'fig', fig, 'players', varargin(ind+1:ind+3), 'xaxis', 'game', optargs{:});
            ind = ind+4;
            fig = fig+1;
            
            
        case 'mastt'
            if length(varargin) < ind+3
                error('Plot ''mastt'' requires three player names to follow!');
            end
            edata.plot('master', 'fig', fig, 'players', varargin(ind+1:ind+3), 'xaxis', 'time', optargs{:});
            ind = ind+4;
            fig = fig+1;
            
        case {'since','until','latest'}
            ind = ind+2;
            
            
        otherwise 
            warning('Unknonw plot ''%s'', ignoring...', varargin{ind});
            ind = ind+1;
    end   
end

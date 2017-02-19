function statplot(plot, varargin)

% This function is able to visualize some data from a StatSystem, the type
% of data that is visualized is chosen by the 'plot' argument. 
% Each plot type can further take some name-value arguments that configures
% the plot in different ways.
%
% Available plot types are:
% 
% 'bar'/'rating'   - Shows a bar plot of the current ratings of players.
%                        Supports options: 'players', 'fig', 'ratingSystem' 
% 'hist'/'history' - Shows a history of ratings.
%                        Supports options: 'players', 'fig', 'ratingSystem'
%                                          'since', 'until', 'latest', 'xaxis'
%
%
% List of configurations:
%
% 'players'      - Specifies which players (names) that should be plotted.
% 'fig'          - Sets the figure number of the plot.
% 'ratingSystem' - Selects which rating system (name) to visualize.
% 'since'        - Only use data from a selected point in time (string).
% 'until'        - Only use data up to a selected point in time (string).
% 'latest'       - Only use data from at most latest (number) games.
% 'xaxis'        - Set type of xaxis, valid values are
%                  'game', 'game_nr'/'nr'/'game_id'/'id' and 'time'.



if exist('stats.mat','file') == 2
    load('stats.mat')
else
    stat_system = StatSystem();
end



switch(lower(plot))
    case {'history','hist'}
        plotHistory(stat_system, varargin{:});
    case {'bar','rating'}
        plotRating(stat_system, varargin{:});
        
    otherwise
        error('Unsupported plot: ''%s''!', plot);
end



end








function plotRating(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'fig', 1);
addParameter(p, 'ratingSystem', 'total');

[~, ids, rating_system] = processArguments(stat_system, p, varargin);

ids = ids(:);
rating = stat_system.getRatingsOfSystem(rating_system, ids);

if all(isnan(rating))
    fprintf('No ratings!');
    return;
end

ids(isnan(rating)) = [];
rating(isnan(rating)) = [];

[rating, srt] = sort(rating);
ids = ids(srt);
leg = cell(length(ids),1);
txt = cell(length(ids),1);
for i=1:length(ids)
    leg{i} = stat_system.getNameOfId(ids(i));
    txt{i} = sprintf('%u', round(rating(i)));
end

figure(p.Results.fig);
clf;
bar(rating);
set(gca, 'xticklabel', leg);
text(1:length(rating), rating, txt, 'HorizontalAlignment','center','VerticalAlignment','bottom');
yd = max(rating)-min(rating);
axis([0 length(rating)+1 min(rating)-0.125*yd max(rating)+0.125*yd]);
title(sprintf('Rating of system ''%s''', rating_system));
ylabel('Rating');

end


function plotHistory(stat_system, varargin)

p = inputParser;
addParameter(p, 'latest', 0);
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'since', '2000-01-01 00:00:00');
addParameter(p, 'until', '3000-01-01 00:00:00');
addParameter(p, 'fig', 1);
addParameter(p, 'xaxis', 'game');
addParameter(p, 'ratingSystem', 'total');


[ginds, ids, rating_system] = processArguments(stat_system, p, varargin);

[history, ginds] = stat_system.getHistoryOfSystem(rating_system, ids, min(ginds), max(ginds));

if isempty(ginds)
    fprintf('No history!\n');
    return;
end

switch (lower(p.Results.xaxis))
    case 'game'
        xaxis = 1:length(ginds);
        xaxis_label = 'Game';
    case {'game_nr','gamenr','nr','number','game_id','gameid','id'}
        xaxis = ginds;
        xaxis_label = 'Game ID';
    case 'time'
        xaxis = stat_system.game_log.getGameData(@(g) g.time, ginds);
        xaxis = [xaxis{:}];
        xaxis_label = 'Time';
    otherwise
        error('No xaxis type ''%s''!', p.Results.xaxis);
end

[~, srt] = sort(history(:,end));
figure(p.Results.fig);
clf;
hold on;
title(sprintf('History of rating system ''%s''', rating_system));
leg = {};
for i=numel(ids):-1:1
    id = ids(srt(i));
    data = history(srt(i),:);
    
    if ~isnan(data(end))
        plot(xaxis, data, 'color', getColorFromId(id));
        leg{length(leg)+1} = stat_system.getNameOfId(id);
    end
end
xlabel(xaxis_label);
ylabel('Rating');
legend(leg,'location','bestOutside');
end











function [ginds, ids, rating_system] = processArguments(stat_system, p, args, varargin)

parse(p, args{:});

ginds = 1:stat_system.game_log.getNumberOfGames();
if ~isempty(varargin)
    ginds = stat_system.game_log.filterGameIndsOnFunc(@(g) varargin{1}(p.Results, g), ginds);
end


if isfield(p.Results,'players')
    ids = stat_system.getPlayerIds(p.Results.players);
else
    ids = stat_system.player_ids;
end

if isfield(p.Results,'gameType')
    ginds = stat_system.game_log.filterGameIndsOnGameTypes(p.Results.gameType, ginds);
    if ~any(strcmp(p.UsingDefaults, 'gameType'))
    end
end

if isfield(p.Results,'vs')
    pl_ids = stat_system.getPlayerIds(p.Results.vs);
    if ~isfield(p.Results,'vsand') || ~p.Results.vsand
        ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAny(pl_ids, ginds);
    else
        ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAll(pl_ids, ginds);
    end
    
end

if isfield(p.Results,'since')
    if isfield(p.Results,'until')
        ginds = stat_system.game_log.filterGameIndsOnTime(p.Results.since, p.Results.until, ginds);
    else
        ginds = stat_system.game_log.filterGameIndsOnTime(p.Results.since, '5000-01-01', ginds);
    end
elseif isfield(p.Results,'until')
    ginds = stat_system.game_log.filterGameIndsOnTime('1000-01-01', p.Results.until, ginds);
end

if isfield(p.Results,'latest') && p.Results.latest > 0 && length(ginds) > p.Results.latest
    ginds = ginds(end-p.Results.latest+1:end);
end



if isempty(ginds)
    ids = [];
    rating_system = {};
    return;
end

if isfield(p.Results,'ratingSystem')
    rating_system = p.Results.ratingSystem;
else
    rating_system = {};
end

end


function color = getColorFromId(id)

colmap = [0.000, 0.447, 0.741;
    0.850, 0.325, 0.098;
    0.929, 0.694, 0.125;
    0.494, 0.184, 0.556;
    0.466, 0.674, 0.188;
    0.301, 0.745, 0.933;
    0.635, 0.078, 0.184;
    0.213, 0.537, 0.430;
    0.870, 0.910, 0.430;
    0.960, 0.350, 0.974;];
nrcol = size(colmap,1);

color = colmap(mod(id-1,nrcol)+1,:);
end



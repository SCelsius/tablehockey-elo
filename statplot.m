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
% 'all'/'distall'  - Plots the distribution of game results, not taking
%                    into account which player scored what.
%                        Supports options: 'fig', 'since', 'until', 'latest',
%                                          'gameType', 'vs', 'vsand', 'filter'
% 'dist'           - Plots the distribution of game results of a specific
%                    game setup. This argument is required to be followed
%                    by a game type and a cell array of player names.
%                        Supports options: 'fig', 'since', 'until', 'latest'
%                                          'filter'
% 'week'/'weeks'   - Plots the rating gained/lost during the last week
%                    (monday-sunday).
%                        Supports options: 'players', 'fig', 'ratingSystem'
%                                          'until', 'xaxis'
% 'month'/'months' - Plots the rating gained/lost during the last calendar
%                    month.
%                        Supports options: 'players', 'fig', 'ratingSystem'
%                                          'until', 'xaxis'
% 'year'/'years'   - Plots the rating gained/lost during the last calendar
%                    year.
%                        Supports options: 'players', 'fig', 'ratingSystem'
%                                          'until', 'xaxis'
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
%                  'game', 'game_nr'/'nr'/'game_id'/'id', 'day/'days', 
%                  'week'/'weeks', 'month'/'months' and 'time'.
% 'gameType'     - Only draw statistics from games of a certain type. Value
%                  can be a single string or a cell array of strings.
% 'vs'           - Only draw statistics from games where at least one of
%                  these players played. Or if the value of 'vsand' is set to
%                  true, only games where all these players played are
%                  included. Value can be a single string, or a
%                  cell array of strings.
% 'vsand'        - Controls how the 'vs' argument is interpreted. Value
%                  should be boolean, default is false.
% 'filter'       - A function handle that further can filter which games to
%                  collect statistics from. The filter function is applied
%                  after all other options above, just before 'latest'. 
%                  The function should take one argument (let's call it 'g') 
%                  and produce a boolean output. 'g' is a structure that 
%                  contains the following game data:
%                  g.type         - the type of the game (string).
%                  g.player_ids   - a matrix of the player ids of the game,
%                                   one row for each team and one column for
%                                   each player of the team. Note that team
%                                   members id's could appear in any order in
%                                   the row.
%                  g.player_names - a cell matrix of the players' names, such
%                                   that the id of player g.player_names{i,j}
%                                   is g.player_ids(i,j).
%                  g.time         - a datetime object representing the end
%                                   time of the game.
%                  g.score        - a vector containing the teams' scores, in
%                                   the order the teams appear in the id
%                                   matrix.
%                  g.win          - an indicator vector that is 1 for the
%                                   team that won the game (if any), 0 elsewhere.
%                  g.tie          - an indicator vector that is 1 for each
%                                   team that tied the game (if any), 0 elsewhere.
%
%
% Examples:
%   Plot the current ratings of the default rating system ('total') as bars:
%   >> statplot('bar')
%
%   Plot the history of rating system 'single', for Alice and Bob, since
%   2018, on week resolution:
%   >> statplot('hist','ratingSystem','single','players',{'Alice','Bob'},...
%               'since','2018-01-01','xaxis','week')
%   
%   Plot the distribution of all single games during 2018 in which both
%   players scored at least once:
%   >> statplot('distall','gameType','single','since','2018-01-01',...
%               'until','2018-12-31','filter',@(g) min(g.score) > 0)
%
%   Plot the distribution of results the 20 last master games between
%   Alice, Bob and Ceasar:
%   >> statplot('dist','master',{'Alice';'Bob';'Ceasar'},'latest',20)
%
%   Plot the gained rating of system 'individual' during the current week
%   in figure 64, with respect to game id:
%   >> statplot('week','ratingSystem','individual','fig',64,'xaxis','id')
%
%   Plot the gained rating of the default system ('total') during February
%   2018, with time on the horizontal axis:
%   >> statplot('month','until','2018-02-28','time')
%
%
%
% Lastly, available plots again: 'bar', 'hist', 'distall', 'dist', 'week',
%                                'month', 'year'

if length(varargin) > 1 && strcmp(varargin{1}, 'system')
    stat_system = varargin{2};
    varargin = varargin(3:end);
elseif exist('stats.mat','file') == 2
    load('stats.mat')
else
    stat_system = StatSystem();
end



switch(lower(plot))
    case {'history','hist'}
        plotHistory(stat_system, varargin{:});
    case {'bar','rating'}
        plotRating(stat_system, varargin{:});
    case {'all','distall'}
        plotAllResultDist(stat_system, varargin{:});
    case {'dist'}
        plotSetupResultDist(stat_system, varargin{:});
    case {'week','weeks'}
        plotWeek(stat_system, varargin{:});
    case {'month','months'}
        plotMonth(stat_system, varargin{:});
    case {'year','years'}
        plotYear(stat_system, varargin{:});
        
    otherwise
        error('Unsupported plot: ''%s''!', plot);
end



end



function plotYear(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'fig', 1);
addParameter(p, 'ratingSystem', 'total');
addParameter(p, 'xaxis', 'game');
addParameter(p, 'until', '3000-01-01');

[ginds, ids, rating_system] = processArguments(stat_system, p, varargin);

ids = ids(:);

[history, ginds] = stat_system.getHistoryOfSystem(rating_system, ids, 1, max(ginds));
starts = stat_system.getStartRatingsOfSystem(rating_system, ids);

if isempty(ginds)
    fprintf('No history!\n');
    return;
end


this_year = year(datetime(stat_system.game_log.getTimeStrOfGame(ginds(end))));
first = length(ginds)-1;

while first > 0 && year(datetime(stat_system.game_log.getTimeStrOfGame(ginds(first)))) == this_year
    first = first-1;
end

init = zeros(length(ids),1);

for i=1:length(ids)
    if first < 1 || isnan(history(i,first))
        init(i) = starts(i);
    else
        init(i) = history(i,first);
    end
end

data = [init, history(:,first+1:end)] - kron(ones(1,length(ginds)-first+1), init);

if first > 0
    ginds = ginds(first:end);
else
    ginds = [0, ginds(first+1:end)];
end

[xaxis, xaxis_label, data, x_ticklabel] = createXAxis(p.Results.xaxis, ginds, data, stat_system);

srt = getDataSort(data);
figure(p.Results.fig);
clf;
hold on;
title(sprintf('%u of rating system ''%s''', this_year, rating_system));
leg = {};
for i=numel(ids):-1:1
    id = ids(srt(i));
    row = data(srt(i),:);
    
    if any(~isnan(row))
        plot(xaxis, row, 'color', getColorFromId(id));
        leg{length(leg)+1} = stat_system.getNameOfId(id);
    end
end
xlabel(xaxis_label);
ylabel('Rating');
l=legend(leg,'location','bestOutside');
set(l,'fontSize',16)
if ~isempty(x_ticklabel)
    set(gca,'xtick',xaxis);
    set(gca,'xticklabel',x_ticklabel,'TickLabelInterpreter','latex');
end
end





function plotMonth(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'fig', 1);
addParameter(p, 'ratingSystem', 'total');
addParameter(p, 'xaxis', 'game');
addParameter(p, 'until', '3000-01-01');

[ginds, ids, rating_system] = processArguments(stat_system, p, varargin);

ids = ids(:);

[history, ginds] = stat_system.getHistoryOfSystem(rating_system, ids, 1, max(ginds));
starts = stat_system.getStartRatingsOfSystem(rating_system, ids);

if isempty(ginds)
    fprintf('No history!\n');
    return;
end


this_year = year(datetime(stat_system.game_log.getTimeStrOfGame(ginds(end))));
this_month = month(datetime(stat_system.game_log.getTimeStrOfGame(ginds(end))));

first = length(ginds)-1;

while first > 0 && year(datetime(stat_system.game_log.getTimeStrOfGame(ginds(first)))) == this_year && ...
        month(datetime(stat_system.game_log.getTimeStrOfGame(ginds(first)))) == this_month
    first = first-1;
end

init = zeros(length(ids),1);

for i=1:length(ids)
    if first < 1 || isnan(history(i,first))
        init(i) = starts(i);
    else
        init(i) = history(i,first);
    end
end

data = [init, history(:,first+1:end)] - kron(ones(1,length(ginds)-first+1), init);

if first > 0
    ginds = ginds(first:end);
else
    ginds = [0, ginds(first+1:end)];
end

[xaxis, xaxis_label, data, x_ticklabel] = createXAxis(p.Results.xaxis, ginds, data, stat_system);

srt = getDataSort(data);
figure(p.Results.fig);
clf;
hold on;
title(sprintf('%s %u of rating system ''%s''', char(month(datetime(2000, this_month, 1),'name')), this_year, rating_system));
leg = {};
for i=numel(ids):-1:1
    id = ids(srt(i));
    row = data(srt(i),:);
    
    if any(~isnan(row))
        plot(xaxis, row, 'color', getColorFromId(id));
        leg{length(leg)+1} = stat_system.getNameOfId(id);
    end
end
xlabel(xaxis_label);
ylabel('Rating');
l=legend(leg,'location','bestOutside');
set(l,'fontSize',16)
if ~isempty(x_ticklabel)
    set(gca,'xtick',xaxis);
    set(gca,'xticklabel',x_ticklabel,'TickLabelInterpreter','latex');
end
end








function plotWeek(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'fig', 1);
addParameter(p, 'ratingSystem', 'total');
addParameter(p, 'xaxis', 'game');
addParameter(p, 'until', '3000-01-01');

[ginds, ids, rating_system] = processArguments(stat_system, p, varargin);

ids = ids(:);

[history, ginds] = stat_system.getHistoryOfSystem(rating_system, ids, 1, max(ginds));
starts = stat_system.getStartRatingsOfSystem(rating_system, ids);

if isempty(ginds)
    fprintf('No history!\n');
    return;
end


this_year = year(datetime(stat_system.game_log.getTimeStrOfGame(ginds(end))));
this_week = week(datetime(stat_system.game_log.getTimeStrOfGame(ginds(end))));

first = length(ginds)-1;

while first > 0 && year(datetime(stat_system.game_log.getTimeStrOfGame(ginds(first)))) == this_year && ...
        week(datetime(stat_system.game_log.getTimeStrOfGame(ginds(first)))) == this_week
    first = first-1;
end

init = zeros(length(ids),1);

for i=1:length(ids)
    if first < 1 || isnan(history(i,first))
        init(i) = starts(i);
    else
        init(i) = history(i,first);
    end
end

data = [init, history(:,first+1:end)] - kron(ones(1,length(ginds)-first+1), init);

if first > 0
    ginds = ginds(first:end);
else
    ginds = [0, ginds(first+1:end)];
end

[xaxis, xaxis_label, data, x_ticklabel] = createXAxis(p.Results.xaxis, ginds, data, stat_system);

srt = getDataSort(data);
figure(p.Results.fig);
clf;
hold on;
title(sprintf('Week %u %u of rating system ''%s''', this_week, this_year, rating_system));
leg = {};
for i=numel(ids):-1:1
    id = ids(srt(i));
    row = data(srt(i),:);
    
    if any(~isnan(row))
        plot(xaxis, row, 'color', getColorFromId(id));
        leg{length(leg)+1} = stat_system.getNameOfId(id);
    end
end
xlabel(xaxis_label);
ylabel('Rating');
l=legend(leg,'location','bestOutside');
set(l,'fontSize',16)
if ~isempty(x_ticklabel)
    set(gca,'xtick',xaxis);
    set(gca,'xticklabel',x_ticklabel,'TickLabelInterpreter','latex');
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







function plotAllResultDist(stat_system, varargin)

p = inputParser;
addParameter(p, 'latest', 0);
addParameter(p, 'since', '2000-01-01 00:00:00');
addParameter(p, 'until', '3000-01-01 00:00:00');
addParameter(p, 'fig', 1);
addParameter(p, 'gameType', {'single','master','double','double master'});
addParameter(p, 'vs', stat_system.player_names);
addParameter(p, 'vsand', false);
addParameter(p, 'filter', @(g) true);


[ginds] = processArguments(stat_system, p, varargin);

reskeys = {};
count = [];

for gs=1:length(ginds)
    g = ginds(gs);
    
    sc = sort(stat_system.game_log.getScoreOfGame(g),'descend');
    
    ind = 1;
    while ind <= length(reskeys)
        if length(reskeys{ind}) == length(sc) && sum(abs(reskeys{ind}-sc)) == 0
            break;
        end
        ind = ind+1;
    end
    
    if ind > length(reskeys)
        reskeys{ind} = sc; %#ok<AGROW>
        count = [count, 1]; %#ok<AGROW>
    else
        count(ind) = count(ind)+1; %#ok<AGROW>
    end
end

% Sort reskeys
org_reskeys = reskeys;
n = 1;
order = zeros(1,length(reskeys));

for i=1:length(reskeys)
    msc = zeros(1,20);
    ind = 0;
    for j=1:length(reskeys)
        if length(reskeys{j}) < length(msc)
            msc = reskeys{j};
            ind = j;
        elseif length(reskeys{j}) == length(msc)
            for k=1:length(msc)
                if reskeys{j}(k) > msc(k)
                    msc = reskeys{j};
                    ind = j;
                    break;
                elseif msc(k) > reskeys{j}(k)
                    break;
                end
            end
        end
    end
    order(n) = ind;
    n = n+1;
    reskeys{ind} = zeros(1,20); %#ok<AGROW>
end

reskeys = org_reskeys(order);
count = count(order);

leg = cell(1,length(reskeys));
for i=1:length(reskeys)
    leg{i} = strjoin(arrayfun(@(x) sprintf('%u',x), reskeys{i}, 'UniformOutput', false),'-');
end

figure(p.Results.fig);
clf;
bar(count./length(ginds).*100);
set(gca, 'xticklabel', leg);
set(gca, 'xtick', 1:length(leg));
ylabel('Percent');
xlabel('Result');
title('Result distribution');

end







function plotSetupResultDist(stat_system, varargin)

p = inputParser;
addRequired(p, 'gameType', @ischar);
addRequired(p, 'players');
addParameter(p, 'latest', 0);
addParameter(p, 'since', '2000-01-01 00:00:00');
addParameter(p, 'until', '3000-01-01 00:00:00');
addParameter(p, 'fig', 1);
addParameter(p, 'filter', @(g) true);


[ginds, ids] = processArguments(stat_system, p, varargin, @checkGameSetup);

reskeys = {};
count = [];

for gs=1:length(ginds)
    g = ginds(gs);
    
    sc = zeros(size(stat_system.game_log.getScoreOfGame(g)));
    for i=1:length(sc)
        sc(i) = stat_system.game_log.getPointsForId(ids(i,1),g);
    end
    
    ind = 1;
    while ind <= length(reskeys)
        if length(reskeys{ind}) == length(sc) && sum(abs(reskeys{ind}-sc)) == 0
            break;
        end
        ind = ind+1;
    end
    
    if ind > length(reskeys)
        reskeys{ind} = sc; %#ok<AGROW>
        count = [count, 1]; %#ok<AGROW>
    else
        count(ind) = count(ind)+1; %#ok<AGROW>
    end
end

% Sort reskeys
nsc = length(sc);
org_reskeys = reskeys;
n = 1;
order = zeros(1,length(reskeys));
switches = zeros(1,nsc-1);
swind = 1;
lastw = 0;

for i=1:length(reskeys)
    for j=1:length(reskeys)
        if sum(order==j) == 0
            ind = j;
            msc = reskeys{j};
            break;
        end
    end
    
    for j=ind+1:length(reskeys)
        % All zeros indicate already sorted
        if sum(reskeys{j}) == 0
            continue;
        end
        
        [mm,wm] = max(msc);
        [mn,wn] = max(reskeys{j});
        
        tm = sum(msc==mm);
        tn = sum(reskeys{j}==mn);
        
        jbefore = false;
        
        % Number of tied players (less means sorted before)
        if tn < tm
            jbefore = true;
        elseif tn == tm
            % Smallest win index is sorted before
            if any(find(msc==mm) > find(reskeys{j}==mn))
                jbefore = true;
            elseif all(find(msc==mm) == find(reskeys{j}==mn))
                ri = wn+1:length(msc);
                li = 1:wn-1;
                
                pm = mm*length(li) - sum(msc(li)) - (mm*length(ri) - sum(msc(ri)));
                pn = mn*length(li) - sum(reskeys{j}(li)) - (mn*length(ri) - sum(reskeys{j}(ri)));
                
                % Margins to right and left pull right/left
                if pn < pm
                    jbefore = true;
                elseif pm == pn
                    
                    % Determine if look at winners score should pull
                    % right/left
                    if wn <= (nsc+1)/2
                        % Larger win value pulls left
                        if mn > mm
                            jbefore = true;
                        elseif mn == mm
                            wmn = mn - sum(reskeys{j}(li)) - sum(reskeys{j}(ri));
                            wmm = mm - sum(msc(li)) - sum(msc(ri));
                            % Less conceded points pulls left
                            if wmn > wmm
                                jbefore = true;
                            elseif wmn == wmm
                                pm = 0; pn = 0;
                                
                                if ~isempty(ri)
                                    pm = pm + dot(msc(ri)-mm,1:length(ri));
                                    pn = pn + dot(reskeys{j}(ri)-mn,1:length(ri));
                                end
                                if ~isempty(li)
                                    pm = pm - dot(msc(li)-mm,length(li):-1:1);
                                    pn = pn - dot(reskeys{j}(li)-mn,length(li):-1:1);
                                end
                                
                                % Pull strength of conceded points
                                if pn < pm
                                    jbefore = true;
                                end
                            end
                        end
                    else
                        % Larger win value pulls right
                        if mn < mm
                            jbefore = true;
                        elseif mn == mm
                            wmn = mn - sum(reskeys{j}(li)) - sum(reskeys{j}(ri));
                            wmm = mm - sum(msc(li)) - sum(msc(ri));
                            % Less conceded points pulls right
                            if wmn < wmm
                                jbefore = true;
                            elseif wmn == wmm
                                pm = 0; pn = 0;
                                
                                if ~isempty(ri)
                                    pm = pm + dot(msc(ri)-mm,1:length(ri));
                                    pn = pn + dot(reskeys{j}(ri)-mn,1:length(ri));
                                end
                                if ~isempty(li)
                                    pm = pm - dot(msc(li)-mm,length(li):-1:1);
                                    pn = pn - dot(reskeys{j}(li)-mn,length(li):-1:1);
                                end
                                % Pull strength of conceded points
                                if pn < pm
                                    jbefore = true;
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if jbefore
            msc = reskeys{j};
            ind = j;
        end
    end
    
    
    
    if i==1
        lastw = find(reskeys{ind} == max(reskeys{ind}));
    else
        wn = find(reskeys{ind} == max(reskeys{ind}));
        if length(wn) ~= length(lastw) || ~all(wn == lastw)
            
            if length(wn) > 1 && length(lastw) == 1
                switches(swind) = -i;
            else
                switches(swind) = i;
            end
            lastw = wn;
            swind = swind+1;
        end
    end
    
    order(n) = ind;
    n = n+1;
    reskeys{ind} = zeros(1,nsc); %#ok<AGROW>
end

reskeys = org_reskeys(order);
count = count(order);

leg = cell(1,length(reskeys));
for i=1:length(reskeys)
    leg{i} = strjoin(arrayfun(@(x) sprintf('%u',x), reskeys{i}, 'UniformOutput', false),'-');
end

plstr = '';
for i=1:size(ids, 1)
    if i > 1
        plstr = sprintf('%s vs. ', plstr);
    end
    for j=1:size(ids, 2)
        if j == size(ids, 2) && j > 1
            plstr = sprintf('%s and ', plstr);
        elseif j > 1
            plstr = sprintf('%s, ', plstr);
        end
        plstr = sprintf('%s%s', plstr, p.Results.players{i,j});
    end
end

figure(p.Results.fig);
clf;
bar(count./length(ginds).*100);
set(gca, 'xticklabel', leg);
set(gca, 'xtick', 1:length(leg));
ylabel('Percent');
xlabel('Result');
title(sprintf('Result distribution of %s',plstr));
yl = ylim;
hold on;
for i=1:length(switches)
    if switches(i) > 0
        plot([switches(i)-0.5, switches(i)-0.5], yl, '--r');
    elseif switches(i) < 0
        plot([-switches(i)-0.5, -switches(i)-0.5], yl, '-k');
    end
end



    function ok = checkGameSetup(r, g)
        if any(size(r.players) ~= size(g.player_names))
            ok = false;
        else
            
            rids = sort(stat_system.getPlayerIds(r.players),2);
            gids = sort(g.player_ids.ids,2);
            
            while ~isempty(gids)
                found = false;
                for ci=1:size(gids,1)
                    if all(gids(ci,:) == rids(1,:))
                        rids(1,:) = [];
                        gids(ci,:) = [];
                        found = true;
                        break;
                    end
                end
                if ~found
                    ok = false;
                    return;
                end
            end
            ok = true;
        end
    end

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

[xaxis, xaxis_label, history, x_ticklabel] = createXAxis(p.Results.xaxis, ginds, history, stat_system);

srt = getDataSort(history);
figure(p.Results.fig);
clf;
hold on;
title(sprintf('History of rating system ''%s''', rating_system));
leg = {};
for i=numel(ids):-1:1
    id = ids(srt(i));
    data = history(srt(i),:);
    lastnonnan = find(~isnan(data),1,'last');
    
    if ~isempty(lastnonnan)
        plot(xaxis, data, 'color', getColorFromId(id), 'markerIndices', lastnonnan,...
            'marker', 'o', 'markerFaceColor', getColorFromId(id), 'markerSize', 4);
        %plot(xaxis(lastnonnan), data(lastnonnan), 'color', getColorFromId(id), 'marker', 'o', 'markerfacecolor', getColorFromId(id), 'markersize', 5); 
        leg{length(leg)+1} = stat_system.getNameOfId(id);
    end
end
xlabel(xaxis_label);
ylabel('Rating');
l=legend(leg,'location','bestOutside');
set(l,'fontSize',16)
if ~isempty(x_ticklabel)
    set(gca,'xtick',xaxis);
    set(gca,'xticklabel',x_ticklabel,'TickLabelInterpreter','latex');
end
end







function [xaxis, xaxis_label, data, x_ticklabel] = createXAxis(type, ginds, data, stat_system)

x_ticklabel = {};

switch (lower(type))
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
    case {'day','days'}
        ind = 1;
        cols = zeros(1,length(ginds));
        if ginds(1) == 0
            dts = stat_system.game_log.getGameData(@(g) datetime(year(g.time), month(g.time), day(g.time)), ginds(2:end));
            dts = [dts{1}-caldays(1), dts{:}];
        else
            dts = stat_system.game_log.getGameData(@(g) datetime(year(g.time), month(g.time), day(g.time)), ginds);
            dts = [dts{:}];
        end
        for i=1:length(ginds)-1
            if year(dts(i)) ~= year(dts(i+1)) ||...
                    month(dts(i)) ~= month(dts(i+1)) ||...
                day(dts(i)) ~= day(dts(i+1))
                cols(ind) = i;
                ind = ind+1;
            end
        end
        cols(ind) = length(ginds);
        
        xaxis = dts(cols(1:ind));
        xaxis_label = 'Day';
        data = data(:,cols(1:ind));
    case {'week','weeks'}
        ind = 1;
        cols = zeros(1,length(ginds));
        if ginds(1) == 0
            dts = stat_system.game_log.getGameData(@(g) datetime(year(g.time), month(g.time), day(g.time)), ginds(2:end));
            dts = [dts{1}-calweeks(1), dts{:}];
        else
            dts = stat_system.game_log.getGameData(@(g) datetime(year(g.time), month(g.time), day(g.time)), ginds);
            dts = [dts{:}];
        end
        for i=1:length(ginds)-1
            if year(dts(i)) ~= year(dts(i+1)) ||...
                    week(dts(i)) ~= week(dts(i+1))
                cols(ind) = i;
                ind = ind+1;
            end
        end
        cols(ind) = length(ginds);
        
        xaxis = 1:ind;
        xaxis_label = 'Week';
        data = data(:,cols(1:ind));
        x_ticklabel = cell(1,length(xaxis));
        for i=1:length(xaxis)
            if year(dts(cols(1))) == year(dts(cols(ind)))
                x_ticklabel{i} = sprintf('%u', week(dts(cols(i))));
            else
                if i==1 || year(dts(cols(i))) ~= year(dts(cols(i-1)))
                    x_ticklabel{i} = sprintf('\\begin{tabular}{c}%u\\\\(%u)\\end{tabular}',week(dts(cols(i))), year(dts(cols(i))));
                else
                    x_ticklabel{i} = sprintf('%u', week(dts(cols(i))));
                end
            end
        end
    case {'month','months'}
        ind = 1;
        cols = zeros(1,length(ginds));
        if ginds(1) == 0
            dts = stat_system.game_log.getGameData(@(g) datetime(year(g.time), month(g.time), day(g.time)), ginds(2:end));
            dts = [dts{1}-calmonths(1), dts{:}];
        else
            dts = stat_system.game_log.getGameData(@(g) datetime(year(g.time), month(g.time), day(g.time)), ginds);
            dts = [dts{:}];
        end
        for i=1:length(ginds)-1
            if year(dts(i)) ~= year(dts(i+1)) ||...
                    month(dts(i)) ~= month(dts(i+1))
                cols(ind) = i;
                ind = ind+1;
            end
        end
        cols(ind) = length(ginds);
        
        xaxis = 1:ind;
        xaxis_label = 'Month';
        data = data(:,cols(1:ind));
        x_ticklabel = cell(1,length(xaxis));
        for i=1:length(xaxis)
            if year(dts(cols(1))) == year(dts(cols(ind)))
                x_ticklabel{i} = char(month(dts(cols(i)),'name'));
            else
                x_ticklabel{i} = sprintf('%s %u', char(month(dts(cols(i)),'name')), year(dts(cols(i))));
            end
        end
    otherwise
        error('No xaxis type ''%s''!', p.Results.xaxis);
end

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

if isfield(p.Results,'filter')
    ginds = stat_system.game_log.filterGameIndsOnFunc(p.Results.filter, ginds);
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


function srt = getDataSort(data)

    tosort = NaN(size(data,1),1);
    for i=1:size(data,1)
        ind = find(~isnan(data(i,:)),1,'last');
        if ~isempty(ind)
            tosort(i) = data(i,ind);
        end
    end
    
    [~,srt] = sort(tosort);

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
    0.960, 0.350, 0.974;
    0.100, 0.100, 0.100;
    0.600, 0.600, 0.600];
nrcol = size(colmap,1);

color = colmap(mod(id-1,nrcol)+1,:);
end



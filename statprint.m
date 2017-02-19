function statprint(stat, varargin)

% This function calculates various statistics from the game log.
% 
% stat - String of the type of statistics wanted.
% varargin - accepts some key-value pairs that can filter the stats.
%
% Available statistics, {Valid key-value arguments}:
%
%   'wins'     - Nr. of wins, win ratio, first and latest victory,
%                {'players', 'gameType', 'latest', 'vs', 'vsand', 'since',
%                'until', 'filter'}.
%   'score'    - Nr. of points, point ratio and scoring ratio instability,
%                {'players', 'gameType', 'latest', 'vs', 'vsand', 'since',
%                'until', 'filter'}.
%   'rating'   - Rating change (inc. avg.), maximum and minumum changes and
%                absolute rating values, {'players', 'latest', 'since',
%                'until', 'ratingSystem', 'filter'}.
%   'streak'   - Streaks of wins/losses/ties/scoring/not scoring, 
%                {'players', 'gameType', 'latest', 'vs', 'vsand', 'since',
%                'until', 'filter'}.
%   'current'  - The currently ongoing streaks, {'players', 'gameType',
%                'vs', 'vsand', 'filter'}.
%   'list'     - Display a list of the games, {'gameType', 'latest',
%                'vs', 'vsand', 'since', 'until', 'filter'}.
%   'marathon' - An aggregated game score of a specific setup, this argument
%                is required to be followed by a game type and a player
%                setup, {'latest', 'since', 'until', 'filter'}.
%   'table'    - An aggregated game score of players or teams, this
%                argument is required to be followed by a game type and a
%                player list (one row for each team to be calculated),
%                {'latest', 'since', 'until', 'vs', 'vsand', 'filter'}.
%
%
% List of key-value arguments:
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
%   'ratingSystem' - The name of the rating system to get rating data from.
%                    Value should be a string, default is 'total'.
%   'filter'   - A function handle that further can filter which games to
%                collect statistics from. The filter function is applied
%                after all other options above, just before 'latest'. 
%                The function should take one argument (let's call it 'g') 
%                and produce a boolean output. 'g' is a structure that 
%                contains the following game data:
%                g.type         - the type of the game (string).
%                g.player_ids   - a matrix of the player ids of the game,
%                                 one row for each team and one column for
%                                 each player of the team. Note that team
%                                 members id's could appear in any order in
%                                 the row.
%                g.player_names - a cell matrix of the players' names, such
%                                 that the id of player g.player_names{i,j}
%                                 is g.player_ids(i,j).
%                g.time         - a datetime object representing the end
%                                 time of the game.
%                g.score        - a vector containing the teams' scores, in
%                                 the order the teams appear in the id
%                                 matrix.
%                g.win          - an indicator vector that is 1 for the
%                                 team that won the game (if any), 0 elsewhere.
%                g.tie          - an indicator vector that is 1 for each
%                                 team that tied the game (if any), 0 elsewhere.
%
%  
% Examples:
%   See longest all-time streaks for everyone:
%   >> statprint('streak');
%
%   Print Bob's scoring statistics of his 5 latest single games against Alice:
%   >> statprint('scoring','gameType','single','latest',5,'players','Bob','vs',{'Alice','Bob'})
%
%   List all master games since 1980:
%   >> statprint('list','gameType','master','since','1980-01-01')
%
%   Get the total aggregated results in double games where Alice and Bob
%   has played against Ceasar and David, in 2018:
%   >> statprint('marathon','double',{'Alice','Bob';'Ceasar','David'},...
%                'since','2018-01-01','until','2018-12-31')
%
%   Show Alice's win statistics in single games where she has scored at least once
%   >> statprint('wins','gameType','single','players','Alice','filter',...
%                @(g) sum(strcmp(g.player_names, 'Alice') .* g.score) > 0)

if exist('stats.mat','file') == 2
    load('stats.mat')
else
    stat_system = StatSystem();
end



% Simple dispatch to different stat functions
switch (lower(stat))
    
    case {'wins','win'}
        printWinStats(stat_system, varargin{:});
    case {'scoring','score'}
        printScoringStats(stat_system, varargin{:});
    case {'list','games','game'}
        printList(stat_system, varargin{:});
    case {'streak','streaks'}
        printStreakStats(stat_system, varargin{:});
    case {'current streaks','current streak','currentstreaks','currenstreak','current'}
        printOngoingStreakStats(stat_system, varargin{:});
    case {'marathon','mara','maraton'}
        printMarathonStats(stat_system, varargin{:});
    case {'rating','ratings'}
        printRatingStats(stat_system, varargin{:});
    case {'marathon table','maraton table','mara table','marathontable','maratontable','maratable','table'}
        printMarathonTableStats(stat_system, varargin{:});
        
    otherwise
        error('Unsupported statistics: ''%s''!', stat);
end

end


function printWinStats(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'gameType', stat_system.game_log.valid_game_types);
addParameter(p, 'latest', 0);
addParameter(p, 'vs', stat_system.player_names);
addParameter(p, 'vsand', false);
addParameter(p, 'since', '1000-01-01');
addParameter(p, 'until', '5000-01-01');
addParameter(p, 'filter', @(g) true);

[hdr, ginds, ids] = processArguments(stat_system, p, varargin);

fprintf(hdr);

for i=1:numel(ids)
    id = ids(i);
    
    nr_wins = stat_system.game_log.getNumberOfWinsForId(id, ginds);
    nr_ties = stat_system.game_log.getNumberOfTiesForId(id, ginds);
    nr_played = stat_system.game_log.getNumberOfGamesForId(id, ginds);
    win_inds = stat_system.game_log.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.win)), ginds);
    
    if nr_played == 0
        continue;
    end
    
    g_str = sprintf('%u games', nr_played);
    if nr_played == 1
        g_str = '1 game';
    end
    fprintf('--- %s (%s):\n', stat_system.getNameOfId(id), g_str);
    
    tie_str = '';
    if nr_ties == 1
        tie_str = ', and has tied 1 game';
    elseif nr_ties > 1
        tie_str = sprintf(', and has tied %u games', nr_ties);
    end
    fprintf('Has won %u games (%u%%)%s.\n',...
        nr_wins, round(nr_wins/nr_played*100), tie_str);
    if nr_wins > 0
        fprintf('First win was %s\nLast win was %s\n',...
            stat_system.game_log.getDescriptionOfGame(ginds(find(win_inds == 1,1,'first')),...
            'with %3$s in a %1$s game on %4$s played by: %2$s.'),...
            stat_system.game_log.getDescriptionOfGame(ginds(find(win_inds == 1,1,'last')),...
            'with %3$s in a %1$s game on %4$s played by: %2$s.'));
    end
    fprintf('\n');
end
end


function printScoringStats(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'gameType', stat_system.game_log.valid_game_types);
addParameter(p, 'latest', 0);
addParameter(p, 'vs', stat_system.player_names);
addParameter(p, 'vsand', false);
addParameter(p, 'since', '1000-01-01');
addParameter(p, 'until', '5000-01-01');
addParameter(p, 'filter', @(g) true);

[hdr, ginds, ids] = processArguments(stat_system, p, varargin);

fprintf(hdr);

for i=1:numel(ids)
    id = ids(i);
    
    nr_points = stat_system.game_log.getPointsForId(id, ginds);
    nr_total = stat_system.game_log.getTotalGamePointsForId(id, ginds);
    ratios = stat_system.game_log.getPointRatiosForId(id, stat_system.game_log.filterGameIndsOnPlayerIdsAny(id, ginds));
    nr_played = length(ratios);
    
    if nr_played == 0
        continue;
    end
    
    g_str = sprintf('%u games', nr_played);
    if nr_played == 1
        g_str = '1 game';
    end
    fprintf('--- %s (%s):\n', stat_system.getNameOfId(id), g_str);
    fprintf('Has scored %u of %u points (%u%%).\nCoefficient of variation of scoring ratio is %u%%.\n\n',...
        nr_points,...
        nr_total,...
        round(nr_points/nr_total*100),...
        round(sqrt(var(ratios))/mean(ratios)*100));
    
end

end


function printList(stat_system, varargin)

p = inputParser;
addParameter(p, 'gameType', stat_system.game_log.valid_game_types);
addParameter(p, 'latest', 0);
addParameter(p, 'vs', stat_system.player_names);
addParameter(p, 'vsand', false);
addParameter(p, 'since', '1000-01-01');
addParameter(p, 'until', '5000-01-01');
addParameter(p, 'filter', @(g) true);

[hdr, ginds] = processArguments(stat_system, p, varargin);
fprintf(hdr);

for i=1:length(ginds)
    fprintf('%3u: %s\n', ginds(i), stat_system.game_log.getDescriptionOfGame(ginds(i)));
end
fprintf('\n');

end




function printStreakStats(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'gameType', stat_system.game_log.valid_game_types);
addParameter(p, 'latest', 0);
addParameter(p, 'vs', stat_system.player_names);
addParameter(p, 'vsand', false);
addParameter(p, 'since', '1000-01-01');
addParameter(p, 'until', '5000-01-01');
addParameter(p, 'filter', @(g) true);

[hdr, ginds, ids] = processArguments(stat_system, p, varargin);
fprintf(hdr);


for i=1:numel(ids)
    id = ids(i);
    
    this_ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAny(id, ginds);
    nr_played = length(this_ginds);
    if nr_played < 2
        continue;
    end
    
    win_inds = stat_system.game_log.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.win)), this_ginds);
    tie_inds = stat_system.game_log.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.tie)), this_ginds);
    score_inds = stat_system.game_log.getGameValues(@(ga) min(1,max(any(ga.player_ids == id,2).*(ga.score))), this_ginds);
    nonscore_inds = 1 - score_inds;
    lose_inds = 1 - min(1, win_inds + tie_inds);
    nonwin_inds = 1 - win_inds;
    nonlose_inds = 1 - lose_inds;
    
    find_win = find(win_inds);
    find_tie = find(tie_inds);
    find_lose = find(lose_inds);
    find_nonwin = find(nonwin_inds);
    find_nonlose = find(nonlose_inds);
    find_score = find(score_inds);
    find_nonscore = find(nonscore_inds);
    
    cs_win = [0 cumsum(diff(find_win)~=1)];
    cs_tie = [0 cumsum(diff(find_tie)~=1)];
    cs_lose = [0 cumsum(diff(find_lose)~=1)];
    cs_nonwin = [0 cumsum(diff(find_nonwin)~=1)];
    cs_nonlose = [0 cumsum(diff(find_nonlose)~=1)];
    cs_score = [0 cumsum(diff(find_score)~=1)];
    cs_nonscore = [0 cumsum(diff(find_nonscore)~=1)];
    
    [win_id, win_streak] = mode(-cs_win);
    [tie_id, tie_streak] = mode(-cs_tie);
    [lose_id, lose_streak] = mode(-cs_lose);
    [nonwin_id, nonwin_streak] = mode(-cs_nonwin);
    [nonlose_id, nonlose_streak] = mode(-cs_nonlose);
    [score_id, score_streak] = mode(-cs_score);
    [nonscore_id, nonscore_streak] = mode(-cs_nonscore);
    
    g_str = sprintf('%u games', nr_played);
    fprintf('--- %s (%s):\n', stat_system.getNameOfId(id), g_str);
    
    if win_streak > 1
        start = find_win(find(cs_win == -win_id,1,'first'));
        stop = start + win_streak - 1;
        if stop == length(this_ginds)
            o_str = ' (ongoing)';
        else
            o_str = '';
        end
        fprintf('Winning streak:     %u games between %s and %s%s.\n',...
            win_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)),...
            stat_system.game_log.getTimeStrOfGame(this_ginds(stop)),...
            o_str);
    end
    
    if nonlose_streak > 1 && nonlose_streak > win_streak
        start = find_nonlose(find(cs_nonlose == -nonlose_id,1,'first'));
        stop = start + nonlose_streak - 1;
        if stop == length(this_ginds)
            o_str = ' (ongoing)';
        else
            o_str = '';
        end
        fprintf('Non-losing streak:  %u games between %s and %s%s.\n',...
            nonlose_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)),...
            stat_system.game_log.getTimeStrOfGame(this_ginds(stop)),...
            o_str);
    end
    
    if tie_streak > 1
        start = find_tie(find(cs_tie == -tie_id,1,'first'));
        stop = start + tie_streak - 1;
        if stop == length(this_ginds)
            o_str = ' (ongoing)';
        else
            o_str = '';
        end
        fprintf('Tie streak:         %u games between %s and %s%s.\n',...
            tie_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)),...
            stat_system.game_log.getTimeStrOfGame(this_ginds(stop)),...
            o_str);
    end
    
    if nonwin_streak > 1 && nonwin_streak > lose_streak
        start = find_nonwin(find(cs_nonwin == -nonwin_id,1,'first'));
        stop = start + nonwin_streak - 1;
        if stop == length(this_ginds)
            o_str = ' (ongoing)';
        else
            o_str = '';
        end
        fprintf('Non-winning streak: %u games between %s and %s%s.\n',...
            nonwin_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)),...
            stat_system.game_log.getTimeStrOfGame(this_ginds(stop)),...
            o_str);
    end
    
    if lose_streak > 1
        start = find_lose(find(cs_lose == -lose_id,1,'first'));
        stop = start + lose_streak - 1;
        if stop == length(this_ginds)
            o_str = ' (ongoing)';
        else
            o_str = '';
        end
        fprintf('Losing streak:      %u games between %s and %s%s.\n',...
            lose_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)),...
            stat_system.game_log.getTimeStrOfGame(this_ginds(stop)),...
            o_str);
    end
    
    if score_streak > 1
        start = find_score(find(cs_score == -score_id,1,'first'));
        stop = start + score_streak - 1;
        if stop == length(this_ginds)
            o_str = ' (ongoing)';
        else
            o_str = '';
        end
        fprintf('Scoring streak:     %u games between %s and %s%s.\n',...
            score_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)),...
            stat_system.game_log.getTimeStrOfGame(this_ginds(stop)),...
            o_str);
    end
    
    if nonscore_streak > 1
        start = find_nonscore(find(cs_nonscore == -nonscore_id,1,'first'));
        stop = start + nonscore_streak - 1;
        if stop == length(this_ginds)
            o_str = ' (ongoing)';
        else
            o_str = '';
        end
        fprintf('Non-scoring streak: %u games between %s and %s%s.\n',...
            nonscore_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)),...
            stat_system.game_log.getTimeStrOfGame(this_ginds(stop)),...
            o_str);
    end
    
    fprintf('\n');
end
end


function printOngoingStreakStats(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'gameType', stat_system.game_log.valid_game_types);
addParameter(p, 'vs', stat_system.player_names);
addParameter(p, 'vsand', false);
addParameter(p, 'filter', @(g) true);

[hdr, ginds, ids] = processArguments(stat_system, p, varargin);
fprintf(hdr);


for i=1:numel(ids)
    id = ids(i);
    
    this_ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAny(id, ginds);
    nr_played = length(this_ginds);
    if nr_played < 2
        continue;
    end
    
    win_inds = stat_system.game_log.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.win)), this_ginds);
    tie_inds = stat_system.game_log.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.tie)), this_ginds);
    score_inds = stat_system.game_log.getGameValues(@(ga) min(1,max(any(ga.player_ids == id,2).*(ga.score))), this_ginds);
    nonscore_inds = 1 - score_inds;
    lose_inds = 1 - min(1, win_inds + tie_inds);
    nonwin_inds = 1 - win_inds;
    nonlose_inds = 1 - lose_inds;
    
    find_win = find(win_inds == 0,1,'last');
    find_tie = find(tie_inds == 0,1,'last');
    find_lose = find(lose_inds == 0,1,'last');
    find_nonwin = find(nonwin_inds == 0,1,'last');
    find_nonlose = find(nonlose_inds == 0,1,'last');
    find_score = find(score_inds == 0,1,'last');
    find_nonscore = find(nonscore_inds == 0,1,'last');
    
    if isempty(find_win)
        find_win = 0;
    end
    if isempty(find_tie)
        find_tie = 0;
    end
    if isempty(find_lose)
        find_lose = 0;
    end
    if isempty(find_nonwin)
        find_nonwin = 0;
    end
    if isempty(find_nonlose)
        find_nonlose = 0;
    end
    if isempty(find_score)
        find_score = 0;
    end
    if isempty(find_nonscore)
        find_nonscore = 0;
    end
    
    win_streak = length(win_inds) - find_win;
    tie_streak = length(tie_inds) - find_tie;
    lose_streak = length(lose_inds) - find_lose;
    nonwin_streak = length(nonwin_inds) - find_nonwin;
    nonlose_streak = length(nonlose_inds) - find_nonlose;
    score_streak = length(score_inds) - find_score;
    nonscore_streak = length(nonscore_inds) - find_nonscore;
    
    g_str = sprintf('%u games', nr_played);
    fprintf('--- %s (%s):\n', stat_system.getNameOfId(id), g_str);
    
    if win_streak > 1
        start = find_win + 1;
        fprintf('Winning streak:     %u games, starting at %s.\n',...
            win_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)));
    end
    
    if nonlose_streak > 1 && nonlose_streak > win_streak
        start = find_nonlose + 1;
        fprintf('Non-losing streak:  %u games, starting at %s.\n',...
            nonlose_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)));
    end
    
    if tie_streak > 1
        start = find_tie + 1;
        fprintf('Tie streak:         %u games, starting at %s.\n',...
            tie_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)));
    end
    
    if nonwin_streak > 1 && nonwin_streak > lose_streak
        start = find_nonwin + 1;
        fprintf('Non-winning streak: %u games, starting at %s.\n',...
            nonwin_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)));
    end
    
    if lose_streak > 1
        start = find_lose + 1;
        fprintf('Losing streak:      %u games, starting at %s.\n',...
            lose_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)));
    end
    
    if score_streak > 1
        start = find_score + 1;
        fprintf('Scoring streak:     %u games, starting at %s.\n',...
            score_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)));
    end
    
    if nonscore_streak > 1
        start = find_nonscore + 1;
        fprintf('Non-scoring streak: %u games, starting at %s.\n',...
            nonscore_streak,...
            stat_system.game_log.getTimeStrOfGame(this_ginds(start)));
    end
    
    fprintf('\n');
end
end


function printMarathonStats(stat_system, varargin)

p = inputParser;
addRequired(p, 'gameType', @ischar);
addRequired(p, 'players');
addParameter(p, 'since', '1000-01-01');
addParameter(p, 'latest', 0);
addParameter(p, 'until', '5000-01-01');
addParameter(p, 'filter', @(g) true);

[hdr, ginds, ids] = processArguments(stat_system, p, varargin, @checkGameSetup);
fprintf(hdr);

if ~isempty(ginds)
    
    scores = zeros(1,size(ids,1));
    wins = zeros(1,size(ids,1));
    ties = zeros(1,size(ids,1));
    
    for i=1:length(scores)
        scores(i) = stat_system.game_log.getPointsForId(ids(i,1), ginds);
        wins(i) = stat_system.game_log.getNumberOfWinsForId(ids(i,1), ginds);
        ties(i) = stat_system.game_log.getNumberOfTiesForId(ids(i,1), ginds);
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
    fprintf('--- Marathon data of %s:\n', plstr);
    fprintf('Total score: %s\n', strjoin(arrayfun(@(x) sprintf('%u',x), scores, 'UniformOutput', false),'-'));
    if max(wins) > 0
        fprintf('Total wins: %s\n', strjoin(arrayfun(@(x) sprintf('%u',x), wins, 'UniformOutput', false),'-'));
    end
    if max(ties) > 0
        if length(ties) > 2
            fprintf('Total ties: %s\n', strjoin(arrayfun(@(x) sprintf('%u',x), ties, 'UniformOutput', false),'-'));
        else
            fprintf('Total ties: %u\n', ties(1));
        end
    end
    fprintf('\n');
end





    function ok = checkGameSetup(r, g)
        if any(size(r.players) ~= size(g.player_names))
            ok = false;
        else
            
            rids = sort(stat_system.getPlayerIds(r.players),2);
            gids = sort(g.player_ids,2);
            
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




function printMarathonTableStats(stat_system, varargin)

p = inputParser;
addRequired(p, 'gameType', @ischar);
addRequired(p, 'players');
addParameter(p, 'since', '1000-01-01');
addParameter(p, 'latest', 0);
addParameter(p, 'until', '5000-01-01');
addParameter(p, 'vs', stat_system.player_names);
addParameter(p, 'vsand', false);
addParameter(p, 'filter', @(g) true);

[hdr, ginds, ids] = processArguments(stat_system, p, varargin);
fprintf(hdr);

for i=1:size(ids,1)
    
    id = sort(ids(i,:));
    
    this_ginds = stat_system.game_log.filterGameIndsOnFunc(@(g) size(g.player_ids,2) == length(id) &&...
        any(all(sort(g.player_ids,2) == kron(id,ones(size(g.player_ids,1),1)),2)), ginds);
    
    nr_played = length(this_ginds);
    if nr_played == 0
        continue;
    end
    
    points = stat_system.game_log.getPointsForId(id(1), this_ginds);
    total_points = stat_system.game_log.getTotalGamePointsForId(id(1), this_ginds);
    wins = stat_system.game_log.getNumberOfWinsForId(id(1), this_ginds);
    ties = stat_system.game_log.getNumberOfTiesForId(id(1), this_ginds);
    ratios = stat_system.game_log.getPointRatiosForId(id(1), this_ginds);
    
    plstr = '';
    for j=1:length(id)
        if j == length(id) && j > 1
            plstr = sprintf('%s and ', plstr);
        elseif j > 1
            plstr = sprintf('%s, ', plstr);
        end
        plstr = sprintf('%s%s', plstr, stat_system.getNameOfId(id(j)));
    end
    
    
    g_str = sprintf('%u games', nr_played);
    if nr_played == 1
        g_str = '1 game';
    end
    fprintf('--- %s (%s):\nHas scored %u of %u points (%u%%).\nCoefficient of variation of scoring ratio is %u%%.\nHas won %u games (%u%%).\n',...
        plstr,...
        g_str,...
        points,...
        total_points,...
        round(points/total_points*100),...
        round(sqrt(var(ratios))/mean(ratios)*100),...
        wins,...
        round(wins/nr_played*100));
    
    if ties == 1        
        fprintf('Has tied 1 game.\n');
    elseif ties > 1
        fprintf('\nHas tied %u games.', ties);
    end
    fprintf('\n');
end



end


function printRatingStats(stat_system, varargin)

p = inputParser;
addParameter(p, 'players', stat_system.player_names);
addParameter(p, 'latest', 0);
addParameter(p, 'since', '1000-01-01');
addParameter(p, 'until', '5000-01-01');
addParameter(p, 'ratingSystem', 'total', @ischar);
addParameter(p, 'filter', @(g) true);

[hdr, ginds, ids, rating_system] = processArguments(stat_system, p, varargin);
fprintf(hdr);

if ~isempty(ginds)
    
    for i=1:numel(ids)
        id = ids(i);
        
        
        
        [hist, hist_ginds] = stat_system.getHistoryOfSystem(rating_system, id, 1, max(ginds));
        start_ind = find(hist_ginds >= min(ginds),1,'first');
        
        if isempty(start_ind)
            continue;
        end
        
        bfhist = hist(1:start_ind-1);
        bfhist_ginds = hist_ginds(1:start_ind-1);
        hist = hist(start_ind:end);
        hist_ginds = hist_ginds(start_ind:end);
        
        played_ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAny(id, hist_ginds);
        bfplayed_ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAny(id, bfhist_ginds);
        
        [~, ~, inds] = intersect(played_ginds, hist_ginds);
        hist = hist(inds);
        [~, ~, inds] = intersect(bfplayed_ginds, bfhist_ginds);
        bfhist = bfhist(inds);
        
        nr_played = length(hist);
        if nr_played == 0
            continue;
        end
        
        maxhist = max(hist);
        minhist = min(hist);
        
        if isempty(bfhist)
            hist = [1200, hist]; %#ok<AGROW>
        else
            hist = [bfhist(end), hist]; %#ok<AGROW>
        end
        
        
        diffs = diff(hist);
        
        [max_diff, max_ind] = max(diffs);
        [min_diff, min_ind] = min(diffs);
        
        totdiff = hist(end) - hist(1);
        
        g_str = sprintf('%u games', nr_played);
        if nr_played == 1
            g_str = '1 game';
        end
        fprintf('--- %s (%s):\n', stat_system.getNameOfId(id), g_str);
        
        sign = '+';
        if totdiff < 0
            sign = '-';
        end
        fprintf('Maximum rating: %u\nMinimum rating: %u\nHas changed %s%.2f (average %s%.2f per game).\nMaximum change was %.2f caused by a %s.\nMinimum change was %.2f caused by a %s.\n\n',...
            round(maxhist),...
            round(minhist),...
            sign,...
            abs(totdiff),...
            sign,...
            abs(totdiff/nr_played),...
            max_diff,...
            stat_system.game_log.getDescriptionOfGame(played_ginds(max_ind)),...
            min_diff,...
            stat_system.game_log.getDescriptionOfGame(played_ginds(min_ind)));
    end
    
end

end











function [hdr, ginds, ids, rating_system] = processArguments(stat_system, p, args, varargin)

parse(p, args{:});

ginds = 1:stat_system.game_log.getNumberOfGames();
if ~isempty(varargin)
    ginds = stat_system.game_log.filterGameIndsOnFunc(@(g) varargin{1}(p.Results, g), ginds);
end

hdr = '\n------------ Displaying stats of ';


if isfield(p.Results,'players')
    ids = stat_system.getPlayerIds(p.Results.players);
else
    ids = stat_system.player_ids;
end

games_str = 'all';
if isfield(p.Results,'gameType')
    ginds = stat_system.game_log.filterGameIndsOnGameTypes(p.Results.gameType, ginds);
    if ~any(strcmp(p.UsingDefaults, 'gameType'))
        if ischar(p.Results.gameType)
            games_str = p.Results.gameType;
        elseif length(p.Results.gameType) == 1
            games_str = p.Results.gameType{1};
        else
            games_str = sprintf('%s and %s', strjoin(p.Results.gameType(1:end-1),', '), p.Results.gameType{end});
        end
    end
end
hdr = sprintf('%s%s games', hdr, games_str);

pl_str = '';
if isfield(p.Results,'vs')
    pl_ids = stat_system.getPlayerIds(p.Results.vs);
    if ~isfield(p.Results,'vsand') || ~p.Results.vsand
        ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAny(pl_ids, ginds);
        join_str = 'or';
    else
        ginds = stat_system.game_log.filterGameIndsOnPlayerIdsAll(pl_ids, ginds);
        join_str = 'and';
    end
    
    if ~any(strcmp(p.UsingDefaults, 'vs'))
        if ischar(p.Results.vs)
            pl_str = p.Results.vs;
        elseif length(p.Results.vs) == 1
            pl_str = p.Results.vs{1};
        else
            pl_str = sprintf('%s %s %s', strjoin(p.Results.vs(1:end-1),', '), join_str, p.Results.vs{end});
        end
        pl_str = sprintf(', played by %s,', pl_str);
    end
end
hdr = sprintf('%s%s', hdr, pl_str);

if isfield(p.Results,'since')
    if isfield(p.Results,'until')
        ginds = stat_system.game_log.filterGameIndsOnTime(p.Results.since, p.Results.until, ginds);
    else
        ginds = stat_system.game_log.filterGameIndsOnTime(p.Results.since, '5000-01-01', ginds);
    end
elseif isfield(p.Results,'until')
    ginds = stat_system.game_log.filterGameIndsOnTime('1000-01-01', p.Results.until, ginds);
end

filt_str = '';
if isfield(p.Results,'filter')
    ginds_filtered = stat_system.game_log.filterGameIndsOnFunc(p.Results.filter, ginds);
    if length(ginds_filtered) < length(ginds)
        filt_str = '(filtered) ';
        ginds = ginds_filtered;
    end
end

if isfield(p.Results,'latest') && p.Results.latest > 0 && length(ginds) > p.Results.latest
    ginds = ginds(end-p.Results.latest+1:end);
end

g_str = 'games';
if length(ginds) == 1
    g_str = 'game';
end

if isempty(ginds)
    hdr = '\n------------ No games ------------\n\n';
    ids = [];
    rating_system = {};
    return;
end

hdr = sprintf('%s between %s and %s (%u %s) %s------------\n\n', hdr,...
    stat_system.game_log.getTimeStrOfGame(ginds(1)),...
    stat_system.game_log.getTimeStrOfGame(ginds(end)),...
    length(ginds), g_str, filt_str);

if isfield(p.Results,'ratingSystem')
    rating_system = p.Results.ratingSystem;
else
    rating_system = {};
end

end

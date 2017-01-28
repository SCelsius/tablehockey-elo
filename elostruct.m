classdef elostruct < handle
    
    properties (GetAccess = public, SetAccess = private)
        
        % Game log
        game_players = {};
        game_type = {};
        history = {};
        name = {};
        rating = {};
        scores = {};
        time = [];
        
        % Rating parameters
        K = 10;
       
    end
    
    
    
    
    
    
    
    
    
    
    % Public methods for editing the game log.
    methods
        
        function enterGame(obj, type, players, score, timestr)
            % Use this function to enter a game into the log
            
            % If game is back in history, it needs special handling
            dt = datetime(timestr);
            if ~isempty(obj.time) && dt < obj.time(end)
                obj.enterHistoricalGame(type, players, score, dt);
                return;
            end
            
            % Create save point to roll back to if this update should not
            % be saved in the end.
            savepoint = obj.createSavePoint();
            
            obj.addGameLast(type, players, score, dt, 1);            
            
            % Propmt user to see if this was correct
            if ~obj.prompt('Accept these changes?');
                obj.restoreSavePoint(savepoint);
            end
        end
        
        
        function replayAllGames(obj)
            % This function recalculates all ratings from the beginning.
            % This is useful if a rating parameter has changed.
            
            % Create roll-back point
            savepoint = obj.createSavePoint();
            
            % Clear log
            obj.game_players = {};
            obj.game_type = {};
            obj.history = {};
            obj.scores = {};
            obj.name = {};
            obj.rating = {};
            obj.time = [];
            
            % Run all games again
            nr_games = length(savepoint.time);
            for i=1:nr_games
                fprintf('Processing game %u of %u.\n', i, nr_games);
                obj.addGameLast(savepoint.game_type{i}, savepoint.game_players{i}, savepoint.scores{i}, savepoint.time(i), 0);
            end
            
            % Print info and prompt to see if correct
            fprintf('New ratings (old ratings):\n');
            for i=1:length(obj.name)
                old_id = find(strcmp(savepoint.name, obj.name{i}));
                if isempty(old_id)
                    fprintf('%s: %u (new)\n', obj.name{i}, round(obj.rating{i}));
                else
                    fprintf('%s: %u (%u)\n', obj.name{i}, round(obj.rating{i}), round(savepoint.rating{old_id}));
                end
            end
            
            if ~obj.prompt('Accept these changes?')
                obj.restoreSavePoint(savepoint);
            end
            
        end
        
        
        function undoGame(obj, game_nr)
            
            if isempty(obj.time)
                fprintf('There are no games to undo!\n');
                return
            end
            
            if game_nr > length(obj.time)
                fprintf('There is no game %u to undo!\n', game_nr);
            elseif game_nr == length(obj.time)
                obj.removeLastGame();
            elseif game_nr > 0
                obj.removeGame(game_nr);
            else
                error('game_nr has to be larger than 0!');
            end
        end
        
        function setRatingChangeParameter(obj, value)
            
            obj.K = value;
            obj.replayAllGames();
            
        end
    end
    
    
    
    
    
    
    
    
    
    
    
    % Public utility methods that uses state of the object.
    methods
        
        function ids = getPlayerIds(obj, names)
            % Get ids of players with names, 0 is returned if player does
            % not exist.
            
            % Make cell if it is a single char array
            if ischar(names)
                names = {names};
            end
            
            ids = zeros(length(names),1);
            for i=1:length(names)
                id = find(strcmp(names{i}, obj.name));
                if ~isempty(id)
                    ids(i) = id;
                end
            end
        end
        
        function diff = getDiffs(obj, type, ratings, score)
            % Get the rating diffs that a game would induce.
            
            switch (type)
                
                case 'single'
                    if(length(ratings) ~= 2 || length(score)  ~= 2)
                        error('Single game comprises 2 players');
                    end
                    ex = obj.expectedSingleScores(ratings, sum(score));
                    if (~xor(isrow(score),iscolumn(ex)))
                        score = score';
                    end
                    
                    diff = obj.K .* (score - ex);
                    
                case 'master'
                    if(length(ratings) ~= 3 || length(score)  ~= 3)
                        error('Master game comprises 3 players');
                    end
                    ex = obj.expectedMasterScores(ratings, sum(score));
                    if (~xor(isrow(score),iscolumn(ex)))
                        score = score';
                    end
                    
                    diff = obj.K .* (score - ex);
                    
                case 'double'
                    if(length(ratings) ~= 4 || length(score)  ~= 2)
                        error('Double game comprises 4 players, 2 scores');
                    end
                    ex = obj.expectedDoubleScores(ratings, sum(score));
                    if (~xor(isrow(score),iscolumn(ex)))
                        score = score';
                    end
                    
                    diff = kron(0.5 .* obj.K .* (score - ex), [1;1]);
                    
                otherwise
                    error('Unknown game type: ''%s''!', type);
            end  
        end
        
        
        function sc = getScoreOfPlayer(obj, game_nr, player)
            % Get a player's score in game nr game_nr
            
            ind = find(strcmp(player, obj.game_players{game_nr}),1);
            
            if isempty(ind)
                sc = -1;
                return;
            end
            
            if strcmp(obj.game_type{game_nr}, 'double')
                ind = floor((ind+1)/2);
            end
            
            sc = obj.scores{game_nr}(ind);
            
        end
        
        
        function srt = getPlayerSorting(obj)
            [~, srt] = sort(cell2mat(obj.rating));
        end
        
        
        function str = gameString(obj, game_nr, varargin)
            % Creates a string describing game nr game_nr,
            % if a format string is given in varargin, that will be used.
            % Format '%1$s game (%4$s) between %2$s: %3$s' is default.
            %
            % 1$ - The game type
            % 2$ - The players of the game
            % 3$ - The result of the game
            % 4$ - The date and time of the game
            
            plstr = '';
            scstr = '';
            
            nr_pl = length(obj.game_players{game_nr});
            for i=1:nr_pl
                if i == 1
                    plstr = strcat(plstr, obj.game_players{game_nr}{i});
                else
                    plstr = strcat(plstr, sprintf(' %s',obj.game_players{game_nr}{i}));
                end
                
                if i == nr_pl-1
                    plstr = strcat(plstr, ' and');
                elseif i < nr_pl-1
                    plstr = strcat(plstr, ',');
                end
            end
            
            
            for i=1:length(obj.scores{game_nr})
                scstr = strcat(scstr, sprintf('%u',obj.scores{game_nr}(i)));
                
                if i < length(obj.scores{game_nr})
                    scstr = strcat(scstr, '-');
                end
            end
            
            if isempty(varargin)
                fmt = '%1$s game (%4$s) between %2$s: %3$s';
            else
                fmt = varargin{1};
            end
            
            str = sprintf(fmt,...
                obj.game_type{game_nr},...
                plstr,...
                scstr,...
                datestr(obj.time(game_nr)));
            
        end
        
        
        
        
        function stats(obj, stat, varargin)
            p = inputParser;
            addParameter(p, 'players', obj.name);
            addParameter(p, 'gameType', {'single','master','double'});
            addParameter(p, 'latest', 0);
            addParameter(p, 'vs', obj.name);
            addParameter(p, 'vsand', false);
            addParameter(p, 'since', '2000-01-01 00:00:00');
            addParameter(p, 'until', '3000-01-01 00:00:00');
            
            parse(p, varargin{:});
            
            ids = obj.getPlayerIds(p.Results.players);
            
            % Filter the games according to parameters
            ginds = 1:length(obj.time);
            ginds = obj.filterGameType(p.Results.gameType, ginds);
            ginds = obj.filterSince(p.Results.since, ginds);
            ginds = obj.filterUntil(p.Results.until, ginds);
            ginds = obj.filterVs(p.Results.vs, p.Results.vsand, ginds);
            
            % Remove games if needed
            if p.Results.latest > 0 && length(ginds) > p.Results.latest
                ginds = ginds(end-p.Results.latest+1:end);
            end
            
            % Exit if no games are left
            if isempty(ginds)
                fprintf('There are no games that fulfill the arguments!\n');
                return;
            end
            
            % Print a message telling what statistics is shown
            prestr = '\n\n----- Displaying stats of';
            if length(p.Results.gameType) == 3
                prestr = strcat(prestr, ' all');
            elseif length(p.Results.gameType) == 2
                prestr = strcat(prestr, sprintf(' %s and %s', p.Results.gameType{1}, p.Results.gameType{2}));
            else
                prestr = strcat(prestr, sprintf(' %s', p.Results.gameType));
            end
            vsstr = '';
            if length(p.Results.vs) < length(obj.name) || (length(obj.name) > 1 && ischar(p.Results.vs))
                if ischar(p.Results.vs)
                    vsstr = sprintf(', played by %s,', p.Results.vs);
                else
                    vsstr = ', played by';
                    for i=1:length(p.Results.vs)
                        if i < length(p.Results.vs) - 1
                            vsstr = strcat(vsstr, sprintf(' %s,', p.Results.vs{i}));
                        elseif i < length(p.Results.vs)
                            oa = 'or';
                            if p.Results.vsand
                                oa = 'and';
                            end
                            vsstr = strcat(vsstr, sprintf(' %s %s', p.Results.vs{i}, oa));
                        else
                            vsstr = strcat(vsstr, sprintf(' %s,', p.Results.vs{i}));
                        end
                    end
                end
            end
            
            prestr = strcat(prestr, sprintf(' games%s since %s (%u games) -----', vsstr, datestr(obj.time(ginds(1))), length(ginds)));
            fprintf(prestr);
            fprintf('\n\n');
            
            
            switch(stat)
                case 'list'
                    obj.list(ginds);
                case 'records'
                    obj.records(ginds, ids);
                case 'wins'
                    obj.wins(ginds, ids);
                case 'scoring'
                    obj.scoring(ginds, ids);
                case 'rating'
                    obj.ratingStat(ginds, ids);
            end
        end
        
        
        function plot(obj, plot, varargin)
            p = inputParser;
            addParameter(p, 'latest', 0);
            addParameter(p, 'players', {});
            addParameter(p, 'player', '');
            addParameter(p, 'since', '2000-01-01 00:00:00');
            addParameter(p, 'until', '3000-01-01 00:00:00');
            addParameter(p, 'fig', 1);
            addParameter(p, 'xaxis', 'game');
            
            parse(p, varargin{:});
            
            % Filter the games according to parameters
            ginds = 1:length(obj.time);
            ginds = obj.filterSince(p.Results.since, ginds);
            ginds = obj.filterUntil(p.Results.until, ginds);
                        
            % Remove games if needed
            if p.Results.latest > 0 && length(ginds) > p.Results.latest
                ginds = ginds(end-p.Results.latest+1:end);
            end
            
            switch(plot)
                case 'bar'
                    obj.bar(p.Results.fig);
                case 'history'
                    obj.historyPlot(p.Results.fig, ginds, p.Results.xaxis);
                case 'norm'
                    id = obj.getPlayerIds(p.Results.player);
                    if id < 1
                        if isempty(p.Results.player)
                            error('Normalized plot requires argument ''player''!');
                        else
                            error('Could not find player ''%s''!', p.Results.player);
                        end
                    end
                    obj.normalizedSinglePlot(p.Results.fig, ginds, p.Results.xaxis, id);
                case 'master'
                    ids = obj.getPlayerIds(p.Results.players);
                    if length(ids) ~= 3
                        if isempty(p.Results.players)
                            error('Master plot requires argument ''players''!');
                        else
                            error('Master plot requires 3 player names!');
                        end
                    end
                    for i=1:3
                        if ids(i) < 1
                            error('Could not find player ''%s''!', p.Results.players{i});
                        end
                    end
                    obj.masterPlot(p.Results.fig, ginds, p.Results.xaxis, ids);
                
                    
                otherwise
                    error('Unknown plot format ''%s''!', plot);
            end 
        end
        
            
    end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % This method block contains private helper methods for adding and
    % removing games. All changes to the game log is made by these methods.
    methods (Access = private, Hidden = true)
        
        function enterHistoricalGame(obj, type, players, score, dt)
            % Create save point to revert back to if needed, and to keep
            % data that will be used
            savepoint = obj.createSavePoint();
            
            % Find how many games in log that are before this one
            nr_before = sum(obj.time <= dt);
            nr_after = length(obj.time) - nr_before;
            
            % Remove everything after the current game in time
            obj.game_players = obj.game_players(1:nr_before);
            obj.game_type = obj.game_type(1:nr_before);
            obj.scores = obj.scores(1:nr_before);
            obj.time = obj.time(1:nr_before);
            keep_ids = [];
            for i=1:length(obj.history)
                obj.history{i} = obj.history{i}(1:nr_before);
                if nr_before > 0
                    obj.rating{i} = obj.history{i}(nr_before);
                else
                    obj.rating{i} = nan;
                end
                if ~isnan(obj.rating{i})
                    keep_ids = [keep_ids, i]; %#ok<AGROW>
                end
            end
            obj.name = obj.name(keep_ids);
            obj.rating = obj.rating(keep_ids);
            obj.history = obj.history(keep_ids);
            
            % Print some info to the user
            fprintf('Entering a historical game...\n');
            fprintf('Processing game 1 of %u.\n', nr_after+1);
            
            % Add the current game
            obj.addGameLast(type, players, score, dt, 0);
            
            % Add all following games
            for i=nr_before+1:nr_before+nr_after
                fprintf('Processing game %u of %u.\n', i-nr_before+1, nr_after+1);
                obj.addGameLast(savepoint.game_type{i}, savepoint.game_players{i}, savepoint.scores{i}, savepoint.time(i), 0);
            end
            
            % Print info to user about the results of the update
            fprintf('New ratings (old ratings):\n');
            for i=1:length(obj.name)
                old_id = find(strcmp(savepoint.name, obj.name{i}));
                if isempty(old_id)
                    fprintf('%s: %u (new)\n', obj.name{i}, round(obj.rating{i}));
                else
                    fprintf('%s: %u (%u)\n', obj.name{i}, round(obj.rating{i}), round(savepoint.rating{old_id}));
                end
            end
            
            if ~obj.prompt('Accept these changes?')
                obj.restoreSavePoint(savepoint);
            end
        end
        
        
        function addGameLast(obj, type, players, score, dt, print_info)
            
            % First check for inactivity up until this game
            indiffs = obj.getInactivityChanges(dt);
            
            % Create new players if needed, and extract playing ids.
            new_names = obj.createNewPlayers(players);
            ids = obj.getPlayerIds(players);
            
            % Extend lenght of indiffs to match #players (might have been
            % added now)
            indiffs = [indiffs, zeros(1,length(obj.name)-length(indiffs))];
            
            % Update ratings to include inactivity
            ratings_after_inact = cell2mat(obj.rating) + indiffs;
            
            diff = obj.getDiffs(type, ratings_after_inact(ids), score);
            
            if print_info
                % Printf info about this update
                for i=1:length(indiffs)
                    if indiffs(i) < 0
                        fprintf('%s concedes %u points due to inactivity.\n', obj.name{i}, -indiffs(i));
                    end
                end
                for i=1:length(new_names)
                    fprintf('New player: %s\n', new_names{i});
                end
                fprintf('New ratings:\n');
                for i=1:length(diff)
                    sign = '+';
                    if (diff(i) < 0)
                        sign = '-';
                    end
                    fprintf('%s: %u (%s%u)\n', obj.name{ids(i)} , round(ratings_after_inact(ids(i))+diff(i)), sign , round(abs(diff(i))) );
                end
            end            
            
            % Update ratings and history
            obj.rating = num2cell(ratings_after_inact);
            for i=1:length(ids)
                obj.rating{ids(i)} = obj.rating{ids(i)} + diff(i);
            end
            
            obj.time = [obj.time; dt];
            
            for i=1:length(obj.history)
                obj.history{i} = [obj.history{i}; obj.rating{i}];
            end
            
            newind = length(obj.time);
            obj.game_type{newind} = type;
            obj.game_players{newind} = players;
            obj.scores{newind} = score;
            
        end
        
        
        function removeGame(obj, game_nr)
            
            if game_nr > length(obj.time)
                error('There are no game %u!', game_nr);
            elseif game_nr == length(obj.time)
                error('To remove last game, removeLastGame() should be used instead!');                
            end
            
            % Create savepoint
            savepoint = obj.createSavePoint();
            
            % Calculate how many games in log that are after this one
            nr_after = length(obj.time) - game_nr;
            
            % Remove everything after and including the current game in time
            obj.game_players = obj.game_players(1:game_nr-1);
            obj.game_type = obj.game_type(1:game_nr-1);
            obj.scores = obj.scores(1:game_nr-1);
            obj.time = obj.time(1:game_nr-1);
            keep_ids = [];
            for i=1:length(obj.history)
                obj.history{i} = obj.history{i}(1:game_nr-1);
                if game_nr > 1
                    obj.rating{i} = obj.history{i}(game_nr-1);
                else
                    obj.rating{i} = nan;
                end
                if ~isnan(obj.rating{i})
                    keep_ids = [keep_ids, i]; %#ok<AGROW>
                end
            end
            obj.name = obj.name(keep_ids);
            obj.rating = obj.rating(keep_ids);
            obj.history = obj.history(keep_ids);
            
            % Print some info to the user
            fprintf('Removing a historical game...\n');
           
            
            % Add all following games
            for i=game_nr+1:game_nr+nr_after
                fprintf('Processing game %u of %u.\n', i-game_nr, nr_after);
                obj.addGameLast(savepoint.game_type{i}, savepoint.game_players{i}, savepoint.scores{i}, savepoint.time(i), 0);
            end
            
            % Print info to user about the results of the update
            fprintf('New ratings (old ratings):\n');
            for i=1:length(obj.name)
                old_id = find(strcmp(savepoint.name, obj.name{i}));
                if isempty(old_id)
                    fprintf('%s: %u (new)\n', obj.name{i}, round(obj.rating{i}));
                else
                    fprintf('%s: %u (%u)\n', obj.name{i}, round(obj.rating{i}), round(savepoint.rating{old_id}));
                end
            end
            
            if ~obj.prompt('Accept these changes?')
                obj.restoreSavePoint(savepoint);
            end
        end
        
        
        function removeLastGame(obj)
            % Create roll-back point
            savepoint = obj.createSavePoint();
            
            nr_games = length(obj.time);
            % Remove last game in list
            obj.time(nr_games) = [];
            obj.game_type = obj.game_type(1:nr_games-1);
            obj.game_players = obj.game_players(1:nr_games-1);
            obj.scores = obj.scores(1:nr_games-1);
            keep_ids = [];            
            
            % Find which players to keep in log (those that had a rating
            % after the now last game.
            for i=1:length(obj.name)
                if nr_games > 1
                    obj.rating{i} = obj.history{i}(nr_games-1);
                else
                    obj.rating{i} = nan;
                end
                obj.history{i}(nr_games) = [];
                if ~isnan(obj.rating{i})
                    keep_ids = [keep_ids, i]; %#ok<AGROW>
                end
            end
            
            obj.rating = obj.rating(keep_ids);
            obj.name = obj.name(keep_ids);
            obj.history = obj.history(keep_ids);
            
            % Print info to user about the results of the update
            fprintf('New ratings (old ratings):\n');
            for i=1:length(obj.name)
                old_id = find(strcmp(savepoint.name, obj.name{i}));
                if isempty(old_id)
                    fprintf('%s: %u (new)\n', obj.name{i}, round(obj.rating{i}));
                else
                    fprintf('%s: %u (%u)\n', obj.name{i}, round(obj.rating{i}), round(savepoint.rating{old_id}));
                end
            end
            
            if ~obj.prompt('Accept these changes?')
                obj.restoreSavePoint(savepoint);
            end
        end
        
        
        
        function diff = getInactivityChanges(obj, ~)
            diff = zeros(1,length(obj.name));
        end
    
        function new_names = createNewPlayers(obj, players)
            new_names = {};
            for i=1:length(players)
                if ~any(strcmp(players{i}, obj.name))
                    new_names{length(new_names)+1} = players{i}; %#ok<AGROW>
                    obj.addNewPlayer(players{i});
                end
            end
        end
        
        function addNewPlayer(obj, player)
            nr_names = length(obj.name);
            obj.name{nr_names+1} = player;
            obj.rating{nr_names+1} = 1200;
            obj.history{nr_names+1} = nan(length(obj.time),1);
        end
        
        function sp = createSavePoint(obj)
            sp = struct();
            sp.game_players = obj.game_players;
            sp.game_type = obj.game_type;
            sp.history = obj.history;
            sp.name = obj.name;
            sp.rating = obj.rating;
            sp.scores = obj.scores;
            sp.time = obj.time;
            sp.K = obj.K;
        end
        
        function restoreSavePoint(obj, sp)
            obj.game_players = sp.game_players;
            obj.game_type = sp.game_type;
            obj.history = sp.history;
            obj.name = sp.name;
            obj.rating = sp.rating;
            obj.scores = sp.scores;
            obj.time = sp.time;
            obj.K = sp.K;
        end
    end
        
        
    
    
    
    
    
    
    
    
    % Game filtering methods, used by the statistics features of elostruct.
    methods
    
        function ginds = filterGameType(obj, types, inds)
    
            ginds = [];
            if ischar(types)
                types = {types};
            end
            
            for i=1:length(inds)
                g = inds(i);
                if any(strcmp(types, obj.game_type{g}))
                    ginds = [ginds, g]; %#ok<AGROW>
                end
            end                     
        end
        
        
        function ginds = filterSince(obj, dt, inds)
            ginds = inds(obj.time(inds) >= dt);           
        end
        
        function ginds = filterUntil(obj, dt, inds)
            ginds = inds(obj.time(inds) <= dt);
        end
        
        function ginds = filterVs(obj, players, vsand, inds)
            
            ginds = [];
            if ischar(players)
                players = {players};
            end
            
            for i=1:length(inds)
                g = inds(i);
                
                if vsand
                    ok = 1;
                    for j=1:length(players)
                        if ~any(strcmp(players{j}, obj.game_players{g}))
                            ok = 0;
                            break;
                        end
                    end
                    
                else
                    ok = 0;
                    for j=1:length(players)
                        if any(strcmp(players{j}, obj.game_players{g}))
                            ok = 1;
                            break;
                        end
                    end
                end
                
                if ok
                    ginds = [ginds, g]; %#ok<AGROW>
                end
            end
        end
        
    end
        
        
        
    
    
    
    
    
    % Statistics displaying methods, quite long and cumbersome sometimes...
    % They are private since they should be access via the stat() method
    methods (Access = private, Hidden = true)
        
        function list(obj, ginds)
            
            for g=ginds
                fprintf('%3u: %s.\n',g,obj.gameString(g));
            end
            
        end
        
        
        function records(obj, ginds, ids)
            
            n=length(ids);
            maxr = [-1000000, 0, 0]; % Max rating
            minr = [1000000, 0, 0];  % Min rating
            wst = zeros(n,5);        % Win streaks
            nlst = zeros(n,5);       % Non-losing streaks
            lst = zeros(n,5);        % Losing streaks
            nwst = zeros(n,5);       % Non-winning streaks
            sst = zeros(n,5);        % Scoring streaks
            nsst = zeros(n,5);       % Non-scoring streaks
            
            for g=ginds
                for u=1:n
                    if obj.history{ids(u)}(g) > maxr(1)
                        maxr(1) = obj.history{ids(u)}(g);
                        maxr(2) = ids(u);
                        maxr(3) = g;
                    end
                    if obj.history{ids(u)}(g) < minr(1)
                        minr(1) = obj.history{ids(u)}(g);
                        minr(2) = ids(u);
                        minr(3) = g;
                    end
                    
                    sc = obj.getScoreOfPlayer(g, obj.name{ids(u)});
                    if sc >= 0
                        if sc == max(obj.scores{g}) % Did the player have max score?
                            if sum(obj.scores{g} == max(obj.scores{g})) == 1 % Only one max score? => win!
                                wst(u,1) = wst(u,1) + 1;
                                nlst(u,1) = nlst(u,1) + 1;
                                nwst(u,1) = 0;
                                lst(u,1) = 0;
                            else % Tie
                                wst(u,1) = 0;
                                nwst(u,1) = nwst(u,1) + 1;
                                lst(u,1) = 0;
                                nlst(u,1) = nlst(u,1) + 1;
                            end
                        else % Lost
                            nwst(u,1) = nwst(u,1) + 1;
                            lst(u,1) = lst(u,1) + 1;
                            nlst(u,1) = 0;
                            wst(u,1) = 0;
                        end
                        if sc > 0 % Did the player score?
                            sst(u,1) = sst(u,1) + 1;
                            nsst(u,1) = 0;
                        else % No scoring
                            nsst(u,1) = nsst(u,1) + 1;
                            sst(u,1) = 0;
                        end
                        
                        % Start of current streak
                        if wst(u,1) == 1
                            wst(u,2) = g;
                        end
                        if lst(u,1) == 1
                            lst(u,2) = g;
                        end
                        if nwst(u,1) == 1
                            nwst(u,2) = g;
                        end
                        if nlst(u,1) == 1
                            nlst(u,2) = g;
                        end
                        if sst(u,1) == 1
                            sst(u,2) = g;
                        end
                        if nsst(u,1) == 1
                            nsst(u,2) = g;
                        end
                        
                        % Check if longest streak for this player
                        if wst(u,1) > wst(u,3)
                            wst(u,3) = wst(u,1);
                            wst(u,4) = wst(u,2);
                            wst(u,5) = g;
                        end
                        if lst(u,1) > lst(u,3)
                            lst(u,3) = lst(u,1);
                            lst(u,4) = lst(u,2);
                            lst(u,5) = g;
                        end
                        if nwst(u,1) > nwst(u,3)
                            nwst(u,3) = nwst(u,1);
                            nwst(u,4) = nwst(u,2);
                            nwst(u,5) = g;
                        end
                        if nlst(u,1) > nlst(u,3)
                            nlst(u,3) = nlst(u,1);
                            nlst(u,4) = nlst(u,2);
                            nlst(u,5) = g;
                        end
                        if sst(u,1) > sst(u,3)
                            sst(u,3) = sst(u,1);
                            sst(u,4) = sst(u,2);
                            sst(u,5) = g;
                        end
                        if nsst(u,1) > nsst(u,3)
                            nsst(u,3) = nsst(u,1);
                            nsst(u,4) = nsst(u,2);
                            nsst(u,5) = g;
                        end
                    end
                end
            end
            
            
            % Print records
            fprintf('The highest rating is:   %u, attained by %s %s.\n',...
                round(maxr(1)),...
                obj.name{maxr(2)},...
                obj.gameString(maxr(3), 'on %4$s after a %1$s game between %2$s, ending %3$s'));
            fprintf('The lowest rating is:    %u, attained by %s %s.\n',...
                round(minr(1)),...
                obj.name{minr(2)},...
                obj.gameString(minr(3), 'on %4$s after a %1$s game between %2$s, ending %3$s'));
            
            fprintf('\n\n');
            
            m = max(wst(:,3));
            fprintf('The longest winning streak is:      %u games, achieved by:\n', m);
            for u=1:n
                if wst(u,3) == m && m > 0
                    fprintf('%s between %s and %s\n', obj.name{ids(u)}, datestr(obj.time(wst(u,4))), datestr(obj.time(wst(u,5))));
                end
            end
            
            fprintf('\n');
            
            m = max(nlst(:,3));
            fprintf('The longest non-losing streak is:   %u games, achieved by:\n', m);
            for u=1:n
                if nlst(u,3) == m && m > 0
                    fprintf('%s between %s and %s\n', obj.name{ids(u)}, datestr(obj.time(nlst(u,4))), datestr(obj.time(nlst(u,5))));
                end
            end
            
            fprintf('\n');
            
            m = max(nwst(:,3));
            fprintf('The longest non-winning streak is:  %u games, achieved by:\n', m);
            for u=1:n
                if nwst(u,3) == m && m > 0
                    fprintf('%s between %s and %s\n', obj.name{ids(u)}, datestr(obj.time(nwst(u,4))), datestr(obj.time(nwst(u,5))));
                end
            end
            
            fprintf('\n');
            
            m = max(lst(:,3));
            fprintf('The longest losing streak is:       %u games, achieved by:\n', m);
            for u=1:n
                if lst(u,3) == m && m > 0
                    fprintf('%s between %s and %s\n', obj.name{ids(u)}, datestr(obj.time(lst(u,4))), datestr(obj.time(lst(u,5))));
                end
            end
            
            fprintf('\n\n');
            
            m = max(sst(:,3));
            fprintf('The longest streak of games with at least 1 point is:   %u games, achieved by:\n', m);
            for u=1:n
                if sst(u,3) == m && m > 0
                    fprintf('%s between %s and %s\n', obj.name{ids(u)}, datestr(obj.time(sst(u,4))), datestr(obj.time(sst(u,5))));
                end
            end
            
            fprintf('\n');
            
            m = max(nsst(:,3));
            fprintf('The longest streak of games with 0 points is:           %u games, achieved by:\n', m);
            for u=1:n
                if nsst(u,3) == m && m > 0
                    fprintf('%s between %s and %s\n', obj.name{ids(u)}, datestr(obj.time(nsst(u,4))), datestr(obj.time(nsst(u,5))));
                end
            end
            
            fprintf('\n');
            
        end
        
        
        function ratingStat(obj, ginds, ids)
            
            n = length(ids);
            ra = [-ones(n,1)*1000, zeros(n,1), ones(n,1)*1000, zeros(n,3)];
            
            for g=ginds
                for u=1:n
                    ind = find(strcmp(obj.game_players{g}, obj.name{ids(u)}), 1);
                    if ~isempty(ind)
                        if g == 1 || isnan(obj.history{ids(u)}(g-1))
                            ch = obj.history{ids(u)}(g) - 1200;
                        else
                            ch = obj.history{ids(u)}(g) - obj.history{ids(u)}(g-1);
                        end
                        if ch > ra(u,1)
                            ra(u,1) = ch;
                            ra(u,2) = g;
                        end
                        if ch < ra(u,3)
                            ra(u,3) = ch;
                            ra(u,4) = g;
                        end
                        ra(u,5) = ra(u,5) + ch;
                        ra(u,6) = ra(u,6) + 1;
                    end
                end
            end
            
            for u=1:length(ids)
                if (ra(u,6) > 0)
                    fprintf('%s has in total changed %+.2f over %u games (avg %.2f).\nMaximum change is %+.2f, caused by %s.\nMinimum change is %+.2f, caused by %s.\n\n',...
                        obj.name{ids(u)},...
                        sum(ra(u,5)),...
                        ra(u,6),...
                        sum(ra(u,5))./ra(u,6),...
                        ra(u,1),...
                        obj.gameString(ra(u,2)),...
                        ra(u,3),...
                        obj.gameString(ra(u,4)));
                else
                    fprintf('%s has in total changed 0.00 over 0 games.\n\n', obj.name{ids(u)});
                end
            end
        end
        
        
        function scoring(obj, ginds, ids)
            
            sc = cell(length(ids),2);
            
            for g=ginds
                for u=1:length(ids)
                    score = obj.getScoreOfPlayer(g, obj.name{ids(u)});
                    if score >= 0
                        sc{u,1} = [sc{u,1}, score];
                        sc{u,2} = [sc{u,2}, sum(obj.scores{g})];
                    end
                end
            end
            
            for u=1:length(ids)
                if (~isempty(sc{u,1}))
                    fprintf('%s has scored %u of %u points (%u%%).\nVariance of score ratio is %u%%.\n\n',...
                        obj.name{ids(u)},...
                        sum(sc{u,1}),...
                        sum(sc{u,2}),...
                        round(100*sum(sc{u,1})/sum(sc{u,2})),...
                        round(100*var(sc{u,1}./sc{u,2})));
                else
                    fprintf('%s has scored 0 of 0 points (0%%).\n\n',obj.name{ids(u)});
                end
            end
        end
        
        
        function wins(obj, ginds, ids)
            
            wr = zeros(length(ids),3);
            
            for i=ginds
                for u=1:length(ids)
                    sc = obj.getScoreOfPlayer(i, obj.name{ids(u)});
                    
                    if sc >= 0
                        wr(u,1) = wr(u,1) + 1;
                        if sc == max(obj.scores{i});
                            if sum(obj.scores{i} == max(obj.scores{i})) == 1
                                wr(u,2) = wr(u,2) + 1;
                                wr(u,3) = i;
                            end
                        end
                    end
                end
            end
            
            for i=1:length(ids)
                if (wr(i,2) > 0)
                    fprintf('%s has won %u of %u games (%u%%).\nLatest win was a %s\n\n',...
                        obj.name{ids(i)},...
                        wr(i,2),...
                        wr(i,1),...
                        round(100*wr(i,2)/wr(i,1)),...
                        obj.gameString(wr(i,3)));
                else
                    fprintf('%s has won 0 of %u games (0%%).\n\n',...
                        obj.name{ids(i)},...
                        wr(i,1));
                end
            end
        end
    end
    
    
    
    
    
    
    
    
    
    % Plotting methods, private since they should be access via the plot()
    % method
    methods (Access = private, Hidden = true)
        
        function bar(obj, fig)
            srt = obj.getPlayerSorting();
            data = cell2mat(obj.rating(srt));
            txt = cell(1,length(obj.name));
            for i=1:length(obj.name)
                txt{i} = sprintf('%u', round(obj.rating{srt(i)}));
            end
            
            figure(fig);
            clf;
            bar(data);
            title('Elo rating')
            set(gca, 'xticklabel', obj.name(srt));
            text(1:length(data), data, txt, 'HorizontalAlignment','center','VerticalAlignment','bottom');
            xl = xlim;
            yd = max(data)-min(data);
            axis([xl(1) xl(2) min(data)-0.125*yd max(data)+0.125*yd]);
        end
        
        function historyPlot(obj, fig, ginds, xaxis)
                   
            xaxis(1) = upper(xaxis(1));
            switch (xaxis)
                case 'Game'
                    ax = ginds;
                case 'Time'
                    ax = obj.time(ginds);
                otherwise
                    error('Unrecognized x-axis: ''%s''!', xaxis);
            end
            
            srt = obj.getPlayerSorting();
            
            figure(fig);
            clf;
            hold on;
            for i=length(srt):-1:1
                plot(ax, obj.history{srt(i)}(ginds), 'color', obj.getColor(length(srt)-i+1));
            end
            title('Elo rating history');
            legend(flip(obj.name(srt)),'Location','bestOutside');
            xlabel(xaxis);
            colormap(colorcube);
        end
        
        
        function normalizedSinglePlot(obj, fig, ginds, xaxis, id)
            
            xaxis(1) = upper(xaxis(1));
            switch (xaxis)
                case 'Game'
                    ax = ginds;
                case 'Time'
                    ax = obj.time(ginds);
                otherwise
                    error('Unrecognized x-axis: ''%s''!', xaxis);
            end
            
            srt = obj.getPlayerSorting();
            
            figure(fig);
            clf;
            hold on;
            for i=length(srt):-1:1
                plot(ax, 10.^( (obj.history{srt(i)}(ginds) - obj.history{id}(ginds))./400 ).*3, 'color', obj.getColor(length(srt)-i+1));
            end
            title(sprintf('Expected scores in single againts %s', obj.name{id}));
            legend(flip(obj.name(srt)),'Location','bestOutside');
            xlabel(xaxis);
            
        end
        
        function masterPlot(obj, fig, ginds, xaxis, ids)
            
            xaxis(1) = upper(xaxis(1));
            switch (xaxis)
                case 'Game'
                    ax = ginds;
                case 'Time'
                    ax = obj.time(ginds);
                otherwise
                    error('Unrecognized x-axis: ''%s''!', xaxis);
            end
            
            
            avghist = zeros(length(obj.history{1}(ginds)),3);
            
            for k=1:length(ginds)
                g = ginds(k);
                
                %fprintf('Calculating game %u of %u...\n',g, length(history{1}));
                rat = [obj.history{ids(1)}(g), obj.history{ids(2)}(g), obj.history{ids(3)}(g)];
                rat(isnan(rat)) = 1200;
                states = [0, 1, 2, 3, 0, 0, 0, 1];
                lim = 1e-5;
                avgp = zeros(3,1);
                
                while ~isempty(states)
                    
                    in = 1;
                    nr_states = size(states,1);
                    newstates = zeros(2*nr_states,8);
                    
                    for i=1:nr_states
                        
                        state = states(i,:);
                        
                        if state(5) == 3 || state(6) == 3 || state(7) == 3 || state(8) < lim
                            % Someone has won, or probability too small to go deeper
                            avgp(state(2)) = avgp(state(2)) + state(5)*state(8);
                            avgp(state(3)) = avgp(state(3)) + state(6)*state(8);
                            avgp(state(4)) = avgp(state(4)) + state(7)*state(8);
                            continue;
                        end
                        
                        
                        p1 = 10^(rat(state(2))/400) / ( 10^(rat(state(2))/400) + 10^(rat(state(3))/400) );
                        
                        inc = 0;
                        if state(1) == state(2)
                            inc = 1;
                        end
                        newstates(in,:) = [state(2), state(2), state(4), state(3), inc+state(5), state(7), state(6), p1*state(8)];
                        in = in+1;
                        
                        inc = 0;
                        if state(1) == state(3)
                            inc = 1;
                        end
                        newstates(in,:) = [state(3), state(4), state(3), state(2), state(7), inc+state(6), state(5), (1-p1)*state(8)];
                        in=in+1;
                        
                    end
                    
                    newstates(in:end,:) = [];
                    states = newstates;
                    
                end
                
                avghist(k,:) = avgp' ./ max(avgp) .* 3;
            end
            
            figure(fig);
            clf;
            plot(ax, avghist);
            
            legend(obj.name(ids), 'Location','bestOutside');
            title(sprintf('Expected results of a master game, outside starter: %s', obj.name{ids(3)}));
            xlabel(xaxis);
            axis([xlim, 0, 3.5]);
            
        end
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Static utility functions
    methods (Static)
        
        
        function ex = expectedSingleScores(ratings, scoresum)
            % Expected scores in a single game
            ex = 10 .^ ( ratings ./ 400 );
            ex = ex./(sum(ex)) * scoresum;
        end
        
        function ex = expectedMasterScores(ratings, scoresum)
            % Expected scores of a master game
            
            % Each row of states will correspond to one possible game at the current
            % depth. The elements of each row are as follows:
            % master player id, player 1 id, player 2 id, non-playing player id,
            % player 1 score, player 2 score, non-playing player score, probability of
            % this state.
            states = [0, 1, 2, 3, 0, 0, 0, 1];
            
            % When the probability of a node is lower than this, we stop.
            lim = 1e-8;
            
            avgp = zeros(3,1);
            
            while ~isempty(states)
                
                ind = 1;
                nr_states = size(states,1);
                
                % Each current state can give 2 new states, one of 2 players will score
                newstates = zeros(2*nr_states,8);
                
                for i=1:nr_states
                    
                    state = states(i,:);
                    
                    if state(5) == 3 || state(6) == 3 || state(7) == 3 || state(8) < lim
                        % Someone has won, or probability too small to go deeper
                        avgp(state(2)) = avgp(state(2)) + state(5)*state(8);
                        avgp(state(3)) = avgp(state(3)) + state(6)*state(8);
                        avgp(state(4)) = avgp(state(4)) + state(7)*state(8);
                        continue;
                    end
                    
                    % Probability of player 1 to score
                    p1 = 10^(ratings(state(2))/400) / ( 10^(ratings(state(2))/400) + 10^(ratings(state(3))/400) );
                    
                    inc = 0;
                    % If player 1 won, and was master, increase points.
                    if state(1) == state(2)
                        inc = 1;
                    end
                    newstates(ind,:) = [state(2), state(2), state(4), state(3), inc+state(5), state(7), state(6), p1*state(8)];
                    ind = ind+1;
                    
                    inc = 0;
                    % If player 2 won, and was master, increase points.
                    if state(1) == state(3)
                        inc = 1;
                    end
                    newstates(ind,:) = [state(3), state(4), state(3), state(2), state(7), inc+state(6), state(5), (1-p1)*state(8)];
                    ind=ind+1;
                    
                end
                
                newstates(ind:end,:) = [];
                states = newstates;
                
            end
            
            ex = avgp ./ sum(avgp) * scoresum;
        end
        
        function ex = expectedDoubleScores(ratings, scoresum)
            % Expected scores of a double game 
            
            ex = [10^((ratings(1)+ratings(2))/800) ; 10^((ratings(3)+ratings(4))/800)];
            ex = ex./(sum(ex)) * scoresum;
        end
        
        
        function accept = prompt(msg)
            % This function will propmt the user to accept the message.
            
            s = 'a';
            tries = 0;
            
            while (strcmp(s,'y') == 0 && strcmp(s,'n') == 0 && tries < 3)
                
                s = input(sprintf('%s (y/n)', msg),'s');
                tries = tries + 1;
                
            end
            
            accept = strcmp(s,'y');
            
        end
        
        function color = getColor(i)
            
            % Plot parameter
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
            
            color = colmap(mod(i-1,nrcol)+1,:);
        end   
       
    end
    
    
end
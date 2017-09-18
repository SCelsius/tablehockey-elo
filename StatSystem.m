classdef StatSystem < handle
    
    properties (GetAccess = public, SetAccess = private)
        
        game_log = [];
        player_names = {};
        player_ids = [];
        
    end
    
    properties (GetAccess = private, SetAccess = private)
        rating_systems = [];
        player_alias_ids = {};
        player_stops = {};
    end
    
    
    methods
        
        function obj = StatSystem()
            obj.rating_systems = [BasicEloRatingSystem('total',{'single','master','double','double master'},{'single','master'},12),...
                BasicEloRatingSystem('individual',{'single','master'},{'single','master'},12),...
                BasicEloRatingSystem('team',{'double','double master'},{'double','double master'},10),...
                BasicEloRatingSystem('single',{'single'},{'single'},12),...
                BasicEloRatingSystem('master',{'master'},{'master'},8),...
                BasicEloRatingSystem('double',{'double'},{'double'},12),...
                BasicEloRatingSystem('double master',{'double master'},{'double master'},12)];

            obj.game_log = GameLog();
        end
        
        function importElostructData(obj, edata)
            obj.removeGamesAfter(0);
            
            for i=1:length(edata.game_type)
                players = edata.game_players{i};
                if strcmp(edata.game_type{i}, 'double')
                    players = {players{1}, players{2}; players{3}, players{4}};
                else
                    players = players';
                end
                
                obj.addGameLast(edata.game_type{i}, players, edata.scores{i}, datestr(edata.time(i)));
            end
        end
        
        function importStatSystemData(obj, sdata)
            obj.removeGamesAfter(0);
            
            for i=1:sdata.game_log.getNumberOfGames()
                type = sdata.game_log.getTypeOfGame(i);
                players = sdata.game_log.getPlayerNamesOfGame(i);
                score = sdata.game_log.getScoreOfGame(i);
                time_str = sdata.game_log.getTimeStrOfGame(i);
                
                obj.addGameLast(type, players, score, time_str);
                fprintf('%u/%u\n',i,sdata.game_log.getNumberOfGames());
            end
        end
        
        function enterGame(obj, type, player_names, score, varargin)
            
            savepoint = obj.createSavePoint();
            
            try
                if ~isempty(varargin)
                    try
                        time_str = datestr(datetime(varargin{1}));
                    catch
                        time_str = datestr(datetime(varargin{1},'InputFormat','HH:mm'));
                    end
                else
                    time_str = datestr(datetime('now'));
                end
                
                % Validate input
                [valid, msg] = obj.game_log.validateGameSetup(type, player_names, score);
                
                if ~valid
                    fprintf('Invalid game setup: %s!\n', msg);
                    obj.restoreSavePoint(savepoint);
                    return;
                end
                
                % Dispatch to correct add game method
                game_nr = obj.game_log.findInsertionGameNr(time_str);
                if game_nr <= obj.game_log.getNumberOfGames()
                    changed = obj.addHistoricalGame(type, player_names, score, time_str, game_nr, savepoint);
                    obj.printChange(savepoint, changed, obj.player_ids);
                else
                    changed = obj.addGameLast(type, player_names, score, time_str);
                    obj.printChange(savepoint, changed, obj.getPlayerIds(player_names));
                end
                
                if ~obj.prompt('Accept these changes?')
                    obj.restoreSavePoint(savepoint);
                end
                
            catch ME
                fprintf('Unexpected error, no change is made!\n');
                obj.restoreSavePoint(savepoint);
                rethrow(ME);
            end
        end
        
        
        
        function removeGame(obj, game_nr)
            
            savepoint = obj.createSavePoint();
            
            try
                
                if game_nr > obj.game_log.getNumberOfGames() || game_nr < 1
                    error('There is no game %u!', game_nr);
                end
                
                total_nr = savepoint.game_log.getNumberOfGames() - game_nr;
                changed = obj.removeGamesAfter(game_nr-1);
                for i=game_nr+1:savepoint.game_log.getNumberOfGames()
                    fprintf('Processing game %u of %u...\n', i-game_nr, total_nr);
                    changed = min(changed + obj.addGameLast(savepoint.game_log.getTypeOfGame(i),...
                        savepoint.game_log.getPlayerNamesOfGame(i),...
                        savepoint.game_log.getScoreOfGame(i),...
                        savepoint.game_log.getTimeStrOfGame(i)),1);
                end
                for i=1:length(obj.player_stops)
                    for j=1:length(obj.player_stops{i})
                        if obj.player_stops{i}(j) >= game_nr
                            obj.player_stops{i}(j) = obj.player_stops{i}(j) - 1;
                        end
                    end
                end
                
                fprintf('\nRemoved a %s.\n\n', savepoint.game_log.getDescriptionOfGame(game_nr));
                
                obj.printChange(savepoint, changed, obj.player_ids);
                
                if ~obj.prompt('Accept these changes?')
                    obj.restoreSavePoint(savepoint);
                end
                
            catch ME
                fprintf('Unexpected error, no change is made!\n');
                obj.restoreSavePoint(savepoint);
                rethrow(ME);
            end
        end
        
        
        function renamePlayer(obj, player_name, new_name) 
            
            for i=1:length(obj.player_names)
                if strcmp(player_name, obj.player_names{i})
                    if obj.prompt(sprintf('Rename %s to %s?', obj.player_names{i}, new_name))
                        obj.player_names{i} = new_name;
                        obj.game_log.renamePlayer(player_name, new_name);
                    end
                    break;
                end
            end
            
        end
        
        
        function addRatingSystem(obj, rating_system_class, varargin)
            
            new_rs = feval(rating_system_class, varargin{:});
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).name, new_rs.name)
                    error('Rating system named ''%s'' already exists!', new_rs.name);
                end
            end
            
            
            for i=1:obj.game_log.getNumberOfGames()
                fprintf('Processing game %u of %u...\n', i, obj.game_log.getNumberOfGames());
                ids = obj.game_log.getPlayerIdsOfGame(i).ids;
                aliases = obj.getAliasesForGameNr(ids, i);
                
                new_rs.processNewGameLast(obj.game_log.getTypeOfGame(i),...
                    aliases,...
                    obj.game_log.getScoreOfGame(i),...
                    obj.game_log.getTimeStrOfGame(i),...
                    i,...
                    obj.game_log);
            end
            fprintf('\nRatings of new system ''%s'':\n', new_rs.name);
            ratings = new_rs.getCurrentRatings(obj.getCurrentAliases(obj.player_ids));
            len = obj.getLongestNameLength();
            
            for i=1:length(ratings)
                if ~isnan(ratings(i))
                    nam = obj.getNameOfId(obj.player_ids(i));
                    fprintf('%s%s: %u\n', blanks(len-length(nam)), nam, round(ratings(i)));
                end
            end
            
            obj.rating_systems = [obj.rating_systems, new_rs];
        end
        
        
        function removePlayer(obj, name)
            for i=1:length(obj.player_names)
                ind = find(strcmp(obj.player_names{i}, name),1,'first');
                if ~isempty(ind)
                    if obj.player_stops{i} >= obj.game_log.getNumberOfGames()
                        error('Cannot remove a player before a later removal of that same player!');
                    end
                    if obj.prompt(sprintf('Are you sure you want to remove player ''%s''?', name))
                        new_alias = max(cellfun(@(ar) max(ar), obj.player_alias_ids)) + 1;
                        obj.player_alias_ids{i} = [obj.player_alias_ids{i}, new_alias];
                        obj.player_stops{i} = [obj.player_stops{i}, obj.game_log.getNumberOfGames()];
                    end
                    return;
                end
            end
            
            fprintf('There is no player named ''%s''!\n', name);
        end
        
        
        function reinstatePlayer(obj, name)     
            
            savepoint = obj.createSavePoint();
            
            try
                game_nr = -1;
                
                for i=1:length(obj.player_names)
                    ind = find(strcmp(obj.player_names{i}, name),1,'first');
                    if ~isempty(ind)
                        if obj.prompt(sprintf('Are you sure you want to reinstate player ''%s''?', name))
                            nr_stops = length(obj.player_stops{i});
                            if (nr_stops == 0) 
                                error('Player have never been removed.');
                            else
                                game_nr = obj.player_stops{i}(nr_stops);
                                obj.player_alias_ids{i} = obj.player_alias_ids{i}(1:nr_stops);
                                obj.player_stops{i} = obj.player_stops{i}(1:nr_stops-1);
                            end
                        else
                            error('User cancelled the operation.');
                        end
                    end
                end
                
                if (game_nr < 0)
                    error('There is no player named %s!', name);
                end
                                
                total_nr = savepoint.game_log.getNumberOfGames() - game_nr;
                changed = obj.removeGamesAfter(game_nr);
                
                for i=game_nr+1:savepoint.game_log.getNumberOfGames()
                    fprintf('Processing game %u of %u...\n', i-game_nr, total_nr);
                    changed = min(changed + obj.addGameLast(savepoint.game_log.getTypeOfGame(i),...
                        savepoint.game_log.getPlayerNamesOfGame(i),...
                        savepoint.game_log.getScoreOfGame(i),...
                        savepoint.game_log.getTimeStrOfGame(i)),1);
                end
                
                obj.printChange(savepoint, changed, obj.player_ids);
                
                if ~obj.prompt('Accept these changes?')
                    obj.restoreSavePoint(savepoint);
                end
                
            catch ME
                fprintf('Unexpected error, no change is made!\n');
                obj.restoreSavePoint(savepoint);
                rethrow(ME);
            end 
            
        end
        
        
        function removePlayerAtGameNr(obj, name, game_nr)
            
           savepoint = obj.createSavePoint();
            
            try
                
                if game_nr > obj.game_log.getNumberOfGames() || game_nr < 1
                    error('There is no game %u!', game_nr);
                end
                
                total_nr = savepoint.game_log.getNumberOfGames() - game_nr;
                changed = obj.removeGamesAfter(game_nr);
                
                obj.removePlayer(name);
                
                for i=game_nr+1:savepoint.game_log.getNumberOfGames()
                    fprintf('Processing game %u of %u...\n', i-game_nr, total_nr);
                    changed = min(changed + obj.addGameLast(savepoint.game_log.getTypeOfGame(i),...
                        savepoint.game_log.getPlayerNamesOfGame(i),...
                        savepoint.game_log.getScoreOfGame(i),...
                        savepoint.game_log.getTimeStrOfGame(i)),1);
                end
                
                obj.printChange(savepoint, changed, obj.player_ids);
                
                if ~obj.prompt('Accept these changes?')
                    obj.restoreSavePoint(savepoint);
                end
                
            catch ME
                fprintf('Unexpected error, no change is made!\n');
                obj.restoreSavePoint(savepoint);
                rethrow(ME);
            end 
        end
            
        
        
        function removeRatingSystem(obj, name)
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).name, name)
                    if obj.prompt(sprintf('Are you sure you want to remove rating system ''%s''?', name))
                        obj.rating_systems(i) = [];
                    end
                    return;
                end
            end
            
            fprintf('There is no rating system named ''%s''!\n', name);
        end
        
        
        function replayAllGameData(obj)
            savepoint = obj.createSavePoint();
            
            try
                
                total_nr = savepoint.game_log.getNumberOfGames();
                obj.removeGamesAfter(0);
                for i=1:total_nr
                    fprintf('Processing game %u of %u...\n', i, total_nr);
                    obj.addGameLast(savepoint.game_log.getTypeOfGame(i),...
                        savepoint.game_log.getPlayerNamesOfGame(i),...
                        savepoint.game_log.getScoreOfGame(i),...
                        savepoint.game_log.getTimeStrOfGame(i));
                end
                
                
                obj.printChange(savepoint, ones(size(obj.rating_systems)), obj.player_ids);
                
                if ~obj.prompt('Accept these changes?')
                    obj.restoreSavePoint(savepoint);
                end
                
            catch ME
                fprintf('Unexpected error, no change is made!\n');
                obj.restoreSavePoint(savepoint);
                rethrow(ME);
            end
        end
        
        function setSystemParameter(obj, system_name, param_name, param_value)
            
            savepoint = obj.createSavePoint();
            
            try
                for i=1:length(obj.rating_systems)
                    if strcmp(obj.rating_systems(i).name, system_name)
                        if obj.rating_systems(i).setParameter(param_name, param_value)
                            
                            obj.rating_systems(i).removeGamesAfter(0);
                            obj.game_log.removeGames(1:obj.game_log.getNumberOfGames());
                            
                            total_nr = savepoint.game_log.getNumberOfGames();
                            for j=1:total_nr
                                fprintf('Processing game %u of %u...\n', j, total_nr);
                                
                                type = savepoint.game_log.getTypeOfGame(j);
                                ids = savepoint.game_log.getPlayerIdsOfGame(j).ids;
                                names = savepoint.game_log.getPlayerNamesOfGame(j);
                                score = savepoint.game_log.getScoreOfGame(j);
                                time_str = savepoint.game_log.getTimeStrOfGame(j);
                                
                                aliases = obj.getAliasesForGameNr(ids, j);
                                
                                obj.rating_systems(i).processNewGameLast(type,...
                                    aliases,...
                                    score,...
                                    time_str,...
                                    j,...
                                    obj.game_log);
                                
                                obj.game_log.addGame(type, ids, aliases, names, score, time_str);
                            end
                            
                            obj.game_log = savepoint.game_log;
                            changed = zeros(1,length(obj.rating_systems));
                            changed(i) = 1;
                            
                            obj.printChange(savepoint, changed, obj.player_ids);
                            
                            if ~obj.prompt('Accept these changes?')
                                obj.restoreSavePoint(savepoint);
                            end
                            
                            
                        else
                            error('Cannot set parameter ''%s'' in system ''%s''!', param_name, system_name);
                        end
                        return;
                    end
                end
                
                fprintf('There is no rating system named ''%s''!\n', name);
                
                
            catch ME
                fprintf('Unexpected error, no change is made!\n');
                obj.restoreSavePoint(savepoint);
                rethrow(ME);
            end
            
            
        end
        
        
        function name = getNameOfId(obj, id)
            ind = find(obj.player_ids == id,1,'first');
            
            if isempty(ind)
                name = 'ERROR NOT FOUND';
            else
                name = obj.player_names{ind};
            end
        end
        
        
        function ids = getPlayerIds(obj, names)
            if ischar(names)
                names = {names};
            end
            
            ids = zeros(size(names));
            
            for i=1:numel(names)
                ids(i) = obj.getPlayerId(names{i});
            end
        end
        
        function id = getPlayerId(obj, name)
            id = obj.player_ids(find(strcmp(obj.player_names, name),1,'first'));
            if isempty(id)
                error('There is no player named ''%s''!', name);
            end
        end
        
        
        function ratings = getRatingsOfSystem(obj, system_name, player_ids)
            
            aliases = obj.getCurrentAliases(player_ids);
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).name, system_name)
                    ratings = obj.rating_systems(i).getCurrentRatings(aliases);
                    return;
                end
            end
            
            ratings = nan(size(player_ids));
        end
        
        function ratings = getStartRatingsOfSystem(obj, system_name, player_ids)
            
            aliases = obj.getFirstAliases(player_ids);
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).name, system_name)
                    ratings = obj.rating_systems(i).getStartRatings(aliases);
                    return;
                end
            end
        end
        
        function [history, game_inds] = getHistoryOfSystem(obj, system_name, player_ids, from_game, to_game)
            
            alias_ids = [];
            
            for i=1:numel(player_ids)
                alias_ids = [alias_ids, obj.getAllAliases(player_ids(i))]; %#ok<AGROW>
            end
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).getName(), system_name)
                    [hist, game_inds] = obj.rating_systems(i).getRatingHistory(alias_ids, from_game, to_game);
                    
                    row = 1;
                    history = nan(numel(player_ids),length(game_inds));
                    
                    for j=1:numel(player_ids)
                        len = length(obj.getAllAliases(player_ids(j)));
                        stops = obj.getAllStops(player_ids(j));
                        if len == 1
                            history(j,:) = hist(row,:);
                        else
                            for k=1:len-1
                                if stops(k) < to_game
                                    ind = find(game_inds > stops(k),1,'first');
                                    if isempty(ind)
                                        ind = 1;
                                    end
                                    hist(row+k-1,ind:end) = NaN;
                                end
                            end
                            history(j,:) = max(hist(row:row+len-1,:));
                        end
                        row = row+len;
                    end
                    return;
                end
            end
            
            history = nan(size(player_ids));
            game_inds = [];
            
        end
        
        
        function score = getEstimatedScoreOfSystem(obj, system_name, game_type, ratings)
            
            % Validate input
            [valid, msg] = obj.game_log.validateGameSetup(game_type, ratings, ones(size(ratings,1),1));
            
            if ~valid
                fprintf('Invalid game setup: %s!\n', msg);
                score = [];
                return;
            end
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).name, system_name)
                    score = obj.rating_systems(i).getEstimatedNormalizedScore(game_type, ratings);
                    return;
                end
            end
            
            score = [];
            
        end
        
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    methods (Access = private)
        
        function alias = getCurrentAlias(obj, id)
%             ind = find(obj.player_ids == id,1,'first');
%             if isempty(ind)
%                 error('Could not find player id %u!',id);
%             end
%             
%             alias = obj.player_alias_ids{ind}(end);
            alias = obj.getAliasForGameNr(id, obj.game_log.getNumberOfGames());
        end
        
        function aliases = getCurrentAliases(obj, ids)
            aliases = zeros(size(ids));
            
            for i=1:numel(ids)
                aliases(i) = obj.getCurrentAlias(ids(i));
            end
        end
        
        function alias = getFirstAlias(obj, id)
            ind = find(obj.player_ids == id,1,'first');
            if isempty(ind)
                error('Could not find player id %u!',id);
            end
            
            alias = obj.player_alias_ids{ind}(1);
        end
        
        function aliases = getFirstAliases(obj, ids)
            aliases = zeros(size(ids));
            
            for i=1:numel(ids)
                aliases(i) = obj.getFirstAlias(ids(i));
            end
        end
        
        function alias = getAliasForGameNr(obj, id, game_nr)
            ind = find(obj.player_ids == id,1,'first');
            if isempty(ind)
                error('Could not find player id %u!',id);
            end
            
            ind2 = 1;
            if ~isempty(obj.player_stops{ind})
                ind2 = find(obj.player_stops{ind} >= game_nr,1,'first');
                if isempty(ind2)
                    ind2 = length(obj.player_alias_ids{ind});
                end
            end
                
            alias = obj.player_alias_ids{ind}(ind2);
        end
        
        function aliases = getAliasesForGameNr(obj, ids, game_nr)
            aliases = zeros(size(ids));
            
            for i=1:numel(ids)
                aliases(i) = obj.getAliasForGameNr(ids(i), game_nr);
            end
        end
        
        function aliases = getAllAliases(obj, id)
            ind = find(obj.player_ids == id,1,'first');
            if isempty(ind)
                error('Could not find player id %u!',id);
            end
            
            aliases = obj.player_alias_ids{ind};
        end
        
        function aliases = getAllStops(obj, id)
            ind = find(obj.player_ids == id,1,'first');
            if isempty(ind)
                error('Could not find player id %u!',id);
            end
            
            aliases = obj.player_stops{ind};
        end
        
        
        
        
        
        function changed = addGameLast(obj, type, player_names, score, time_str)
            
            obj.createNewPlayersIfNeeded(player_names);
            ids = obj.getPlayerIds(player_names);
            aliases = obj.getCurrentAliases(ids);
            
            game_nr = obj.game_log.findInsertionGameNr(time_str);
            
            changed = zeros(length(obj.rating_systems),1);
            for i=1:length(obj.rating_systems)
                changed(i) = obj.rating_systems(i).processNewGameLast(type, aliases, score, time_str, game_nr, obj.game_log);
            end
            
            obj.game_log.addGame(type, ids, aliases, player_names, score, time_str);
        end
        
        
        function changed = addHistoricalGame(obj, type, player_names, score, time_str, game_nr, savepoint)
            
            obj.removeGamesAfter(game_nr-1);
            obj.game_log.removeGames(game_nr:obj.game_log.getNumberOfGames());
            
            total_nr = savepoint.game_log.getNumberOfGames() - game_nr + 2;
            fprintf('Entering historical game:\nProcessing game %u of %u...\n', 1, total_nr);
            
            changed = obj.addGameLast(type, player_names, score, time_str);
            
            for i=1:length(obj.player_stops)
                for j=1:length(obj.player_stops{i})
                    if obj.player_stops{i}(j) >= game_nr
                        obj.player_stops{i}(j) = obj.player_stops{i}(j) + 1;
                    end
                end
            end
                
            
            for i = game_nr:savepoint.game_log.getNumberOfGames()
                fprintf('Processing game %u of %u...\n', i - game_nr + 2, total_nr);
                changed = min(changed + obj.addGameLast(savepoint.game_log.getTypeOfGame(i),...
                    savepoint.game_log.getPlayerNamesOfGame(i),...
                    savepoint.game_log.getScoreOfGame(i),...
                    savepoint.game_log.getTimeStrOfGame(i)),1);
            end
            fprintf('\n');
        end
        
        
        function changed = removeGamesAfter(obj, game_nr)
            changed = zeros(length(obj.rating_systems),1);
            for i=1:length(obj.rating_systems)
                changed(i) = obj.rating_systems(i).removeGamesAfter(game_nr);
            end
            
            obj.game_log.removeGames(game_nr+1:obj.game_log.getNumberOfGames());
        end
        
        
        
        function printChange(obj, savepoint, which, ids)
            
            if nargin < 3
                which = ones(length(obj.rating_systems),1);
            end
            
            ids = unique(ids);
            
            len = obj.getLongestNameLength();
            for i=1:length(obj.rating_systems)
                if which(i)
                    fprintf('Rating changes of system ''%s'':\n', obj.rating_systems(i).name);
                    for j = 1:numel(ids)
                        id = ids(j);
                        alias = obj.getCurrentAlias(id);
                        old_rating = savepoint.rating_systems(i).getCurrentRatings(alias);
                        new_rating = obj.rating_systems(i).getCurrentRatings(alias);
                        diff = new_rating-old_rating;
                        if ~isnan(new_rating)
                            nam = obj.getNameOfId(id);
                            fprintf('%s%s: ', blanks(len-length(nam)), nam);
                            if isnan(old_rating)
                                fprintf('%u (new)\n', round(new_rating));
                            else
                                if diff < 0
                                    sign = '-';
                                else
                                    sign = '+';
                                end
                                fprintf('%u (%s%u)\n', round(new_rating), sign, abs(round(diff)));
                            end
                        end
                    end
                    fprintf('\n');
                end
            end
            
        end
        
        function len = getLongestNameLength(obj)
            len = 0;
            for i=1:length(obj.player_names)
                if length(obj.player_names{i}) > len
                    len = length(obj.player_names{i});
                end
            end
        end
        
        
        
        function new_names = createNewPlayersIfNeeded(obj, player_names)
            
            new_names = {};
            
            for i=1:numel(player_names)
                ind = find(strcmp(obj.player_names, player_names{i}),1,'first');
                
                if isempty(ind)
                    obj.player_names = [obj.player_names player_names(i)];
                    id = max(obj.player_ids) + 1;
                    alias = max(cellfun(@(ar) max(ar), obj.player_alias_ids)) + 1;
                    if isempty(id)
                        id = 1;
                    end
                    if isempty(alias)
                        alias = 1000;
                    end
                    obj.player_ids = [obj.player_ids, id];
                    obj.player_alias_ids = [obj.player_alias_ids, {alias}];
                    obj.player_stops = [obj.player_stops, {[]}];
                    new_names = [new_names {player_names(i)}]; %#ok<AGROW>
                end
            end
        end
        
        
        
        function savepoint = createSavePoint(obj)
            
            savepoint = struct();
            savepoint.game_log         = obj.game_log.clone();
            savepoint.player_names     = obj.player_names;
            savepoint.player_alias_ids = obj.player_alias_ids;
            savepoint.player_stops     = obj.player_stops;
            savepoint.player_ids       = obj.player_ids;
            savepoint.rating_systems   = obj.rating_systems;
            
            for i=1:length(obj.rating_systems)
                savepoint.rating_systems(i) = obj.rating_systems(i).clone();
            end
            
        end
        
        function restoreSavePoint(obj, savepoint)
            
            obj.game_log         = savepoint.game_log;
            obj.player_names     = savepoint.player_names;
            obj.player_alias_ids = savepoint.player_alias_ids;
            obj.player_stops     = savepoint.player_stops;
            obj.player_ids       = savepoint.player_ids;
            obj.rating_systems   = savepoint.rating_systems;
            
        end
        
        function accept = prompt(~, msg)
            % This function will propmt the user to accept the message.
            
            s = 'a';
            tries = 0;
            while (strcmp(s,'y') == 0 && strcmp(s,'n') == 0 && tries < 3)
                
                s = input(sprintf('%s (y/n)', msg),'s');
                tries = tries + 1;
                
            end
            accept = strcmp(s,'y');
        end
    end
    
    
end
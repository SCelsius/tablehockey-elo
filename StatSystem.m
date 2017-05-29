classdef StatSystem < handle
    
    properties (GetAccess = public, SetAccess = private)
        
        game_log = [];
        player_names = {};
        player_ids = [];
        
    end
    
    properties (GetAccess = private, SetAccess = private)
        rating_systems = [];
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
            end
        end
        
        function enterGame(obj, type, player_names, score, varargin)
            
            savepoint = obj.createSavePoint();
            
            try
                if ~isempty(varargin) > 0
                    time_str = varargin{1};
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
                    obj.printChange(savepoint, changed, 1:length(obj.player_ids));
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
                fprintf('\nRemoved a %s.\n\n', savepoint.game_log.getDescriptionOfGame(game_nr));
                
                obj.printChange(savepoint, changed, 1:length(obj.player_ids));
                
                if ~obj.prompt('Accept these changes?')
                    obj.restoreSavePoint(savepoint);
                end
                
            catch ME
                fprintf('Unexpected error, no change is made!\n');
                obj.restoreSavePoint(savepoint);
                rethrow(ME);
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
                new_rs.processNewGameLast(obj.game_log.getTypeOfGame(i),...
                    obj.game_log.getPlayerIdsOfGame(i),...
                    obj.game_log.getScoreOfGame(i),...
                    obj.game_log.getTimeStrOfGame(i),...
                    i,...
                    obj.game_log);
            end
            fprintf('\nRatings of new system ''%s'':\n', new_rs.name);
            ratings = new_rs.getCurrentRatings(obj.player_ids);
            len = obj.getLongestNameLength();
            
            for i=1:length(ratings)
                if ~isnan(ratings(i))
                    nam = obj.getNameOfId(obj.player_ids(i));
                    fprintf('%s%s: %u\n', blanks(len-length(nam)), nam, round(ratings(i)));
                end
            end
            
            obj.rating_systems = [obj.rating_systems, new_rs];
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
                
                
                obj.printChange(savepoint, ones(size(obj.rating_systems)), 1:length(obj.player_ids));
                
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
                        if obj.rating_systems(i).setParameter(param_name, param_value);
                            
                            obj.rating_systems(i).removeGamesAfter(0);
                            obj.game_log.removeGames(1:obj.game_log.getNumberOfGames());
                            
                            total_nr = savepoint.game_log.getNumberOfGames();
                            for j=1:total_nr
                                fprintf('Processing game %u of %u...\n', j, total_nr);
                                
                                type = savepoint.game_log.getTypeOfGame(j);
                                ids = savepoint.game_log.getPlayerIdsOfGame(j);
                                names = savepoint.game_log.getPlayerNamesOfGame(j);
                                score = savepoint.game_log.getScoreOfGame(j);
                                time_str = savepoint.game_log.getTimeStrOfGame(j);
                                
                                obj.rating_systems(i).processNewGameLast(type,...
                                    ids,...
                                    score,...
                                    time_str,...
                                    j,...
                                    obj.game_log);
                                
                                obj.game_log.addGame(type, ids, names, score, time_str);
                            end
                            
                            obj.game_log = savepoint.game_log;
                            changed = zeros(1,length(obj.rating_systems));
                            changed(i) = 1;
                            
                            obj.printChange(savepoint, changed, 1:length(obj.player_ids));
                            
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
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).name, system_name)
                    ratings = obj.rating_systems(i).getCurrentRatings(player_ids);
                    return;
                end
            end
            
            ratings = nan(size(player_ids));
        end
        
        function ratings = getStartRatingsOfSystem(obj, system_name, player_ids)
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).name, system_name)
                    ratings = obj.rating_systems(i).getStartRatings(player_ids);
                    return;
                end
            end
        end
        
        function [history, game_inds] = getHistoryOfSystem(obj, system_name, player_ids, from_game, to_game)
            
            for i=1:length(obj.rating_systems)
                if strcmp(obj.rating_systems(i).getName(), system_name)
                    [history, game_inds] = obj.rating_systems(i).getRatingHistory(player_ids, from_game, to_game);
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
        
        
        function changed = addGameLast(obj, type, player_names, score, time_str)
            
            obj.createNewPlayersIfNeeded(player_names);
            ids = obj.getPlayerIds(player_names);
            
            game_nr = obj.game_log.findInsertionGameNr(time_str);
            
            changed = zeros(length(obj.rating_systems),1);
            for i=1:length(obj.rating_systems)
                changed(i) = obj.rating_systems(i).processNewGameLast(type, ids, score, time_str, game_nr, obj.game_log);
            end
            
            obj.game_log.addGame(type, ids, player_names, score, time_str);
        end
        
        
        function changed = addHistoricalGame(obj, type, player_names, score, time_str, game_nr, savepoint)
            
            obj.removeGamesAfter(game_nr-1);
            obj.game_log.removeGames(game_nr:obj.game_log.getNumberOfGames());
            
            total_nr = savepoint.game_log.getNumberOfGames() - game_nr + 2;
            fprintf('Entering historical game:\nProcessing game %u of %u...\n', 1, total_nr);
            
            changed = obj.addGameLast(type, player_names, score, time_str);
            
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
                        old_rating = savepoint.rating_systems(i).getCurrentRatings(id);
                        new_rating = obj.rating_systems(i).getCurrentRatings(id);
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
                    id = min(setdiff(1:length(obj.player_names),obj.player_ids));
                    obj.player_ids = [obj.player_ids, id];
                    new_names = [new_names {player_names(i)}]; %#ok<AGROW>
                end
            end
        end
        
        
        
        function savepoint = createSavePoint(obj)
            
            savepoint = struct();
            savepoint.game_log = obj.game_log.clone();
            savepoint.player_names = obj.player_names;
            savepoint.player_ids = obj.player_ids;
            savepoint.rating_systems = obj.rating_systems;
            
            for i=1:length(obj.rating_systems)
                savepoint.rating_systems(i) = obj.rating_systems(i).clone();
            end
            
        end
        
        function restoreSavePoint(obj, savepoint)
            
            obj.game_log = savepoint.game_log;
            obj.player_names = savepoint.player_names;
            obj.player_ids = savepoint.player_ids;
            obj.rating_systems = savepoint.rating_systems;
            
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
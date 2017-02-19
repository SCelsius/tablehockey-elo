classdef GameLog < handle
    
    properties (GetAccess = private, SetAccess = private)
        
        games = [];
        
    end
    
    
    
    properties (GetAccess = public, Constant = true)
        
        valid_game_types = {'single','master','double','double master'};
        game_type_dims = [2 1;  % Single is 2 teams, 1 player/team 
                          3 1;  % Master is 3 teams, 1 player/team
                          2 2;  % Double is 2 teams, 2 players/team
                          3 2]; % Double master is 3 teams, 2 players/team
        
    end
    
    
    
    
    
    
    % Methods that modifies the game log is only accessible to the
    % statistics system
    methods (Access = {?StatSystem})
        
        function addGame(obj, game_type, player_ids, player_names, score, time_str)
            game_nr = obj.findInsertionGameNr(time_str);
            
            if isrow(score)
                score = score';
            end
            win = score == max(score);
            tie = win;
            if sum(win) == 1
                tie = zeros(size(tie));
            else
                win = zeros(size(win));
            end
            
            new_game = struct();
            new_game.type = game_type;
            new_game.player_ids = player_ids;
            new_game.player_names = player_names;
            new_game.time = datetime(time_str);
            new_game.score = score;
            new_game.win = win;
            new_game.tie = tie;
            
            % Place game at correct place in time line
            bf = 1:game_nr-1;
            af = game_nr:length(obj.games);
            
            bfgames = obj.games(bf);
            afgames = obj.games(af);
            if isempty(bfgames)
                bfgames = [];
            end
            if isempty(afgames)
                afgames = [];
            end
            obj.games = [bfgames, new_game, afgames];
        end     
        
        function removeGames(obj, game_inds)
            
            keep_inds = setdiff(1:length(obj.games), game_inds);
            
            obj.games = obj.games(keep_inds);            
        end
    end
    
    
    
    
    
    % Public methods that gives access to read data from the log
    methods (Access = public)
        
        function clon = clone(obj)
            clon = feval(class(obj));
            
            clon.games = obj.games;
        end
        
        function [valid, msg] = validateGameSetup(obj, game_type, player_ids, score)
            
            valid = true;
            msg = 'valid';
            ind = find(strcmp(obj.valid_game_types, game_type),1);
            
            if isempty(ind)
                valid = false;
                msg = sprintf('Unknown game type: ''%s''', game_type);
                
            elseif size(player_ids,1) ~= obj.game_type_dims(ind, 1)
                valid = false;
                msg = sprintf('%s should have %u teams',...
                    obj.valid_game_types{ind},...
                    obj.game_type_dims(ind, 1));
                
            elseif size(player_ids,2) ~= obj.game_type_dims(ind, 2)
                valid = false;
                msg = sprintf('%s should have %u players per team',...
                    obj.valid_game_types{ind},...
                    obj.game_type_dims(ind, 2));
                
            elseif length(score) ~= obj.game_type_dims(ind, 1)
                valid = false;
                msg = sprintf('%s should have %u scores',...
                    obj.valid_game_types{ind},...
                    obj.game_type_dims(ind,1));
            end
        end
        
        function nr = findInsertionGameNr(obj, time_str)
            if isempty(obj.games)
                nr = 1;
            else
                nr = sum([obj.games.time] <= datetime(time_str)) + 1;
            end
        end
        
        function desc = getDescriptionOfGame(obj, game_nr, varargin)
            
            if isempty(varargin)
                fmt = '%1$s game (%4$s): %2$s, ending %3$s'; 
            else
                fmt = varargin{1};
            end
            
            plstr = '';
            for i=1:size(obj.games(game_nr).player_names, 1)
                if i > 1
                    plstr = sprintf('%s vs. ', plstr);
                end
                for j=1:size(obj.games(game_nr).player_names, 2)
                    if j == size(obj.games(game_nr).player_names, 2) && j > 1
                        plstr = sprintf('%s and ', plstr);
                    elseif j > 1
                        plstr = sprintf('%s, ', plstr);
                    end
                    plstr = sprintf('%s%s', plstr, obj.games(game_nr).player_names{i,j});
                end
            end
            
            scstr = strjoin(arrayfun(@(x) sprintf('%u',x), obj.games(game_nr).score, 'UniformOutput', false),'-');
            
            desc = sprintf(fmt, obj.games(game_nr).type, plstr, scstr, datestr(obj.games(game_nr).time));
        end
        
        
        
        function nr_games = getNumberOfGames(obj)
            nr_games = length(obj.games);
        end
        

        
        
        function time_str = getTimeStrOfGame(obj, game_nr)
            if game_nr < 1 || game_nr > length(obj.games)
                time_str = 'ERROR NO TIME STRING';
            else
                time_str = datestr(obj.games(game_nr).time);
            end
        end
        
        function type = getTypeOfGame(obj, game_nr)
            if game_nr < 1 || game_nr > length(obj.games)
                type = 'ERROR NO TYPE';
            else
                type = obj.games(game_nr).type;
            end            
        end
        
        function score = getScoreOfGame(obj, game_nr)
            if game_nr < 1 || game_nr > length(obj.games)
                score = 'ERROR NO SCORE';
            else
                score = obj.games(game_nr).score;
            end            
        end
        
        function player_names = getPlayerNamesOfGame(obj, game_nr)
            if game_nr < 1 || game_nr > length(obj.games)
                player_names = 'ERROR NO PLAYER NAMES';
            else
                player_names = obj.games(game_nr).player_names;
            end              
        end
        
        function player_ids = getPlayerIdsOfGame(obj, game_nr)
            if game_nr < 1 || game_nr > length(obj.games)
                player_ids = 'ERROR NO PLAYER IDS';
            else
                player_ids = obj.games(game_nr).player_ids;
            end              
        end
        
        
        
        
        
        % Function to filter games on arbitrary conditions
        function game_inds = filterGameIndsOnFunc(obj, func, ginds)
            game_inds = ginds(arrayfun(func, obj.games(ginds)));
        end
        
        
        
        % Some basic game filtering functions
        function game_inds = filterGameIndsOnGameTypes(obj, types, ginds)
            game_inds = obj.filterGameIndsOnFunc(@(g) any(strcmp(types, g.type)), ginds);       
        end
        
        function game_inds = filterGameIndsOnTime(obj, since, until, ginds)
            game_inds = obj.filterGameIndsOnFunc(@(g) g.time >= datetime(since) && g.time <= datetime(until), ginds);
        end
        
        function game_inds = filterGameIndsOnPlayerIdsAny(obj, ids, ginds)
            game_inds = obj.filterGameIndsOnFunc(@(g) ~isempty(intersect(ids, g.player_ids)), ginds);
        end
        
        function game_inds = filterGameIndsOnPlayerIdsAll(obj, ids, ginds)
            game_inds = obj.filterGameIndsOnFunc(@(g) length(intersect(ids, g.player_ids)) == length(ids), ginds);
        end
        
        
        
        
        % Function to collect arbitrary data from a set of games into a
        % cell array
        function data = getGameData(obj, func, ginds)
            data = arrayfun(func, obj.games(ginds), 'UniformOutput', false);
        end
        
        % Function to collect arbitrary values from a set of games into an
        % array
        function data = getGameValues(obj, func, ginds)
            data = arrayfun(func, obj.games(ginds));
        end
        
        
        
        % Some basic data collection functions
        function wins = getNumberOfWinsForId(obj, id, ginds)
           wins = sum(obj.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.win)), ginds));
        end
        
        function ties = getNumberOfTiesForId(obj, id, ginds)
           ties = sum(obj.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.tie)), ginds));
        end
        
        function nr_games = getNumberOfGamesForId(obj, id, ginds)
            nr_games = sum(obj.getGameValues(@(ga) max(any(ga.player_ids == id,2)), ginds));
        end
        
        function points = getPointsForId(obj, id, ginds)
            points = sum(obj.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.score)), ginds));
        end
        
        function points = getTotalGamePointsForId(obj, id, ginds)
            points = sum(obj.getGameValues(@(ga) max(any(ga.player_ids == id,2))*sum(ga.score), ginds));
        end
        
        function ratios = getPointRatiosForId(obj, id, ginds)
            ratios = obj.getGameValues(@(ga) max(any(ga.player_ids == id,2).*(ga.score)) / sum(ga.score), ginds);
        end
    end
end
classdef BasicEloRatingSystem < RatingSystem
    
    properties (GetAccess = private, SetAccess = private)
        
        game_types;
        K = 10;
        
        rating = [];
        history = [];
        player_id_to_ind = [];
        game_inds = [];
        
    end
    
    
    
    methods 
    
        function changed = processNewGameLast(obj, type, player_ids, score, time_str, game_nr, game_log)
            
            changed = false;
            % Only process if matches game_types
            if any(strcmp(obj.game_types, type))
                if isempty(obj.game_inds)
                    last_time_str = '';
                else
                    last_time_str = game_log.getTimeStrOfGame(obj.game_inds(end));
                end
                obj.addGameLast(type, player_ids, score, game_nr, last_time_str, time_str);
                changed = true;
            end
            
        end
        
        function changed = removeGamesAfter(obj, game_nr)
            nr_to_remove = sum(obj.game_inds > game_nr);
            
            if nr_to_remove > 0
                changed = true;
                obj.history(:,end-nr_to_remove+1:end) = [];
                if isempty(obj.history)
                    obj.rating = [];
                else
                    obj.rating = obj.history(:,end);
                end
                
                pl_to_remove = sum(isnan(obj.rating)); 
                obj.player_id_to_ind(obj.player_id_to_ind > length(obj.rating) - pl_to_remove) = 0;
                obj.history(end-pl_to_remove+1:end,:) = [];
                if isempty(obj.history)
                    obj.rating = [];
                else
                    obj.rating = obj.history(:,end);
                end                
                
                obj.game_inds(end-nr_to_remove+1:end) = [];
                
            else
                changed = false;
            end
        end
        
        function ok = setParameter(obj, name, value)
            switch(name)
                case 'K'
                    obj.K = value;
                    ok = true;
                    
                otherwise
                    ok = false;
            end
        end
    end
    
    
    
    
    
    
    
    
    methods
        
        function clon = clone(obj)
            
            clon = feval(class(obj), obj.name, obj.game_types);
            clon.rating = obj.rating;
            clon.history = obj.history;
            clon.player_id_to_ind = obj.player_id_to_ind;
            clon.game_inds = obj.game_inds;
            
        end
        
        function obj = BasicEloRatingSystem(name, game_types)
            
            obj@RatingSystem(name);
            if ischar(game_types)
                obj.game_types = {game_types};
            else
                obj.game_types = game_types;
            end
            
        end
        
       
        function rating = getCurrentRatings(obj, player_ids)
            rating = nan(size(player_ids));
            
            for i = 1:numel(player_ids)
                
                ind = obj.getIndOfPlayerId(player_ids(i));
                
                if ind == 0
                    rating(i) = nan;
                else
                    rating(i) = obj.rating(ind);
                end
            end
        end
        
        function [history, game_inds] = getRatingHistory(obj, player_ids, from_game, to_game)
            from_ind = find(obj.game_inds >= from_game,1,'first');
            to_ind = find(obj.game_inds <= to_game,1,'last');
            
            if isempty(from_ind) || isempty(to_ind) || to_ind < from_ind
                history = [];
                game_inds = [];
            else
                history = nan(numel(player_ids), to_ind-from_ind+1);
                
                for i=1:numel(player_ids)
                    ind = obj.getIndOfPlayerId(player_ids(i));
                    if ind == 0
                        history(i,:) = nan;
                    else
                        history(i,:) = obj.history(ind,from_ind:to_ind);
                    end
                end
                
                game_inds = obj.game_inds(from_ind:to_ind);
            end
        end
        
        
        function score = getEstimatedNormalizedScore(obj, type, ratings)
            
            if ~any(strcmp(type, obj.game_types))
                type = 'Not supported';
            end
            
            switch (type)
                case 'single'
                    score = obj.getExpectedSingleScores(ratings, 1);
                    if isrow(score)
                        score = score';
                    end
                    
                case 'master'
                    score = obj.getExpectedMasterScores(ratings, 1);
                    if isrow(score)
                        score = score';
                    end
                    
                case 'double'
                    score = obj.getExpectedDoubleScores(ratings, 1);
                    if isrow(score)
                        score = score';
                    end
                    
                case 'double master'
                    score = obj.getExpectedDoubleMasterScores(ratings, 1);
                    if isrow(score)
                        score = score';
                    end
                    
                otherwise
                    score = ones(size(ratings));
                    score = score ./ sum(score);
            end
        end
    end
    
    
    
    
    
    
    
    methods (Access = private)
        
        
        function addGameLast(obj, type, player_ids, score, game_nr, last_game_time_str, time_str)
            
            % First check for inactivity up until this game
            indiffs = obj.getInactivityChanges(last_game_time_str, time_str);
            
            nr_new = obj.addNewPlayersIfNeeded(player_ids);
            
            % Extend lenght of indiffs to match #players (might have been
            % added now)
            indiffs = [indiffs; zeros(nr_new,1)];
            
            % Update ratings to include inactivity 
            ratings_after_inact = obj.rating + indiffs;
            
            % Get players' indices in the rating vector
            inds = zeros(size(player_ids));
            for i=1:numel(inds)
                inds(i) = obj.getIndOfPlayerId(player_ids(i));
            end
            
            % Get diff for playing players
            diff = obj.getRatingDiff(type, obj.rating(inds), score);
            
            % Update ratings and history
            obj.rating = ratings_after_inact;
            for i=1:numel(inds)
                obj.rating(inds(i)) = obj.rating(inds(i)) + diff(i);
            end
            
            if isempty(obj.history)
                obj.history = obj.rating;
            else
                obj.history = [obj.history, obj.rating];
            end
                
            obj.game_inds = [obj.game_inds, game_nr]; 
        end
        
        
        function inact = getInactivityChanges(obj, ~, ~)
            inact = zeros(size(obj.rating));            
        end
        
        function nr_new = addNewPlayersIfNeeded(obj, player_ids)
           
            nr_new = 0;
            
            for i=1:numel(player_ids)
                ind = obj.getIndOfPlayerId(player_ids(i));
                
                if ind == 0
                    nr_new = nr_new+1;
                    new_ind = length(obj.rating)+1;
                    obj.rating = [obj.rating; 1200];
                    obj.history = [obj.history; nan(1, length(obj.game_inds))];
                    obj.player_id_to_ind(player_ids(i)) = new_ind;
                end
            end
            
        end
        
        
        function ind = getIndOfPlayerId(obj, id)
            if id > length(obj.player_id_to_ind)
                obj.player_id_to_ind = [obj.player_id_to_ind; zeros(id-length(obj.player_id_to_ind),1)];
            end
            ind = obj.player_id_to_ind(id);
        end
        
        
        function diff = getRatingDiff(obj, type, ratings, score)
            
            switch (type)
                case 'single'
                    ex = obj.getExpectedSingleScores(ratings, sum(score));
                    if isrow(score)
                        score = score';
                    end
                    if isrow(ex)
                        ex = ex';
                    end
                    
                    diff = obj.K .* (score - ex);
                    
                case 'master'
                    ex = obj.getExpectedMasterScores(ratings, sum(score));
                    if isrow(score)
                        score = score';
                    end
                    if isrow(ex)
                        ex = ex';
                    end
                    
                    diff = obj.K .* (score - ex);
                    
                case 'double'
                    ex = obj.getExpectedDoubleScores(ratings, sum(score));
                    if isrow(score)
                        score = score';
                    end
                    if isrow(ex)
                        ex = ex';
                    end
                    
                    diff = kron(0.5 .* obj.K .* (score - ex), [1 1]);
                    
                case 'double master'
                    ex = obj.getExpectedDoubleMasterScores(ratings, sum(score));
                    if isrow(score)
                        score = score';
                    end
                    if isrow(ex)
                        ex = ex';
                    end
                    
                    diff = kron(0.5 .* obj.K .* (score - ex), [1 1]);
                    
                otherwise
                    diff = zeros(size(ratings));
                    
                    if isrow(diff)
                        diff = diff';
                    end
            end
            
        end
        
    end 
    
    
    
    
    
    methods (Access = private, Static)
        
        
        function ex = getExpectedSingleScores(ratings, scoresum)
            ex = 10 .^ ( ratings ./ 400 );
            ex = ex./(sum(ex)) * scoresum;
        end
        
        function ex = getExpectedMasterScores(ratings, scoresum)
            % Each row of states will correspond to one possible game at the current
            % depth. The elements of each row are as follows:
            % master player id, player 1 id, player 2 id, non-playing player id,
            % player 1 score, player 2 score, non-playing player score, probability of
            % this state.
            states = [0, 1, 2, 3, 0, 0, 0, 1];
            
            % When the probability of a node is lower than this, we stop.
            lim = 1e-6;
            
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
        
        
        function ex = getExpectedDoubleScores(ratings, scoresum)
            ex = BasicEloRatingSystem.getExpectedSingleScores([(ratings(1,1)+ratings(1,2))/2; (ratings(2,1)+ratings(2,2))/2], scoresum);
        end
        
        function ex = getExpectedDoubleMasterScores(ratings, scoresum)
            ex = BasicEloRatingSystem.getExpectedMasterScores([(ratings(1,1)+ratings(1,2))/2; (ratings(2,1)+ratings(2,2))/2; (ratings(3,1)+ratings(3,2))/2], scoresum);
        end
        
    end
    
end
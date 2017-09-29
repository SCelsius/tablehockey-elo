classdef BasicEloRatingSystem < RatingSystem
    
    properties (GetAccess = private, SetAccess = private)
        
        start_game_types;
        start_games = 10;
        start_rating = [];
        
        game_types;
        K = 15;
        
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
                obj.addGameLast(type, player_ids, score, game_nr, last_time_str, time_str, game_log);
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
            
            clon = feval(class(obj), obj.name, obj.game_types, obj.start_game_types, obj.start_games);
            clon.rating = obj.rating;
            clon.history = obj.history;
            clon.player_id_to_ind = obj.player_id_to_ind;
            clon.game_inds = obj.game_inds;
            clon.start_rating = obj.start_rating;
            clon.K = obj.K;
            
        end
        
        function obj = BasicEloRatingSystem(name, game_types, start_game_types, start_games)
            
            obj@RatingSystem(name);
            if ischar(game_types)
                obj.game_types = {game_types};
            else
                obj.game_types = game_types;
            end
            
            if ischar(game_types)
                obj.start_game_types = {start_game_types};
            else
                obj.start_game_types = start_game_types;
            end
            
            obj.start_games = start_games;
            
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
        
        function rating = getStartRatings(obj, player_ids)
            rating = nan(size(player_ids));
            
            for i=1:numel(player_ids)
                ind = obj.getIndOfPlayerId(player_ids(i));
                
                if ind > 0
                    rating(i) = obj.start_rating(ind);
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
        
        
        function addGameLast(obj, type, player_ids, score, game_nr, last_game_time_str, time_str, game_log)
            
            if obj.checkPreRatingGame(type, player_ids, game_nr, game_log)
                % Do nothing, this game will only be used to calculate an
                % initial rating for the player that has not played enough
                % yet.
                return;
            end
            
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
        
        function ispre = checkPreRatingGame(obj, type, player_ids, game_nr, game_log)
            isnotrated = ones(size(player_ids));
            nrgames = zeros(size(player_ids));
            ginds = game_log.filterGameIndsOnGameTypes(obj.start_game_types, 1:(game_nr-1));
            for i=1:numel(player_ids)
                if obj.getIndOfPlayerId(player_ids(i)) > 0
                    isnotrated(i) = 0;
                end
                nrgames(i) = game_log.getNumberOfGamesForId(player_ids(i), ginds);
            end
            
            % If no-one is not rated, then this is not a pre-rating game
            if sum(isnotrated(:)) == 0
                ispre = false;
                return;
            elseif ~any(strcmp(obj.start_game_types, type))
                % If someone is not rated, but this game type is not a
                % start type, then it is a pre-game.
                ispre = true;
                return;
            elseif sum(isnotrated(:) .* (nrgames(:) < obj.start_games)) > 0
                % If someone that is not rated, hasn't reached the required
                % number of start games before this game, then it is a pre
                % game
                ispre = true;
                return;
            end
            
            % Else we have some non-rated players, but they now have enough
            % games to enter the rating system => calculate initial
            % ratings.
            ispre = false;
            
            for i=1:numel(player_ids)
                if isnotrated(i)
                    
                    % Extract data from this players initial rating games
                    this_ginds = game_log.filterGameIndsOnPlayerIdsAny(player_ids(i), ginds);
                    ratios = game_log.getPointRatiosForId(player_ids(i), this_ginds);
                    types = game_log.getGameData(@(g) g.type, this_ginds);
                    ids = game_log.getGameData(@(g) g.player_ids.aliases, this_ginds);
                    ratings = cell(1,length(this_ginds));
                    pl_teams = zeros(1,length(this_ginds));
                    pl_inds = zeros(1,length(this_ginds));
                    
                    for j=1:length(this_ginds)
                        [team, ind] = ind2sub(size(ids{j}), find(ids{j} == player_ids(i),1));
                        pl_teams(j) = team;
                        pl_inds(j) = ind;
                        ratings{j} = 1200*ones(size(ids{j}));
                        prev_game = find(obj.game_inds < this_ginds(j),1,'last');
                        
                        % Fill the rating matrix of each game with other
                        % players ratings at that time. If the player did
                        % not have a rating at that time (or if there was 
                        % no game before that), use its start
                        % rating. If that does not exist either, use the
                        % average value of start ratings, and if that is
                        % empty, assume 1200.
                        if isempty(obj.start_rating)
                            default_rating_value = 1200;
                        else
                            default_rating_value = 1200;
                        end
                        for k=1:numel(ratings{j})
                            ind = obj.getIndOfPlayerId(ids{j}(k));
                            value = default_rating_value;
                            
                            if ind > 0
                                if isempty(prev_game) || isnan(obj.history(ind,prev_game))
                                    value = obj.start_rating(ind);
                                else
                                    value = obj.history(ind,prev_game);
                                end
                            end
                            
                            ratings{j}(k) = value; 
                        end
                    end
                    
                    % Find rating value that best would predict the actual
                    % results (min 600, seems unlikely that anyone would
                    % ever have lower, and handles case of a really bad
                    % start of the player, like not having scored at all
                    % during these initial games)
                    r = fminsearch(@(x) errFun(obj, ratios, types, ratings, pl_teams, pl_inds, x), 1200);
                    r = max(r,600);
                    
                    new_ind = length(obj.rating)+1;
                    obj.rating = [obj.rating; r];
                    obj.start_rating = [obj.start_rating; r];
                    obj.history = [obj.history; nan(1, length(obj.game_inds))];
                    obj.player_id_to_ind(player_ids(i)) = new_ind;
                    
                end
            end       
            
            function err = errFun(obj, ratios, types, ratings, pl_teams, pl_inds, rating)
                exps = zeros(size(ratios));
                for g=1:length(ratios)
                    rs = ratings{g};
                    rs(pl_teams(g), pl_inds(g)) = rating;
                    ex = obj.getEstimatedNormalizedScore(types{g}, rs);
                    exps(g) = ex(pl_teams(g));
                end
                err = mean((ratios-exps).^2);
            end
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
   
    
    
    
    
    
    
    
    
    methods (Access = public, Static)
        
        
        function ex = getExpectedSingleScores(ratings, scoresum)
            ex = 10 .^ ( ratings ./ 400 );
            ex = ex./(sum(ex)) * scoresum;
        end
        
        function ex = getExpectedMasterScores(ratings, scoresum)
            p1score2 = 1/(1+10^((ratings(2)-ratings(1))/400));
            p1score3 = 1/(1+10^((ratings(3)-ratings(1))/400));
            p2score3 = 1/(1+10^((ratings(3)-ratings(2))/400));
            p = [0, p1score2, p1score3; (1-p1score2), 0, p2score3; (1-p1score3), (1-p2score3), 0];
            
            pc1 = p(1,2)*p(3,1)*p(2,3);
            pc2 = p(2,1)*p(1,3)*p(3,2);
            
            p13100 = p(1,2)*pc2/(1-pc2);
            p12100 = p(1,2)*p(1,3)/(1-pc1);
            p23010 = p(2,1)*pc1/(1-pc1);
            p21010 = p(2,1)*p(2,3)/(1-pc2);
            p31001 = p(1,2)*p(3,1)*p(3,2)/(1-pc1);
            p32001 = p(2,1)*p(3,2)*p(3,1)/(1-pc2);
            pt = p13100+p12100+p23010+p21010+p31001+p32001;
            
            tp = zeros(3, 3, 3);
            tp(1,2,1) = p(1,2);
            tp(1,2,2) = p(2,1)*p(2,3);
            tp(1,2,3) = p(2,1)*p(3,2)*p(3,1);
            tp(1,3,1) = p(1,3);
            tp(1,3,2) = p(3,1)*p(2,3)*p(2,1);
            tp(1,3,3) = p(3,1)*p(3,2);
            tp(2,1,1) = p(1,2)*p(1,3);
            tp(2,1,2) = p(2,1);
            tp(2,1,3) = p(1,2)*p(3,1)*p(3,2);
            tp(2,3,1) = p(3,2)*p(1,3)*p(1,2);
            tp(2,3,2) = p(2,3);
            tp(2,3,3) = p(3,2)*p(3,1);
            tp(3,1,1) = p(1,3)*p(1,2);
            tp(3,1,2) = p(1,3)*p(2,1)*p(2,3);
            tp(3,1,3) = p(3,1);
            tp(3,2,1) = p(2,3)*p(1,2)*p(1,3);
            tp(3,2,2) = p(2,3)*p(2,1);
            tp(3,2,3) = p(3,2);
            for i=1:3
                for j=1:3
                    if i ~= j
                        tp(i,j,:) = tp(i,j,:) / sum(tp(i,j,:));
                    end
                end
            end
            
            
            states = [1 3 1 0 0 p13100/pt;...
                      1 2 1 0 0 p12100/pt;...
                      2 3 0 1 0 p23010/pt;...
                      2 1 0 1 0 p21010/pt;...
                      3 1 0 0 1 p31001/pt;...
                      3 2 0 0 1 p32001/pt];
                  
            ex = [0 0 0];
                  
            while ~isempty(states)
                new_states = zeros(size(states,1)*3,6);
                ind = 1;
                
                for i=1:size(states,1)
                    state = states(i,:);
                    
                    if max(state(3:5)) >= 3
                        ex = ex + state(3:5) * state(6);
                        continue;
                    end
                    
                    c1 = mod(state(1)+3-state(2),3) == 1;
                    
                    if c1
                        s1 = [1, 2, [1 0 0]+state(3:5), state(6)*tp(state(1),state(2),1)];
                        s2 = [2, 3, [0 1 0]+state(3:5), state(6)*tp(state(1),state(2),2)];
                        s3 = [3, 1, [0 0 1]+state(3:5), state(6)*tp(state(1),state(2),3)];
                    else
                        s1 = [1, 3, [1 0 0]+state(3:5), state(6)*tp(state(1),state(2),1)];
                        s2 = [2, 1, [0 1 0]+state(3:5), state(6)*tp(state(1),state(2),2)];
                        s3 = [3, 2, [0 0 1]+state(3:5), state(6)*tp(state(1),state(2),3)];
                    end
                    
                    new_states(ind,:) = s1;
                    new_states(ind+1,:) = s2;
                    new_states(ind+2,:) = s3;
                    ind = ind+3;
                end
                
                states = new_states(1:ind-1,:);
            end
                  
            ex = ex/sum(ex)*scoresum;
        end
        
        function ex = getExpectedDoubleScores(ratings, scoresum)
            ex = BasicEloRatingSystem.getExpectedSingleScores([(ratings(1,1)+ratings(1,2))/2; (ratings(2,1)+ratings(2,2))/2], scoresum);
        end
        
        function ex = getExpectedDoubleMasterScores(ratings, scoresum)
            ex = BasicEloRatingSystem.getExpectedMasterScores([(ratings(1,1)+ratings(1,2))/2; (ratings(2,1)+ratings(2,2))/2; (ratings(3,1)+ratings(3,2))/2], scoresum);
        end
        
    end
    
end
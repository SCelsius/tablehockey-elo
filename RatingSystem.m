classdef (Abstract) RatingSystem < handle
    
    properties (GetAccess = public, SetAccess = private) 
        name = '';
    end
    
    methods (Abstract)
        
        changed = processNewGameLast(obj, type, player_ids, score, time_str, game_nr, game_log)
        changed = removeGamesAfter(obj, game_nr)
        rating = getCurrentRatings(obj, player_ids)
        [history, game_inds] = getRatingHistory(obj, player_ids, from_game, to_game)
        ok = setParameter(obj, name, value)
        clon = clone(obj)
        score = getEstimatedNormalizedScore(obj, type, ratings)
        
    end
    
    methods
        function obj = RatingSystem(name)
            obj.name = name;
        end
    end
    
end
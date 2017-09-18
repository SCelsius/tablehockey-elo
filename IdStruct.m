classdef IdStruct
   
    properties (GetAccess = private, SetAccess = private)
        
        ids1;
        ids2;
        
    end
    
    methods
    
        function obj = IdStruct(ids1, ids2)
            if nargin < 2
                ids2 = ids1;
            end
            
            obj.ids1 = ids1;
            obj.ids2 = ids2;
        end
        
        function e = eq(obj1, obj2)
            
            is1 = isa(obj1,'IdStruct');
            is2 = isa(obj2,'IdStruct');
            
            if is1 && is2
                e = or(or(obj1.ids1 == obj2.ids1, obj1.ids2 == obj2.ids2),or(obj1.ids1 == obj2.ids2, obj1.ids2 == obj2.ids1));
            elseif is1                
                e = or(obj1.ids1 == obj2, obj1.ids2 == obj2);
            elseif is2
                e = or(obj2.ids1 == obj1, obj2.ids2 == obj1);
            else
                e = false;
            end
        end
        
        
        
        function sz = size(obj, varargin)
            sz = size(obj.ids1, varargin{:});
        end
        
        function val = subsref(obj, s)
            if strcmp(s.type, '.')
                if strcmp(s.subs, 'ids')
                    val = obj.ids1;
                elseif strcmp(s.subs, 'aliases')
                    val = obj.ids2;
                else
                    error('IdStruct has no member ''%s''',s.subs);
                end
            else
                val = IdStruct(subsref(obj.ids1, s), subsref(obj.ids2, s));
            end
        end
        
        function empt = isempty(obj)
            empt = isempty(obj.ids1);
        end
        
        function res = intersect(obj1, obj2)
            if isa(obj1,'IdStruct')
                ar1 = [obj1.ids1(:); obj1.ids2(:)];
            else
                ar1 = obj1;
            end
            
            if isa(obj2,'IdStruct')
                ar2 = [obj2.ids1(:); obj2.ids2(:)];
            else
                ar2 = obj2;
            end
            
            res = intersect(ar1, ar2);
        end
    
    end
    
end
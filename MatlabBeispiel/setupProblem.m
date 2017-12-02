function [f, intcom, Aineq,bineq, Aeq, beq,lb,ub,param]=setupProblem(param) %#ok<INUSD,STOUT>
%
% Split up in four steps for higher readability..
setupProblem_1_IndicesAndPrealloc
setupProblem_2_EqualityConstraints
setupProblem_3_InequalityConstraints
setupProblem_4_TargetFunction
end
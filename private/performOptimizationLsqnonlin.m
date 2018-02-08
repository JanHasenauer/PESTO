function [negLogPost_opt, par_opt, gradient_opt, hessian_opt, exitflag, n_objfun, n_iter] ...
    = performOptimizationLsqnonlin(parameters, negLogPost, par0, options)

    % Definition of index set of optimized parameters
    freePars = setdiff(1:parameters.number, options.fixedParameters);
    options.localOptimizerOptions.Algorithm = 'trust-region-reflective';
    
    % Run lsqnonlin
    [par_opt, chi2value, ~, exitflag, results_lsqnonlin, ~, jacobian_opt] = lsqnonlin(...
        negLogPost,...
        par0(freePars), ...
        parameters.min(freePars), ...
        parameters.max(freePars), ...
        options.localOptimizerOptions);
    
    % Assignment of results
    negLogPost_opt = 0.5 * chi2value + options.logPostOffset;
    par_opt(freePars) = par_opt;
    par_opt(options.fixedParameters) = options.fixedParameterValues;
    n_objfun = results_lsqnonlin.funcCount;
    n_iter = results_lsqnonlin.iterations;
    
    % Assigment of Hessian (gradient is not computed)
    gradient_opt = nan(size(par_opt));
    if ~isempty(jacobian_opt)
        hessian_sqrt = full(jacobian_opt);
        hessian_opt = hessian_sqrt' * hessian_sqrt;
    end
    
end
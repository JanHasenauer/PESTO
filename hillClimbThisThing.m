function [x, fval, exitflag, output] = hillClimbThisThing(fun, x0, lb, ub, options)

    dim = length(x0);

    % extract options
    [tolX,tolFun,maxIter,maxFunEvals,outputFcn] = f_extractOptions(options,dim);
    if (isfield(options,'OutputFcn'))
        outputFcn = options.OutputFcn;
        visual = true;
    else
        visual = false;
    end
    
    % Set options % TODO pass as parameter
    logbar = 'log-barrier';
    
    % align vectors in 1st dimension
    lb = lb(:);
    ub = ub(:);
    middle = lb + 0.5*(ub-lb);
    x0 = x0(:);
    np = size(x0,1);
    
    % converged?
    converged = false;
    exitflag = -1;
    startTime = cputime;
    
    % initialize variables for optimization, wlak to the middle first
    % correct, if initial step size was set to 0
    step = -sign(x0-middle) * 0.01 .* (ub-lb) .* ones(size(x0));
    zeroInd = (step==0);
    step(zeroInd) = 0.01 .* (ub(zeroInd)-lb(zeroInd)) .* ones(sum(zeroInd), 1);
    [~, ind] = max(abs(x0-middle) ./ (ub-lb));
    current_i = ind;
    x = x0;
    iStep = 0;
    funcCount = 0;
    
    obj_val = fun(x);
    funcCount = funcCount + 1;
    
    if (visual)
        f_output(x,obj_val,iStep,'init',outputFcn);
    end
    
    while (~converged)
        % increase counter
        iStep = iStep + 1;
        
        % Use log-barrier, if necessary
        if logbar 
            obj_val = barrierFunction(obj_val, [], x, [lb, ub], iStep, maxIter, 'log-barrier');
        end
        
        % Look into different directions
        foundDescent = false;
        new_obj_val = Inf;new_x=x;
        while ~foundDescent
            % Set new step
            delta = zeros(size(lb));
            % Make sure not to exceed bounds
            if step(current_i) > 0
                if (x(current_i) + step(current_i) >= ub(current_i))
                    delta(current_i) = 0.75*(ub(current_i)-x(current_i));
                else
                    delta(current_i) = step(current_i);
                end
                if (x(current_i) - step(current_i) <= lb(current_i))
                    delta(current_i) = 0.75*(x(current_i)-lb(current_i));
                end
            else
                if (x(current_i) + step(current_i) <= lb(current_i))
                    delta(current_i) = 0.75*(lb(current_i)-x(current_i));
                else
                    delta(current_i) = step(current_i);
                end
                if (x(current_i) - step(current_i) >= ub(current_i))
                    delta(current_i) = 0.75*(ub(current_i)-x(current_i));
                end
            end
            step(current_i) = delta(current_i);
            
            % Test new objective value in delta direction
            new_obj_val_p = fun(x + delta);
            funcCount = funcCount + 1;
            
            % Use log-barrier, if necessary
            if logbar 
                new_obj_val_p = barrierFunction(new_obj_val_p, [], x + delta, [lb, ub], iStep, maxIter, 'log-barrier');
            end

            % Success?
            if new_obj_val_p < obj_val
                new_x = max(min(x + delta, ub), lb);
                new_obj_val = new_obj_val_p;
                step(current_i) = step(current_i) * 1.5;
                foundDescent = true;
            else
                % No? Test in negative delta direction
                new_obj_val_m = fun(x - delta);
                funcCount = funcCount + 1;
                
                % Use log-barrier, if necessary
                if logbar 
                    new_obj_val_m = barrierFunction(new_obj_val_m, [], x - delta, [lb, ub], iStep, maxIter, 'log-barrier');
                end
                
                % Success now?
                if new_obj_val_m < obj_val
                    new_x = min(max(x - delta, lb), ub);
                    new_obj_val = new_obj_val_m;
                    step(current_i) = -step(current_i) * 1.5;
                    foundDescent = true;
                else
                    % No? Try next direction and make step size smaller
                    step(current_i) = step(current_i)/4;
                    if current_i == np
                        current_i = 1;
                    else
                        current_i = current_i + 1;
                    end
                end
            end
            
            % Chekc for tolerance in step size
            if all(abs(step) < tolX)
                converged = true;
                foundDescent = true;
                exitflag = 2;
            end
        end
        
        % Check for tolernace in objective function
        if ~converged
            stepSize_y = abs(obj_val - new_obj_val);
            if stepSize_y < tolFun
                converged = true;
                exitflag = 1;
            end
        end
        
        % update current state
        obj_val = new_obj_val;
        x = new_x;
        
        if (visual)
            f_output(x,obj_val,iStep,'iter',outputFcn);
        end
        
        % Check for maxIter
        if (iStep > maxIter || funcCount > maxFunEvals)
            converged = true;
            exitflag = 0;
        end
    end
    
    % Assign values
    fval = obj_val;
    output.t_cpu = cputime - startTime;
    output.iterations = iStep;
    output.funcCount = funcCount;
    output.algorithm = 'Hill Climb This Thing';
    
    if (visual)
        f_output(x,obj_val,iStep,'done',outputFcn);
    end
end

function [tolX,tolFun,maxIter,maxFunEvals,outputFcn] = f_extractOptions(options,dim)
% interpret options

    if (isfield(options,'TolX'))
        tolX    = options.TolX;
    else
        tolX    = 1e-6;
    end
    
    if (isfield(options,'TolFun'))
        tolFun  = options.TolFun;
    else
        tolFun  = 1e-6;
    end
    
    if (isfield(options,'MaxIter'))
        maxIter = options.MaxIter;
    else
        maxIter = 200*dim;
    end
    
    if (isfield(options,'MaxFunEvals'))
        maxFunEvals = options.MaxFunEvals;
    else
        maxFunEvals = 400*dim;
    end
    
    if (isfield(options,'OutputFcn'))
        outputFcn = options.OutputFcn;
    else
        outputFcn = nan;
    end
    
end

function f_output(x,fval,iter,state,outputFcn)
% short for call to output function
    optimValues.fval = fval;
    optimValues.iteration = iter;
    outputFcn(x,optimValues,state);
end
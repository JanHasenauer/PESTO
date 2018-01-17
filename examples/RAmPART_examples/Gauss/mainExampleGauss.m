% Main file of the Gaussian mixture example for RBPT debugging
%
% Demonstrates the use of:
% * getParameterSamples()
%
% Demonstrates furthermore:
% * how to use RBPT
% * how to use advanced plotting tools from PESTO
%
% The example problem is a mixture of Gaussian modes in the first two
% dimensions and a single mode in any other dimension. The dimensionality,
% angle, scaling and position of modes can be altered in defineGaussLLH.m.
% This example was written by B. Ballnus.
% 
% Single-chain and multi-chain Monte-Carlo sampling is performed by 
% getParameterSamples() and with different settings (commented code 
% version) and plotted in 1D and 2D.



%% Preliminary
clear all
close all
clc


%% Problem initialization

% Settings for this example
define_Gauss_LLH();
gaussDimension = 2 + dimi;


% Set required sampling options for Parallel Tempering
par.number = gaussDimension;
par.min    = [-100;-100;-100*ones(dimi,1)];
par.max    = [100;100;100*ones(dimi,1)];
par.name   = {};
for i = 1 : dimi + 2
   par.name{end+1} = ['\theta_' num2str(i)];
end

% Sampling Options
rng('shuffle')
options                     = PestoSamplingOptions();
options.objOutNumber        = 1;
options.nIterations         = 1e4;
options.mode                = 'text';
options.debug               = false;

% % Using PT
% options.samplingAlgorithm   = 'PT';
% options.PT.nTemps           = 40;
% options.PT.exponentT        = 1000;   
% options.PT.maxT             = 2000;
% options.PT.alpha            = 0.51;
% options.PT.temperatureNu    = 1e4;
% options.PT.memoryLength     = 1;
% options.PT.regFactor        = 1e-8;
% options.PT.temperatureEta   = 10;
% options.theta0              = repmat([mu(1,:),repmat(25,1,dimi)]',1,options.PT.nTemps); 
% options.theta0(:,1:2:end)   = repmat([mu(2,:),repmat(25,1,dimi)]',1,ceil(options.PT.nTemps/2));
% options.sigma0              = 1e6*diag(ones(1,dimi+2));

% Using RBPT
options.samplingAlgorithm     = 'RBPT';
options.RBPT.nTemps           = 40;
options.RBPT.exponentT        = 1000;   
options.RBPT.maxT             = 2000;
options.RBPT.alpha            = 0.51;
options.RBPT.temperatureNu    = 1e3;
options.RBPT.memoryLength     = 1;
options.RBPT.regFactor        = 1e-8;
options.RBPT.temperatureEta   = 10;

options.RBPT.trainPhaseFrac   = 0.1;

options.RBPT.RPOpt.rng                  = 7;
options.RBPT.RPOpt.nSample              = floor(options.nIterations*options.RBPT.trainPhaseFrac)-1;
options.RBPT.RPOpt.crossValFraction     = 0.2;
options.RBPT.RPOpt.modeNumberCandidates = 2;%[1,2,3,4,5,6,7,8];
options.RBPT.RPOpt.displayMode          = 'visual';
options.RBPT.RPOpt.maxEMiterations      = 100;
options.RBPT.RPOpt.nDim                 = par.number;
options.RBPT.RPOpt.nSubsetSize          = 1000;
options.RBPT.RPOpt.lowerBound           = par.min;
options.RBPT.RPOpt.upperBound           = par.max;
options.RBPT.RPOpt.tolMu                = 1e-4 * (par.max(1)-par.min(1));
options.RBPT.RPOpt.tolSigma             = 1e-2 * (par.max(1)-par.min(1));
options.RBPT.RPOpt.dimensionsToPlot     = [1,2];
options.RBPT.RPOpt.isInformative        = [1,1,zeros(1,options.RBPT.RPOpt.nDim-1)];

options.theta0              = repmat([mu(1,:),repmat(25,1,dimi)]',1,options.RBPT.nTemps); 
options.theta0(:,1:2:end)   = repmat([mu(2,:),repmat(25,1,dimi)]',1,ceil(options.RBPT.nTemps/2));
options.sigma0              = 1e6*diag(ones(1,dimi+2));

% Perform the parameter estimation via sampling
par = getParameterSamples(par, logP, options);

%%

% Additional visualization
figure('Name', 'Chain analysis and theoretical vs true sampling distribution');

% Visualize the mixing properties and the exploration of the chain
subplot(2,1,1);
plot(squeeze(par.S.par(:,:,1))');

% ...and their theoretical distribution
subplot(2,1,2); 
% plot_Gauss_LH();
hold on;
plot(squeeze(par.S.par(1,:,1))',squeeze(par.S.par(2,:,1))','.'); 
for k = unique(par.S.newLabel)'
   plot_gaussian_ellipsoid([par.S.par(1,end,1),par.S.par(2,end,1)], ...
      par.S.sigmaScale(end,1,k)*par.S.sigmaHist(1:2,1:2,1,k))
end
hold off;


% All tempered chains
figure
for j = 1:length(squeeze(par.S.par(1,1,:)))
   subplot(ceil(sqrt(length(squeeze(par.S.par(1,1,:))))),ceil(sqrt(length(squeeze(par.S.par(1,1,:))))),j)
   plot(par.S.par(1:2,:,j)');
   title(num2str(par.S.temperatures(end,j)))
end

% Swap Ratios
figure
title('Swapping Ratios')
bar(par.S.accSwap./par.S.propSwap)

% Temepratures
figure
title('Temperatures')
plot(log10(par.S.temperatures))

% Regions
figure
for j = 1:length(squeeze(par.S.par(1,1,:)))
   subplot(ceil(sqrt(length(squeeze(par.S.par(1,1,:))))),ceil(sqrt(length(squeeze(par.S.par(1,1,:))))),j)
   histogram(par.S.newLabel(1:end,j))
end

% modeSelection
figure;
plot(par.S.regions.lh);hold all; plot(max(par.S.regions.lh'),'linewidth',2,'color',[0,0,0]);xlabel('nModes');ylabel('LLH of randomly selected test set')



%% ACT
addpath('C:\Users\GEYAW\Home\Matlab_Home\2016_12_20_GIT_PESTO_Paper_Code\AnalysisPipelineTools')
acf = iact(squeeze(par.S.par(:,:,1))')
max(acf)










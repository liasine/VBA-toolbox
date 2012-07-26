function [posterior,options,dim,suffStat] = VBA_odeLim2NLSS(posterior,options,dim,suffStat,u,flag)
% recollect posterior structure from ODE limit
% function [posterior,options,dim,suffStat] =
% VBA_odeLim2NLSS(posterior,options,dim,suffStat,u,flag)
% This function checks the options structure, and returns the correct
% posterior structure if the state-space model was inverted in the 'ODE'
% (deterministic) mode.

% flag =1: function called by VBA_NLStateSpaceModel.m
% flag =0: function called by VBA_UpdateDisplay.m

% Check whether in ODE mode
if ~isequal(options.g_fname,@VBA_odeLim)
    return
end


% store current posterior and sufficient statistics
posterior0 = posterior;
suffStat0 = suffStat;
options0 = options;
suffStat.ODE_posterior = posterior;

% recover dimensions and options
dim = options.inG.old.dim;
options = options.inG.old.options;
try; options.init = options0.init; end

% Recover observation parameters posterior
if dim.n_phi > 0
    posterior.muPhi = posterior0.muPhi(1:dim.n_phi);
    posterior.SigmaPhi = posterior0.SigmaPhi(1:dim.n_phi,1:dim.n_phi);
    suffStat.dphi = suffStat0.dphi(1:dim.n_phi);
    indIn = options.params2update.phi;
    if ~isempty(indIn)
        suffStat.Sphi = 0.5*length(indIn)*log(2*pi*exp(1)) + 0.5*VBA_logDet(posterior.SigmaPhi,indIn);
    else
        suffStat.Sphi = 0;
    end
else
    posterior.muPhi = [];
    posterior.SigmaPhi = [];
    suffStat.dphi = [];
    suffStat.Sphi = [];
end

% Recover evolution parameters posterior
if dim.n_theta > 0
    posterior.muTheta = posterior0.muPhi(dim.n_phi+1:dim.n_phi+dim.n_theta);
    posterior.SigmaTheta = posterior0.SigmaPhi(dim.n_phi+1:dim.n_phi+dim.n_theta,dim.n_phi+1:dim.n_phi+dim.n_theta);
    suffStat.dtheta = suffStat0.dphi(dim.n_phi+1:dim.n_phi+dim.n_theta);
    indIn = options.params2update.theta;
    if ~isempty(indIn)
        suffStat.Stheta = 0.5*length(indIn)*log(2*pi*exp(1)) + 0.5*VBA_logDet(posterior.SigmaTheta,indIn);
    else
        suffStat.Stheta = 0;
    end
else
    posterior.muTheta = [];
    posterior.SigmaTheta = [];
    suffStat.dtheta = [];
    suffStat.Stheta = [];
end

% Recover initial conditions posterior
if options.updateX0
    posterior.muX0 = posterior0.muPhi(dim.n_phi+dim.n_theta+1:end);
    posterior.SigmaX0 = posterior0.SigmaPhi(dim.n_phi+dim.n_theta+1:end,dim.n_phi+dim.n_theta+1:end);
    suffStat.dx0 = suffStat0.dphi(dim.n_phi+dim.n_theta+1:end);
    indIn = options.params2update.x0;
    if ~isempty(indIn)
        suffStat.SX0 = 0.5*length(indIn)*log(2*pi*exp(1)) + 0.5*VBA_logDet(posterior.SigmaX0,indIn);
    else
        suffStat.SX0 = 0;
    end
else
    posterior.muX0 = options.priors.muX0;
    posterior.SigmaX0 = options.priors.SigmaX0;
    suffStat.dx0 = zeros(dim.n,1);
    indIn = options.params2update.x0;
    if ~isempty(indIn)
        suffStat.SX0 = 0.5*length(indIn)*log(2*pi*exp(1)) + 0.5*VBA_logDet(posterior.SigmaX0,indIn);
    else
        suffStat.SX0 = 0;
    end
end

% Recover hidden states posterior
posterior.muX = suffStat.muX;
posterior.SigmaX.current = suffStat.SigmaX;
if flag % if called by VBA_wrapup.m
    options.priors.muX = options.init.suffStat.muX;
    options.priors.SigmaX.current = options.init.suffStat.SigmaX;
    suffStat.SX = 0.5*dim.n*dim.n_t*log(2*pi*exp(1));
    for t=1:dim.n_t
        suffStat.SX = suffStat.SX + 0.5*VBA_logDet(posterior.SigmaX.current{t});
        posterior.SigmaX.inter{t} = zeros(dim.n,dim.n);
        options.priors.SigmaX.inter{t} = zeros(dim.n,dim.n);
    end
end



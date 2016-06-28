function test_dwjz(o)
% test_dwjz (distributed cross-identifiability gramian parameter reduction)
% by Christian Himpe, 2016 ( http://gramian.de )
% released under BSD 2-Clause License ( opensource.org/licenses/BSD-2-Clause )
%*
    if(exist('emgr')~=2)
        error('emgr not found! Get emgr at: http://gramian.de');
    else
        global ODE;
        fprintf('emgr (version: %1.1f)\n',emgr('version'));
    end

%% SETUP
    J = 4;
    N = 64;
    O = J;
    T = [0.01,1.0];
    L = floor(T(2)/T(1)) + 1;
    U = [ones(J,1),zeros(J,L-1)];
    X = zeros(N,1);
    P = 0.5+0.5*cos(1:N)';

    A = -gallery('lehmer',N);
    B = toeplitz(1:N,1:J)./N;
    C = B';

    LIN = @(x,u,p) A*x + B*u + p;
    OUT = @(x,u,p) C*x;

%% FULL ORDER
    Y = ODE(LIN,OUT,T,X,U,P); %figure; plot(0:T(1):T(2),Y); return;
    n1 = norm(Y(:),1);
    n2 = norm(Y(:),2);
    n8 = norm(Y(:),Inf);

%% OFFLINE
    global DWX;
    DWX = [];

    tic;
    WJ = emgr(LIN,OUT,[J,N,O],T,'j',[zeros(N,1),ones(N,1)],[0,0,0,0,0,0,1,0,0,0]);
    [UU,D,VV] = svd(WJ{2});
    OFFLINE = toc

    tic;

    w = 8;
    n = ceil(2*N/w);
    wj = [];
    for I=1:n
        DWX = [w,I];
        wj = [wj,emgr(LIN,OUT,[J,N,O],T,'j',[zeros(N,1),ones(N,1)],[0,0,0,0,0,0,1,0,0,0])];
    end;
    wx = wj(:,1:N);
    wi = -0.5*wj(:,N+1:end)'*ainv(wx+wx')*wj(:,N+1:end);

    OFFLINE = toc
    RESIDUAL1 = norm(WJ{1}-wx)
    RESIDUAL2 = norm(WJ{2}-wi)

%% EVALUATION
    for I=1:N-1
        uu = UU(:,1:I);
        y = ODE(LIN,OUT,T,X,U,uu*uu'*P);
        l1(I) = norm(Y(:)-y(:),1)/n1;
        l2(I) = norm(Y(:)-y(:),2)/n2;
        l8(I) = norm(Y(:)-y(:),Inf)/n8;
    end;

%% OUTPUT
    if(nargin>0 && o==0), return; end; 
    figure('Name',mfilename,'NumberTitle','off');
    semilogy(1:N-1,[l1;l2;l8],{'r','g','b'},'linewidth',2);
    xlim([1,N-1]);
    ylim([10^floor(log10(min([l1(:);l2(:);l8(:)]))),1]);
    pbaspect([2,1,1]);
    legend('L1 Error ','L2 Error ','L8 Error ','location','northeast');
    if(nargin>0 && o==1), print('-dsvg',[mfilename(),'.svg']); end;

%% CLEAN UP
    ODE = [];
    DWX = [];
end

function x = ainv(m)

    d = diag(m);
    d(d~=0) = 1.0./d(d~=0);
    n = numel(d);
    x = bsxfun(@times,m,-d);
    x = bsxfun(@times,x,d');
    x(1:n+1:end) = d;
end
function test_dwz(o)
% test_dwz (distributed non-symmetric cross gramian linear state reduction)
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

    A = -gallery('lehmer',N);
    B = toeplitz(1:N,1:J)./N;
    C = B';

    LIN = @(x,u,p) A*x + B*u;
    OUT = @(x,u,p) C*x;

%% FULL ORDER
    Y = ODE(LIN,OUT,T,X,U,0); %figure; plot(0:T(1):T(2),Y); return;
    n1 = norm(Y(:),1);
    n2 = norm(Y(:),2);
    n8 = norm(Y(:),Inf);

%% OFFLINE
    tic;
    WZ = emgr(LIN,OUT,[J,N,O],T,'x',[],[0,0,0,0,0,0,1,0,0,0]);
    [UU,D,VV] = svd(WZ);
    OFFLINE = toc

    tic;
    global DWX;
    w = 7;
    n = ceil(N/w);
    wz = [];
    for I=1:n
        DWX = [w,I];
        wz = [wz,emgr(LIN,OUT,[J,N,O],T,'x',[],[0,0,0,0,0,0,1,0,0,0])];
    end;
    OFFLINE = toc
    RESIDUAL = norm(WZ-wz)

%% EVALUATION
    for I=1:N-1
        uu = UU(:,1:I);
        lin = @(x,u,p) uu'*LIN(uu*x,u,p);
        out = @(x,u,p) OUT(uu*x,u,p);
        y = ODE(lin,out,T,uu'*X,U,0);
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

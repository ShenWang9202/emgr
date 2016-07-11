function test_cwi(o)
% test_cwi (identifiability gramian combined reduction)
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
    tic;
    WC = emgr(LIN,OUT,[J,N,O],T,'c');    
    WI = emgr(LIN,OUT,[J,N,O],T,'i',[zeros(N,1),ones(N,1)]);
    [L1,D1,R1] = svd(WC); LC = L1*diag(sqrt(diag(D1)));
    [L2,D2,R2] = svd(WI{1}); LO = L2*diag(sqrt(diag(D2)));
    [Lb,Db,Rb] = svd(LO'*LC);
    UU = ( LO*Lb*diag(1.0./sqrt(diag(Db))) )';
    VV =   LC*Rb*diag(1.0./sqrt(diag(Db)));
    [PP,D,QQ] = svd(WI{2});
    OFFLINE = toc

%% EVALUATION
    for I=1:N-1
        uu = VV(:,1:I);
        vv = UU(1:I,:);
        pp = PP(:,1:I);
        lin = @(x,u,p) vv*LIN(uu*x,u,p);
        out = @(x,u,p) OUT(uu*x,u,p);
        y = ODE(lin,out,T,vv*X,U,pp*pp'*P);
        l1(I) = norm(Y(:)-y(:),1)/n1;
        l2(I) = norm(Y(:)-y(:),2)/n2;
        l8(I) = norm(Y(:)-y(:),Inf)/n8;
    end;

%% OUTPUT
    if(nargin>0 && o==0), return; end; 
    figure('Name',mfilename,'NumberTitle','off');
    semilogy(1:N-1,l1,'r','linewidth',2); hold on;
    semilogy(1:N-1,l2,'g','linewidth',2);
    semilogy(1:N-1,l8,'b','linewidth',2); hold off;
    xlim([1,N-1]);
    ylim([10^floor(log10(min([l1(:);l2(:);l8(:)]))),1]);
    pbaspect([2,1,1]);
    legend('L1 Error ','L2 Error ','L8 Error ','location','northeast');
    if(nargin>0 && o==1), print('-dsvg',[mfilename(),'.svg']); end;

%% CLEAN UP
    ODE = [];
end

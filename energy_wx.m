function energy_wx(o)
% energy_wx (cross gramian experimental reduction)
% by Christian Himpe, 2015 ( http://gramian.de )
% released under BSD 2-Clause License ( opensource.org/licenses/BSD-2-Clause )
%*

if(exist('emgr')~=2)
    disp('emgr framework is required. Download at http://gramian.de/emgr.m');
    return;
end

%% Setup

J = 8;
N = 64;
O = 1;
T = [0.0,0.01,1.0];
L = (T(3)-T(1))/T(2);
U = [ones(J,1),zeros(J,L-1)];
X =  zeros(N,1);

rand('seed',1009);
A = rand(N,N); A(1:N+1:end) = -0.55*N;
B = rand(N,J);
C = rand(O,N);

LIN = @(x,u,p) A*x + B*u;
OUT = @(x,u,p) x'*x;

norm1 = @(y) T(2)*sum(abs(y(:)));
norm2 = @(y) sqrt(T(2)*dot(y(:),y(:)));
norm8 = @(y) max(y(:));

%% Main

Y = rk3(LIN,OUT,T,X,U,0); % Full Order

tic;
WX = emgr(LIN,OUT,[J,N,O],T,'x',0,[0,0,0,0,0,0,0,0,0,1,0,0],1,0,1);
[UU,D,VV] = svd(WX);
OFFLINE = toc

for I=1:N-1
    uu = UU(:,1:I);
    vv = uu';
    a = vv*A*uu;
    b = vv*B;
    x = vv*X;
    lin = @(x,u,p) a*x + b*u;
    out = @(x,u,p) OUT(uu*x,u,p);
    y = rk3(lin,out,T,x,U,0); % Reduced Order
    l1(I) = abs(norm1(Y-y)/norm1(Y));
    l2(I) = abs(norm2(Y-y)/norm2(Y));
    l8(I) = abs(norm8(Y-y)/norm8(Y));
end;

%% Output

if(nargin==0), return; end
figure();
semilogy(1:N-1,l1,'r','linewidth',2); hold on;
semilogy(1:N-1,l2,'g','linewidth',2);
semilogy(1:N-1,l8,'b','linewidth',2); hold off;
xlim([1,N-1]);
ylim([10^floor(log10(min([l1(:);l2(:);l8(:)]))-1),1]);
pbaspect([2,1,1]);
legend('L1 Error ','L2 Error ','L8 Error ','location','northeast');
if(o==1), print('-dsvg',[mfilename(),'.svg']); end;

%% ======== Integrator ========

function y = rk3(f,g,t,x,u,p)

    h = t(2);
    T = round(t(3)/h);

    y(:,1) = g(x,u(:,1),p);
    y(end,T) = 0;

    for t=1:T
        k1 = h*f(x,u(:,t),p);
        k2 = h*f(x + 0.5*k1,u(:,t),p);
        k3 = h*f(x + 0.75*k2,u(:,t),p);
        x = x + (2.0/9.0)*k1 + (1.0/3.0)*k2 + (4.0/9.0)*k3;
        y(:,t) = g(x,u(:,t),p);
    end;
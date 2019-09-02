% computes ka and kb from two-point measured thrust

% masses of UAV
mass = [
3.4;
4.3;
5.51;
];

% thrusts needed to hover
thrust = [
0.49;
0.56;
0.66;
];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fix kf constant at something
kf = 1;

% the gravitational acceleration
g = 9.81;

% create the main matrix
A = ones(length(mass), 2);

for i=1:length(mass)
  A(i, 1) = sqrt((mass(i)*g)/kf);
end

% print A
A

% compute the linear coeficients
X = A\thrust;

% plot the constants
kf
ka = X(1)
kb = X(2)
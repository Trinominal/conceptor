%%%% plain demo that when a RNN is driven by different signals, the induced
%%%% internal signals will inhabit different subspaces of the signal space.


% set figure window to 1 x 2 panels


set(0,'DefaultFigureWindowStyle','docked');

%%% Experiment control
randstate = 8; newNets = 1; newSystemScalings = 1;
linearMorphing = 0;

%%% Setting system params
Netsize = 100; % network size
NetSR = 1.5; % spectral radius
NetinpScaling = 1.5; % scaling of pattern feeding weights
BiasScaling = 0.2; % size of bias


%%% loading learning
TychonovAlpha = .0001; % regularizer for  W training
washoutLength = 500;
learnLength = 1000;
signalPlotLength = 20;

%%% pattern readout learning
TychonovAlphaReadout = 0.01;


%%% C learning and testing
alpha = 10;
CtestLength = 200;
SplotLength = 50;

% %%% Autoadapt testing
% cueLength = 50; postCueLength = 300;
% deviationPlotInterval = 100;
% TalphaAuto = 0.02;
% startAlpha = .02; % starting value for cueing phase
% TautoLR = 0.02;
% TcueLR = 0.02;
% SNR_cue = Inf; SNR_freeRun = Inf; % can be Inf for zero noise

%%% Setting patterns

patterns = [53 54 10 36];
%patterns = [23 6];
%patterns = [1 2 21 20 22 8 19 6  16 9 10 11 12];

% 1 = sine10  2 = sine15  3 = sine20  4 = spike20
% 5 = spike10 6 = spike7  7 = 0   8 = 1
% 9 = rand5; 10 = rand5  11 = rand6 12 = rand7
% 13 = rand8 14 = sine10range01 15 = sine10rangept5pt9
% 16 = rand3 17 = rand9 18 = rand10 19 = 0.8 20 = sineroot27
% 21 = sineroot19 22 = sineroot50 23 = sineroot75
% 24 = sineroot10 25 = sineroot110 26 = sineroot75tenth
% 27 = sineroots20plus40  28 = sineroot75third
% 29 = sineroot243  30 = sineroot150  31 = sineroot200
% 32 = sine10.587352723 33 = sine10.387352723
% 34 = rand7  35 = sine12  36 = 10+perturb  37 = sine11
% 38 = sine10.17352723  39 = sine5 40 = sine6
% 41 = sine7 42 = sine8  43 = sine9 44 = sine12
% 45 = sine13  46 = sine14  47 = sine10.8342522
% 48 = sine11.8342522  49 = sine12.8342522  50 = sine13.1900453
% 51 = sine7.1900453  52 = sine7.8342522  53 = sine8.8342522
% 54 = sine9.8342522 55 = sine5.19004  56 = sine5.8045
% 57 = sine6.49004 58 = sine6.9004 59 = sine13.9004
% 60 = 18+perturb

%%% Initializations

randn('state', randstate);
rand('twister', randstate);

% Create raw weights
if newNets
    if Netsize <= 20
        Netconnectivity = 1;
    else
        Netconnectivity = 10/Netsize;
    end
    WstarRaw = generate_internal_weights(Netsize, Netconnectivity);
    WinRaw = randn(Netsize, 1);
    WbiasRaw = randn(Netsize, 1);
end

% Scale raw weights and initialize weights
if newSystemScalings
    Wstar = NetSR * WstarRaw;
    Win = NetinpScaling * WinRaw;
    Wbias = BiasScaling * WbiasRaw;
end

% Set pattern handles
pattHandles; 
%%% in order to get same patterns as in the hierarchical
%architecture demo, run that demo first and do not call pattHandles here
%again. 

I = eye(Netsize);

% % learn equi weights

% harvest data from network externally driven by patterns
Np = length(patterns);
allTrainArgs = zeros(Netsize, Np * learnLength);
allTrainOldArgs = zeros(Netsize, Np * learnLength);
allTrainTargs = zeros(Netsize, Np * learnLength);
allTrainOuts = zeros(1, Np * learnLength);
readoutWeights = cell(1,Np);
patternCollectors = cell(1,Np);
xCollectorsCentered = cell(1,Np);
xCollectors = cell(1,Np);
SRCollectors = cell(1,Np);
URCollectors = cell(1,Np);
patternRs = cell(1,Np);
train_xPL = cell(1,Np);
train_pPL = cell(1,Np);
startXs = zeros(Netsize, Np);
% collect data from driving native reservoir with different drivers
for p = 1:Np
    patt = patts{patterns(p)}; % current pattern generator
    xCollector = zeros(Netsize, learnLength );
    xOldCollector = zeros(Netsize, learnLength );
    pCollector = zeros(1, learnLength );
    x = zeros(Netsize, 1);
    for n = 1:(washoutLength + learnLength)
        u = patt(n); % pattern input
        xOld = x;
        x = tanh(Wstar * x + Win * u + Wbias);
        if n > washoutLength
            xCollector(:, n - washoutLength ) = x;
            xOldCollector(:, n - washoutLength ) = xOld;
            pCollector(1, n - washoutLength) = u;
        end
    end
    
    xCollectorCentered = xCollector - ...
        repmat( mean(xCollector,2),1,learnLength);
    xCollectorsCentered{1,p} = xCollectorCentered;
    xCollectors{1,p} = xCollector;
    R = xCollector * xCollector' / learnLength;
    [Ux Sx Vx] = svd(R);
    SRCollectors{1,p} = Sx;
    URCollectors{1,p} = Ux;
    patternRs{p} = R;
    
    
    startXs(:,p) = x;
    train_xPL{1,p} = xCollector(:,1:signalPlotLength);
    train_pPL{1,p} = pCollector(1,1:signalPlotLength);
    
    patternCollectors{1,p} = pCollector;
    allTrainArgs(:, (p-1)*learnLength+1:p*learnLength) = ...
        xCollector;
    allTrainOldArgs(:, (p-1)*learnLength+1:p*learnLength) = ...
        xOldCollector;
    allTrainOuts(1, (p-1)*learnLength+1:p*learnLength) = ...
        pCollector;
    allTrainTargs(:, (p-1)*learnLength+1:p*learnLength) = ...
        Win * pCollector;
end

%%% compute readout

Wout = (inv(allTrainArgs * allTrainArgs' + ...
    TychonovAlphaReadout * eye(Netsize)) ...
    * allTrainArgs * allTrainOuts')';
% training error
NRMSE_readout = nrmse(Wout*allTrainArgs, allTrainOuts);
disp(sprintf('NRMSE readout: %g', NRMSE_readout));

%%% compute W
Wtargets = (atanh(allTrainArgs) - repmat(Wbias,1,Np*learnLength));
W = (inv(allTrainOldArgs * allTrainOldArgs' + ...
    TychonovAlpha * eye(Netsize)) * allTrainOldArgs * Wtargets')';
% training errors per neuron
NRMSE_W = nrmse(W*allTrainOldArgs, Wtargets);
disp(sprintf('mean NRMSE W: %g', mean(NRMSE_W)));

%%% run loaded reservoir to observe a messy output. Do this with starting
%%% from four states originally obtained in the four driving conditions
%%
figure(10); clf;
% initialize network state
for p = 1:4
    x = startXs(:,p);
    messyOutPL = zeros(1,CtestLength);
    % run
    for n = 1:CtestLength
        x = tanh(W*x + Wbias);
        y = Wout * x;
        messyOutPL(1,n) = y;
    end
    subplot(2,2,p);
    plot(messyOutPL(1,end-19:end));
end




% % compute projectors
Cs = cell(4, Np);
for p = 1:Np
    R = patternRs{p};
    [U S V] = svd(R);
    Snew = (S * inv(S + alpha^(-2) * eye(Netsize)));
    
    C = U * Snew * U';
    Cs{1, p} = C;
    Cs{2, p} = U;
    Cs{3, p} = diag(Snew);
    Cs{4, p} = diag(S);
end

% % test with C
x_CTestPL = zeros(5, CtestLength, Np);
p_CTestPL = zeros(1, CtestLength, Np);
for p = 1:Np
    C = Cs{1, p};
    x = startXs(:,p);
    x = 0.5*randn(Netsize,1);
    
    for n = 1:CtestLength
        x = tanh(W *  x + Wbias);
        x = C * x;
        x_CTestPL(:,n,p) = x(1:5,1);
        p_CTestPL(:,n,p) = Wout * x;
    end
end



%%% plotting



test_pAligned_PL = cell(1,Np);
test_xAligned_PL = cell(1,Np);
NRMSEsAligned = zeros(1,Np);
MSEsAligned = zeros(1,Np);

for p = 1:Np
    intRate = 20;
    thisDriver = train_pPL{1,p};
    thisOut = p_CTestPL(1,:,p);
    thisDriverInt = interp1((1:signalPlotLength)',thisDriver',...
        (1:(1/intRate):signalPlotLength)', 'spline')';
    thisOutInt = interp1((1:CtestLength)', thisOut',...
        (1:(1/intRate):CtestLength)', 'spline')';
    
    L = size(thisOutInt,2); M = size(thisDriverInt,2);
    phasematches = zeros(1,L - M);
    for phaseshift = 1:(L - M)
        phasematches(1,phaseshift) = ...
            norm(thisDriverInt - ...
            thisOutInt(1,phaseshift:phaseshift+M-1));
    end
    [maxVal maxInd] = max(-phasematches);
    test_pAligned_PL{1,p} = ...
        thisOutInt(1,maxInd:intRate:...
        (maxInd+intRate*signalPlotLength-1));
    coarseMaxInd = ceil(maxInd / intRate);
    test_xAligned_PL{1,p} = ...
        x_CTestPL(:,coarseMaxInd:coarseMaxInd+signalPlotLength-1,p);
    NRMSEsAligned(1,p) = ...
        nrmse(test_pAligned_PL{1,p},train_pPL{1,p});
    MSEsAligned(1,p) = ...
        mean((test_pAligned_PL{1,p} - train_pPL{1,p}).^2 );
end

meanNRMSE = mean(NRMSEsAligned)
%%
figure(2); clf;
fs = 24; fsNRMSE = 18;
%set(gcf,'DefaultAxesColorOrder',[0  0.4 0.65 0.8]'*[1 1 1]);
set(gcf, 'WindowStyle','normal');

set(gcf,'Position', [600 400 1000 500]);

pick1 = 71; pick2 = 80;
col1 = 0.6*[1 1 1]; col2 = 0.3*[1 1 1];
for p = 1:Np
    subplot(Np,4,(p-1)*4+1);
    plot(test_pAligned_PL{1,p}, 'LineWidth',10,...
        'Color',0.75*[1 1 1]); hold on;
    plot(train_pPL{1,p},'k','LineWidth',1.5); hold off;
    if p == 1
        title('p and y','FontSize',fs);
    end
    if p ~= Np
        set(gca, 'XTickLabel',[]);
    end
    set(gca, 'YLim',[-1,1], 'FontSize',fs);
%     rectangle('Position', [0.5,-0.95,8,0.5],'FaceColor','w',...
%         'LineWidth',1);
%      text(1,-0.7,num2str(NRMSEsAligned(1,p),2),...
%         'Color','k','FontSize',fsNRMSE, 'FontWeight', 'bold');
    
    subplot(Np,4,(p-1)*4+2); hold on;
    plot(train_xPL{1,p}(pick1,:)','Color',col1,'LineWidth',3);
    plot(train_xPL{1,p}(pick2,:)','Color',col2,'LineWidth',3);
    hold off;
    if p == 1
        title('two neurons','FontSize',fs);
    end
    if p ~= Np
        set(gca, 'XTickLabel',[]);
    end
    set(gca,'YLim',[-1,1], 'FontSize',fs, 'Box', 'on');
    
    subplot(Np,4,(p-1)*4+3);
    %diagNormalized = sDiagCollectors{1,p} / sum(sDiagCollectors{1,p});
    hold on;
    plot(log10(diag(SRCollectors{1,p})),'k','LineWidth',3);
    plot(zeros(1,100),'k--');
    hold off;
    
    set(gca,'YLim',[-17,5], 'YTick',[-10, 0], 'FontSize',fs, 'Box','on');
    if p == 1
        title('log10 \sigma','FontSize',fs);
    end
    if p < 4
        set(gca,'XTick',[]);
    end
    
    subplot(Np,4,(p-1)*4+4);
    hold on;
    plot(zeros(1,100),'k--');
    plot(ones(1,100),'k--');
    plot(Cs{3, p},'k','LineWidth',3);
    hold off;
    if p == 1
        title('s','FontSize',fs);
    end
    set(gca,'YLim',[-0.1,1.1], 'YTick',[0 1], 'FontSize',fs, 'Box','on');
    if p < 4
        set(gca,'XTick',[]);
    end
end

%%
% pick1 = 11; pick2 = 16;
% pick1 = 12; pick2 = 14;
% pick1 = 16; pick2 = 32;
% pick1 = 16; pick2 = 51; 71 80
%pick1 = randi([1 100]); 
%pick2 = 18;
%pick2 = randi([1 100]); 
col1 = 0.5*[1 1 1]; col2 = 0.7*[1 1 1]; 
col3 = 0.3*[1 1 1]; col4 = [0.6 0. 0.4];
L = 100;
fs = 16;
trace1 = allTrainArgs([pick1 pick2],1:L);
trace2 = allTrainArgs([pick1 pick2],1001:1000+L);
trace3 = allTrainArgs([pick1 pick2],2001:2000+L);
trace4 = allTrainArgs([pick1 pick2],3001:3000+L);
R1 = trace1 * trace1' / L; [U1 S1 V1] = svd(R1);
R2 = trace2 * trace2' / L; [U2 S2 V2] = svd(R2);
R3 = trace3 * trace3' / L; [U3 S3 V3] = svd(R3);
R4 = trace4 * trace4' / L; [U4 S4 V4] = svd(R4);
cycleData = [cos(2 * pi * (0:200) / 200 ); sin(2 * pi * (0:200) / 200) ];
E1 = R1 * cycleData; E2 = R2 * cycleData;
figure(3); clf;
set(gcf, 'WindowStyle','normal');
set(gcf,'Position', [800 200 600 200]);
rg = 1.2;
subplot(1,3,1);
hold on;
plot([-rg rg], [0 0], 'k--');
plot([0 0], [-rg rg], 'k--');
plot(cycleData(1,:), cycleData(2,:), 'k','LineWidth',1.5);
plot(trace1(1,:), trace1(2,:), '.','Color',col1, 'MarkerSize', 20);
% plot(trace2(1,:), trace2(2,:), 'r.',...
%     'MarkerSize', 20);
plot(E1(1,:), E1(2,:), 'Color',col1, 'LineWidth',2);
plot(S1(1,1) * [0,U1(1,1)], S1(1,1) * [0,U1(2,1)],'Color',col1, 'LineWidth',2);
plot(S1(2,2) * [0,U1(1,2)], S1(2,2) * [0,U1(2,2)],'Color',col1, 'LineWidth',2);
% plot(E2(1,:), E2(2,:), 'r', 'LineWidth',4);
% plot(S2(1,1) * [0,U2(1,1)], S2(1,1) * [0,U2(2,1)],'r', 'LineWidth',2);
% plot(S2(2,2) * [0,U2(1,2)], S2(2,2) * [0,U2(2,2)],'r', 'LineWidth',2);
hold off;
set(gca, 'XLim', [-rg rg], 'YLim', [-rg rg], 'XTick',[-1 0 1],...
   'YTick',[-1 0 1], 'FontSize', fs, 'Box', 'on' );
axis square;

a = 1.6;
C1 = R1 * inv(R1 + a^(-2)*eye(2));
[U1c S1c V1c] = svd(C1);
C2 = R2 * inv(R2 + a^(-2)*eye(2));
[U2c S2c V2c] = svd(C2);
C3 = R3 * inv(R3 + a^(-2)*eye(2));
[U3c S3c V3c] = svd(C3);
C4 = R4 * inv(R4 + a^(-2)*eye(2));
[U4c S4c V4c] = svd(C4);
E1c = C1 * cycleData; E2c = C2 * cycleData;
E3c = C3 * cycleData; E4c = C4 * cycleData;

subplot(1,3,2);
hold on;
plot([-rg rg], [0 0], 'k--');
plot([0 0], [-rg rg], 'k--');
plot(cycleData(1,:), cycleData(2,:), 'k','LineWidth',1.5);
plot(E1(1,:), E1(2,:), 'Color',col1, 'LineWidth',1.5);
plot(E1c(1,:), E1c(2,:), 'Color',col3, 'LineWidth',4);
plot(S1(1,1) * [0,U1(1,1)], S1(1,1) * [0,U1(2,1)],'Color',col1, ...
    'LineWidth',1.5);
plot(S1(2,2) * [0,U1(1,2)], S1(2,2) * [0,U1(2,2)],'Color',col1, ...
    'LineWidth',1.5);
plot(S1c(1,1) * [0,U1c(1,1)], S1c(1,1) * [0,U1c(2,1)],'Color',col3, ...
    'LineWidth',4);
plot(S1c(2,2) * [0,U1c(1,2)], S1c(2,2) * [0,U1c(2,2)],'Color',col3,...
    'LineWidth',4);
% plot(E2(1,:), E2(2,:), 'r', 'LineWidth',2);
% plot(E2c(1,:), E2c(2,:), 'r', 'LineWidth',4);
% plot(S2(1,1) * [0,U2(1,1)], S2(1,1) * [0,U2(2,1)],'r', 'LineWidth',1);
% plot(S2(2,2) * [0,U2(1,2)], S2(2,2) * [0,U2(2,2)],'r', 'LineWidth',1);
hold off;
set(gca, 'XLim', [-rg rg], 'YLim', [-rg rg], 'XTick',[-1 0 1],...
   'YTick',[-1 0 1], 'FontSize', fs, 'Box', 'on' );
axis square;

subplot(1,3,3);
ms = 20; lw = 1.5;
hold on;
plot([-rg rg], [0 0], 'k--');
plot([0 0], [-rg rg], 'k--');
plot(cycleData(1,:), cycleData(2,:), 'k','LineWidth',1.5);
plot(E1c(1,:), E1c(2,:), 'Color',col1, 'LineWidth',lw);
plot(E2c(1,:), E2c(2,:), 'Color',col3, 'LineWidth',lw);
plot(S1c(1,1) * [0,U1c(1,1)], S1c(1,1) * [0,U1c(2,1)],'Color',col1, ...
    'LineWidth',lw);
plot(S1c(2,2) * [0,U1c(1,2)], S1c(2,2) * [0,U1c(2,2)],'Color',col1, ...
    'LineWidth',lw);
plot(S2c(1,1) * [0,U2c(1,1)], S2c(1,1) * [0,U2c(2,1)],'Color',col3, ...
    'LineWidth',lw);
plot(S2c(2,2) * [0,U2c(1,2)], S2c(2,2) * [0,U2c(2,2)],'Color',col3, ...
    'LineWidth',lw);
% plot(E3c(1,:), E3c(2,:), '.', 'Color',col3,'LineWidth',2);
% plot(E4c(1,:), E4c(2,:), '.', 'Color',col4,'LineWidth',2);
% plot(S3c(1,1) * [0,U3c(1,1)], S3c(1,1) * [0,U3c(2,1)],'Color',col3, ...
%     'LineWidth',2);
% plot(S3c(2,2) * [0,U3c(1,2)], S3c(2,2) * [0,U3c(2,2)],'Color',col3, ...
%     'LineWidth',2);
% plot(S4c(1,1) * [0,U4c(1,1)], S4c(1,1) * [0,U4c(2,1)],'Color',col4, ...
%     'LineWidth',2);
% plot(S4c(2,2) * [0,U4c(1,2)], S4c(2,2) * [0,U4c(2,2)],'Color',col4,...
%     'LineWidth',2);
hold off;
set(gca, 'XLim', [-rg rg], 'YLim', [-rg rg], 'XTick',[-1 0 1],...
   'YTick',[-1 0 1], 'FontSize', fs, 'Box', 'on' );
axis square;
%%
% %%
% figure(10); clf;
% fs = 24;
% set(gcf,'DefaultAxesColorOrder',[0  ]'*[1 1 1]);
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [1000 400 120 80]);
% plot(train_pPL{1,3}','LineWidth',2);
% set(gca,'YLim',[-1,1],'YTickLabel',[],'XTickLabel',[]);

% figure(11); clf;
% fs = 24;
% set(gcf,'DefaultAxesColorOrder',[0  ]'*[1 1 1]);
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [1000 500 200 80]);
% plot(train_xPL{1,1}(1,:),'LineWidth',2);
% set(gca,'YLim',[-1,1],'YTickLabel',[],'XTickLabel',[]);
%
% figure(12); clf;
% fs = 24;
% set(gcf,'DefaultAxesColorOrder',[0.5  ]'*[1 1 1]);
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [1000 600 200 80]);
% plot(train_xPL{1,1}(2,:),'LineWidth',8);
% set(gca,'YLim',[-1,1],'YTickLabel',[],'XTickLabel',[]);
%
% figure(13); clf;
% fs = 24;
% set(gcf,'DefaultAxesColorOrder',[0  ]'*[1 1 1]);
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [1000 700 200 80]);
% plot(train_xPL{1,1}(3,:),'LineWidth',2);
% set(gca,'YLim',[-1,1],'YTickLabel',[],'XTickLabel',[]);
%
% figure(14); clf;
% fs = 24;
% set(gcf,'DefaultAxesColorOrder',[0  ]'*[1 1 1]);
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [1000 800 200 80]);
% plot(train_xPL{1,1}(4,:),'LineWidth',2);
% set(gca,'YLim',[-1,1],'YTickLabel',[],'XTickLabel',[]);


%%  energy similarities between driven response spaces

% 
% similarityMatrixC = zeros(Np, Np);
% for i = 1:Np
%     for j = i:Np
%         similarity = ...
%             norm((diag(sqrt(Cs{3, i})) * Cs{2,i}' * ...
%             Cs{2,j}*diag(sqrt(Cs{3, j}))),'fro')^2 / ...
%             (norm(Cs{1,i},'fro') * norm(Cs{1,j},'fro'));
%         
%         similarityMatrixC(i,j) = similarity;
%         similarityMatrixC(j,i) = similarity;
%     end
% end
% 
% similarityMatrixR = zeros(Np, Np);
% 
% for i = 1:Np
%     for j = i:Np
%         similarity = ...
%             norm((sqrt(SRCollectors{1, i}) * URCollectors{1,i}' * ...
%             URCollectors{1,j}* sqrt(SRCollectors{1, j})),'fro')^2 / ...
%             (norm(patternRs{i},'fro') * norm(patternRs{j},'fro'));
%         
%         similarityMatrixR(i,j) = similarity;
%         similarityMatrixR(j,i) = similarity;
%     end
% end
% %%
% figure(22); clf;
% fs = 24; fs1 = 24;
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [900 400 500 500]);
% plotmat(similarityMatrixC, 0, 1, 'g');
% for i = 1:Np
%     for j = i:Np
%         if similarityMatrixC(i,j) > 0.995
%             text(i-0.1,j,num2str(similarityMatrixC(i,j),2),...
%                 'FontSize',fs1);
%         elseif similarityMatrixC(i,j) < 0.5
%             text(i-0.3,j,num2str(similarityMatrixC(i,j),2),...
%                 'Color','w','FontSize',fs1);
%         else
%             text(i-0.3,j,num2str(similarityMatrixC(i,j),2),...
%                 'FontSize',fs1);
%             
%         end
%     end
% end
% set(gca,'YTick',[1 2 3 4], 'XTick',[1 2 3 4],'FontSize',fs);
% title(['C based similarities, \alpha = ', num2str(alpha)],...
%     'FontSize', fs);
% 
% 
% %%
% figure(3); clf;
% fs = 24; fs1 = 24;
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [1100 300 500 500]);
% plotmat(similarityMatrixR, 0, 1, 'g');
% for i = 1:Np
%     for j = i:Np
%         if similarityMatrixR(i,j) > 0.995
%             text(i-0.1,j,num2str(similarityMatrixR(i,j),2),...
%                 'FontSize',fs1);
%         elseif similarityMatrixR(i,j) < 0.5
%             text(i-0.3,j,num2str(similarityMatrixR(i,j),2),...
%                 'Color','w','FontSize',fs1);
%         else
%             text(i-0.3,j,num2str(similarityMatrixR(i,j),2),...
%                 'FontSize',fs1);
%             
%         end
%     end
% end
% set(gca,'YTick',[1 2 3 4], 'XTick',[1 2 3 4],'FontSize',fs);
% title('R based similarities', 'FontSize', fs);
% 
% 
% 
% figure(4); clf;
% for p = 1:Np
%     subplot(Np,2,(p-1)*2+1);
%     plot(x_CTestPL(:,end - signalPlotLength+1:end,p)');
%     if p == 1
%         title('C controlled x');
%     end
%     subplot(Np,2,p*2);
%     plot(patternCollectors{1,p}(:,end - signalPlotLength+1:end)', 'g'); hold on;
%     plot(p_CTestPL(:,end - signalPlotLength+1:end,p)');
%     hold off;
%     if p == 1
%         title('C controlled p');
%     end
%     
% end
% 
% %%
% % plotting comparisons for different alpha
% sPL1 = zeros(5,Netsize);
% sPL2 = zeros(5,Netsize);
% alphas = [1 10 100 1000 10000];
% for i = 1:5
%     R1 =  patternRs{1};
%     C1 =  R1 * inv(R1 + alphas(i)^(-2) * I);
%     [U1 S1 V1] = svd(C1);
%     sPL1(i,:) = diag(S1)';
%     R2 =  patternRs{3};
%     C2 =  R2 * inv(R2 + alphas(i)^(-2) * I);
%     [U2 S2 V2] = svd(C2);
%     sPL2(i,:) = diag(S2)';    
% end
% %%
% figure(5); clf;
% set(gcf, 'WindowStyle','normal');
% set(gcf,'Position', [800 300 800 200]);
% set(gcf,'DefaultAxesColorOrder',[0 0.2 0.4 0.6 0.7]'*[1 1 1]);
% fs = 18;
% subplot(1,2,1);
% plot(sPL1', 'LineWidth',2);
% title('sine (pattern 1)', 'FontSize',fs);
% set(gca,'YTick',[0 1], 'YLim', [0 1.1], 'FontSize',fs);
% subplot(1,2,2);
% plot(sPL2', 'LineWidth',2);
% title('10-periodic random (pattern 3)', 'FontSize',fs);
% set(gca,'YTick',[0 1], 'YLim', [0 1.1], 'FontSize',fs);
% legend('\alpha = 1', '\alpha = 10', ...
%     '\alpha = 100', '\alpha = 1000', '\alpha = 10000' );


